require 'helper'
require 'fluent/test/driver/filter'
require 'fluent/plugin/filter_rename_key'

class RenameKeyFilterTest < Test::Unit::TestCase
  MATCH_TAG = 'incoming_tag'
  RENAME_RULE_CONFIG = 'rename_rule1 ^\$(.+) x$${md[1]}'
  REPLACE_RULE_CONFIG = 'replace_rule1 ^\$ x'

  def setup
    Fluent::Test.setup
  end

  def create_driver(conf)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::RenameKeyFilter).configure(conf)
  end

  def test_config_error
    assert_raise(Fluent::ConfigError) { create_driver('') }

    assert_raise(Fluent::ConfigError) { create_driver('rename_rule1 ^$(.+?) ') }

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
      rename_rule1 ^\$(.+)1 x$${md[1]}
      rename_rule2 ^\$(.+)2(\d+) ${md[1]}_${md[2]}
    ]

    d = create_driver config_multiple_rules
    assert_equal '^\$(.+)1 x$${md[1]}', d.instance.config['rename_rule1']
    assert_equal '^\$(.+)2(\d+) ${md[1]}_${md[2]}', d.instance.config['rename_rule2']
  end


  def test_rename_rule_emit_deep_rename_hash
    d = create_driver RENAME_RULE_CONFIG
    d.run default_tag: MATCH_TAG do
      d.feed '$key1' => 'value1', 'key2' => {'$key3' => 'value3', '$key4'=> {'$key5' => 'value5'} }
    end

    records = d.filtered_records
    assert_equal %w[x$key1 key2], records[0].keys
    assert_equal %w[x$key3 x$key4], records[0]['key2'].keys
    assert_equal ['x$key5'], records[0]['key2']['x$key4'].keys
  end

  def test_rename_rule_emit_deep_rename_array
    d = create_driver RENAME_RULE_CONFIG
    d.run default_tag: MATCH_TAG do
      d.feed '$key1' => 'value1', 'key2' => [{'$key3' => 'value3'}, {'$key4'=> {'$key5' => 'value5'}}]
    end

    records = d.filtered_records
    assert_equal %w[x$key3 x$key4], records[0]['key2'].flat_map(&:keys)
    assert_equal ['x$key5'], records[0]['key2'][1]['x$key4'].keys
  end

  def test_rename_rule_emit_deep_rename_off
    config = %Q[
      #{RENAME_RULE_CONFIG}
      deep_rename false
    ]

    d = create_driver config
    d.run default_tag: MATCH_TAG do
      d.feed '$key1' => 'value1', 'key2' => {'$key3'=>'value3', '$key4'=> 'value4'}
    end

    records = d.filtered_records
    assert_equal %w[$key3 $key4], records[0]['key2'].keys
  end

  def test_rename_rule_emit_with_match_data
    d = create_driver 'rename_rule1 (\w+)\s(\w+)\s(\w+) ${md[3]} ${md[2]} ${md[1]}'
    d.run default_tag: MATCH_TAG do
      d.feed 'key1 key2 key3' => 'value'
    end
    records = d.filtered_records
    assert_equal 1, records.length
    assert_equal ['key3 key2 key1'], records[0].keys
  end

  def test_multiple_rename_rules_emit
    config_multiple_rules = %q[
      rename_rule1 ^(\w+)\s1 ${md[1]}_1
      rename_rule2 ^(\w+)\s2 ${md[1]}_2
    ]

    d = create_driver config_multiple_rules
    d.run default_tag: MATCH_TAG do
      d.feed 'key 1' => 'value1', 'key 2' => 'value2'
    end

    records = d.filtered_records
    assert_equal %w[key_1 key_2], records[0].keys
  end

  def test_replace_rule_emit_deep_rename_hash
    d = create_driver 'replace_rule1 ^(\$) x'

    d.run default_tag: MATCH_TAG do
      d.feed '$key1' => 'value1', 'key2' => { 'key3' => 'value3', '$key4' => 'value4' }
    end
    records = d.filtered_records
    assert_equal %w[xkey1 key2], records[0].keys
    assert_equal %w[key3 xkey4], records[0]['key2'].keys
  end

  def test_replace_rule_emit_with_match_data
    d = create_driver 'rename_rule1 (\w+)\s(\w+)\s(\w+) ${md[3]} ${md[2]} ${md[1]}'
    d.run default_tag: MATCH_TAG do
      d.feed 'key1 key2 key3' => 'value'
    end
    records = d.filtered_records
    assert_equal 1, records.length
    assert_equal ['key3 key2 key1'], records[0].keys
  end

  def test_replace_rule_emit_deep_rename_array
    d = create_driver 'replace_rule1 ^(\$) x${md[1]}'

    d.run default_tag: MATCH_TAG do
      d.feed '$key1' => 'value1', 'key2' => [{'$key3' => 'value3'}, {'$key4' => {'$key5' => 'value5'}}]
    end

    records = d.filtered_records
    assert_equal %w[x$key3 x$key4], records[0]['key2'].flat_map(&:keys)
    assert_equal %w[x$key5], records[0]['key2'][1]['x$key4'].keys
  end

  def test_replace_rule_emit_deep_rename_off
    config = %Q[
      #{REPLACE_RULE_CONFIG}
      deep_rename false
    ]

    d = create_driver config
    d.run default_tag: MATCH_TAG do
      d.feed '$key1' => 'value1', 'key2' => {'$key3'=>'value3', '$key4'=> 'value4'}
    end

    records = d.filtered_records
    assert_equal %w[$key3 $key4], records[0]['key2'].keys
  end

  def test_replace_rule_emit_remove_matched_when_no_replacement
    d = create_driver 'replace_rule1 "[\\\\s/()]"'
    d.run default_tag: MATCH_TAG do
      d.feed 'key (/1 )' => 'value1'
    end

    records = d.filtered_records
    assert_equal %w[key1], records[0].keys
  end

  def test_multiple_replace_rules_emit
    config_multiple_rules = %q[
      replace_rule1 ^(\w+)\s(\d) ${md[1]}${md[2]}
      replace_rule2 "[\\\\s()]"
    ]

    d = create_driver config_multiple_rules
    d.run default_tag: MATCH_TAG do
      d.feed 'key 1' => 'value1', 'key (2)' => 'value2'
    end

    records = d.filtered_records
    assert_equal %w[key1 key2], records[0].keys
  end

  def test_combined_rename_rule_and_replace_rule
    config_combined_rules = %q[
      rename_rule1 ^(.+)\s(one) ${md[1]}1
      replace_rule2 "[\\\\s()]"
    ]

    d = create_driver config_combined_rules
    d.run default_tag: MATCH_TAG do
      d.feed '(key) one (x)' => 'value1', 'key (2)' => 'value2'
    end

    records = d.filtered_records
    assert_equal %w[key1 key2], records[0].keys
  end
end
