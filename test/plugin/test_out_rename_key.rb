require 'helper'

class RenameKeyOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %q[
    rename_rule1 ^\$(.+) x$${md[1]}
    rename_rule2 ^l(eve)l(\d+) ${md[1]}_${md[2]}
  ]

  def create_driver(conf=CONFIG,tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::RenameKeyOutput, tag).configure(conf)
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }

    assert_raise(Fluent::ConfigError) {
      d = create_driver('rename_rule1 ^$(.+?) ')
    }

    assert_raise(Fluent::ConfigError) {
      config_dup_rules_for_a_key = %q[
        rename_rule1 ^\$(.+) ${md[1]}
        rename_rule2 ^\$(.+) ${md[1]} something
      ]
      d = create_driver(config_dup_rules_for_a_key)
    }

    config_multiple_rules = %q[
      rename_rule1 ^\$(.+) x$${md[1]}
      rename_rule2 ^(level)(\d+) ${md[1]}_${md[2]}
    ]

    d = create_driver config_multiple_rules
    assert_equal '^\$(.+) x$${md[1]}', d.instance.config['rename_rule1']
    assert_equal '^(level)(\d+) ${md[1]}_${md[2]}', d.instance.config['rename_rule2']
  end

end
