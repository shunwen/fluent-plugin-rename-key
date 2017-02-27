require 'test/unit'
require 'fluent/plugin/filter_rename_key'

class TestClass
  include Fluent::Plugin::RenameKeyUtil
end

class RenameKeyUtilTest < Test::Unit::TestCase

  def test_parse_rename_rule
    parsed = TestClass.new.send :parse_rename_rule, '(reg)(exp) ${md[1]} ${md[2]}'
    assert_equal 2, parsed.length
    assert_equal /(reg)(exp)/, parsed[:key_regexp]
    assert_equal '${md[1]} ${md[2]}', parsed[:new_key]
  end

  def test_parse_replace_rule_with_replacement
    # Replace hyphens with underscores
    parsed = TestClass.new.send :parse_replace_rule, '- _'
    assert_equal 2, parsed.length
    assert_equal /-/, parsed[:key_regexp]
    assert_equal '_', parsed[:replacement]
  end

  def test_parse_replace_rule_without_replacement
    # Remove all parentheses, hyphens, and spaces
    parsed = TestClass.new.send :parse_replace_rule, '[-\s()]'
    assert_equal 2, parsed.length
    assert_equal /[-\s()]/, parsed[:key_regexp]
    assert_equal '', parsed[:replacement]
  end
end
