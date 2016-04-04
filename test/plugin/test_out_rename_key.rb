require 'helper'

class RenameKeyOutputTest < Test::Unit::TestCase
  MATCH_TAG = 'incoming_tag'
  CONFIG = 'rename_rule1 ^\$(.+) x$${md[1]}'

  def setup
    Fluent::Test.setup
  end

  def create_driver(conf = CONFIG, tag = MATCH_TAG)
    Fluent::Test::OutputTestDriver.new(Fluent::RenameKeyOutput, tag).configure(conf)
  end

  def test_config_error
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }

    assert_raise(Fluent::ConfigError) {
      create_driver('rename_rule1 ^$(.+?) ')
    }

    assert_raise(Fluent::ConfigError) {
      config_dup_rules_for_a_key = %q[
        rename_rule1 ^\$(.+) ${md[1]}
        rename_rule2 ^\$(.+) ${md[1]} something
      ]
      create_driver(config_dup_rules_for_a_key)
    }
  end

  def test_config_success
    config_multiple_rules = %q[
      rename_rule1 ^\$(.+) x$${md[1]}
      rename_rule2 ^(level)(\d+) ${md[1]}_${md[2]}
    ]

    d = create_driver config_multiple_rules
    assert_equal '^\$(.+) x$${md[1]}', d.instance.config['rename_rule1']
    assert_equal '^(level)(\d+) ${md[1]}_${md[2]}', d.instance.config['rename_rule2']
  end

  def test_emit_default_append_tag
    append_tag = Fluent::RenameKeyOutput::DEFAULT_APPEND_TAG
    d = create_driver
    d.run do
      d.emit '$key1' => 'value1', '%key2' => {'$key3'=>'123', '$key4'=> {'$key5' => 'value2'} }
    end

    emits = d.emits
    assert_equal 1, emits.length
    assert_equal "#{MATCH_TAG}.#{append_tag}", emits[0][0]
    assert_equal ['x$key1', '%key2'], emits[0][2].keys
  end

  def test_emit_append_custom_tag
    custom_tag = 'custom_tag'
    config = %Q[
      #{CONFIG}
      append_tag #{custom_tag}
    ]
    d = create_driver config

    d.run do
      d.emit '$key1' => 'value1', '%key2' => {'$key3'=>'123', '$key4'=> {'$key5' => 'value2'} }
    end

    emits = d.emits
    assert_equal 1, emits.length
    assert_equal "#{MATCH_TAG}.#{custom_tag}", emits[0][0]
    assert_equal ['x$key1', '%key2'], emits[0][2].keys
  end

  def test_emit_deep_rename_hash
    d = create_driver
    d.run do
      d.emit '$key1' => 'value1', '%key2' => {'$key3'=>'123', '$key4'=> {'$key5' => 'value2'} }
    end

    emits = d.emits
    assert_equal ['x$key3', 'x$key4'], emits[0][2]['%key2'].keys
    assert_equal ['x$key5'], emits[0][2]['%key2']['x$key4'].keys
  end

  def test_emit_deep_rename_array
    d = create_driver
    d.run do
      d.emit '$key1' => 'value1', '%key2' => [{'$key3'=>'123'}, {'$key4'=> {'$key5' => 'value2'}}]
    end

    emits = d.emits
    assert_equal ['x$key3', 'x$key4'], emits[0][2]['%key2'].flat_map(&:keys)
    assert_equal ['x$key5'], emits[0][2]['%key2'][1]['x$key4'].keys
  end

  def test_emit_deep_rename_off
    config = %Q[
      #{CONFIG}
      deep_rename false
    ]

    d = create_driver config
    d.run do
      d.emit '$key1' => 'value1', '%key2' => {'$key3'=>'123', '$key4'=> {'$key5' => 'value2'} }
    end

    emits = d.emits
    assert_equal ['$key3', '$key4'], emits[0][2]['%key2'].keys
  end

  def test_remove_tag_prefix
    append_tag = Fluent::RenameKeyOutput::DEFAULT_APPEND_TAG

    config = %Q[
      #{CONFIG}
      remove_tag_prefix #{MATCH_TAG}
    ]

    d = create_driver config
    d.run do
      d.emit 'key1' => 'value1'
      d.emit '$key2' => 'value2'
    end

    emits = d.emits
    assert_equal 2, emits.length
    assert_equal append_tag, emits[0][0]
    assert_equal append_tag, emits[1][0]
  end
end
