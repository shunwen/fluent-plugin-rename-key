require 'helper'

class RenameKeyOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %q[
    rename_rule1 ^\$(.+) x$${md[1]}
    rename_rule2 ^l(eve)l(\d+) ${md[1]}_${md[2]}
  ]

  CONFIG_MULTI_RULES_FOR_A_KEY = %q[
    rename_rule1 ^\$(.+) ${md[1]}
    rename_rule2 ^\$(.+) ${md[1]} somthing
  ]

  CONFIG_REMOVE_TAG_PREFIX = %q[
    rename_rule1 ^\$(.+) ${md[1]} somthing
    remove_tag_prefix input
  ]

  CONFIG_APPEND_TAG = %q[
    rename_rule1 ^\$(.+) ${md[1]} somthing
    append_tag postfix
  ]

  def create_driver(conf=CONFIG,tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::RenameKeyOutput, tag).configure(conf)
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }
    # assert_raise(Fluent::ConfigError) {
    #   d = create_driver('rewriterule1 foo')
    # }
    # assert_raise(Fluent::ConfigError) {
    #   d = create_driver('rewriterule1 foo foo')
    # }
    # assert_raise(Fluent::ConfigError) {
    #   d = create_driver('rewriterule1 hoge hoge.${tag_parts[0..2]}.__TAG_PARTS[0..2]__')
    # }
    # assert_raise(Fluent::ConfigError) {
    #   d = create_driver('rewriterule1 fuga fuga.${tag_parts[1...2]}.__TAG_PARTS[1...2]__')
    # }
    # d = create_driver %[
    #   rewriterule1 domain ^www.google.com$ site.Google
    #   rewriterule2 domain ^news.google.com$ site.GoogleNews
    # ]
    # assert_equal 'domain ^www.google.com$ site.Google', d.instance.config['rewriterule1']
    # assert_equal 'domain ^news.google.com$ site.GoogleNews', d.instance.config['rewriterule2']
  end

  # def test_emit
  #   d1 = create_driver(CONFIG, 'input.access')
  #   d1.run do
  #     d1.emit({'domain' => 'www.google.com', 'path' => '/foo/bar?key=value', 'agent' => 'Googlebot', 'response_time' => 1000000})
  #     d1.emit({'domain' => 'news.google.com', 'path' => '/', 'agent' => 'Googlebot-Mobile', 'response_time' => 900000})
  #     d1.emit({'domain' => 'map.google.com', 'path' => '/', 'agent' => 'Macintosh; Intel Mac OS X 10_7_4', 'response_time' => 900000})
  #     d1.emit({'domain' => 'labs.google.com', 'path' => '/', 'agent' => 'Mozilla/5.0 Googlebot-FooBar/2.1', 'response_time' => 900000})
  #     d1.emit({'domain' => 'tagtest.google.com', 'path' => '/', 'agent' => 'Googlebot', 'response_time' => 900000})
  #     d1.emit({'domain' => 'noop.example.com'}) # to be ignored
  #   end
  #   emits = d1.emits
  #   assert_equal 5, emits.length
  #   assert_equal 'site.Google', emits[0][0] # tag
  #   assert_equal 'site.GoogleNews', emits[1][0] # tag
  #   assert_equal 'news.google.com', emits[1][2]['domain']
  #   assert_equal 'agent.MacOSX', emits[2][0] #tag
  #   assert_equal 'agent.Googlebot-FooBar', emits[3][0] #tag
  #   assert_equal 'site.input.access.tagtest', emits[4][0] #tag
  # end
  #
  # def test_emit2_indent_and_capitalize_option
  #   d1 = create_driver(CONFIG_INDENT_SPACE_AND_CAPITALIZE_OPTION, 'input.access')
  #   d1.run do
  #     d1.emit({'domain' => 'www.google.com', 'path' => '/foo/bar?key=value', 'agent' => 'Googlebot', 'response_time' => 1000000})
  #     d1.emit({'domain' => 'news.google.com', 'path' => '/', 'agent' => 'Googlebot-Mobile', 'response_time' => 900000})
  #     d1.emit({'domain' => 'map.google.com', 'path' => '/', 'agent' => 'Macintosh; Intel Mac OS X 10_7_4', 'response_time' => 900000})
  #     d1.emit({'domain' => 'labs.google.com', 'path' => '/', 'agent' => 'Mozilla/5.0 Googlebot-FooBar/2.1', 'response_time' => 900000})
  #   end
  #   emits = d1.emits
  #   assert_equal 4, emits.length
  #   assert_equal 'site.Google', emits[0][0] # tag
  #   assert_equal 'site.GoogleNews', emits[1][0] # tag
  #   assert_equal 'news.google.com', emits[1][2]['domain']
  #   assert_equal 'agent.MacOSX', emits[2][0] #tag
  #   assert_equal 'agent.Googlebot-Foobar', emits[3][0] #tag
  # end
  #
  # def test_emit3_remove_tag_prefix
  #   d1 = create_driver(CONFIG_REMOVE_TAG_PREFIX, 'input.access')
  #   d1.run do
  #     d1.emit({'domain' => 'www.google.com', 'path' => '/foo/bar?key=value', 'agent' => 'Googlebot', 'response_time' => 1000000})
  #   end
  #   emits = d1.emits
  #   assert_equal 1, emits.length
  #   assert_equal 'access', emits[0][0] # tag
  # end
  #
  # def test_emit4_remove_tag_prefix_with_dot
  #   d1 = create_driver(CONFIG_REMOVE_TAG_PREFIX_WITH_DOT, 'input.access')
  #   d1.run do
  #     d1.emit({'domain' => 'www.google.com', 'path' => '/foo/bar?key=value', 'agent' => 'Googlebot', 'response_time' => 1000000})
  #   end
  #   emits = d1.emits
  #   assert_equal 1, emits.length
  #   assert_equal 'access', emits[0][0] # tag
  # end
  #
  # def test_emit5_short_hostname
  #   d1 = create_driver(CONFIG_SHORT_HOSTNAME, 'input.access')
  #   d1.run do
  #     d1.emit({'domain' => 'www.google.com', 'path' => '/foo/bar?key=value', 'agent' => 'Googlebot', 'response_time' => 1000000})
  #   end
  #   emits = d1.emits
  #   assert_equal 1, emits.length
  #   assert_equal `hostname -s`.chomp, emits[0][0] # tag
  # end
  #
  # def test_emit6_non_matching
  #   d1 = create_driver(CONFIG_NON_MATCHING, 'input.access')
  #   d1.run do
  #     d1.emit({'domain' => 'www.google.com'})
  #     d1.emit({'path' => '/'})
  #     d1.emit({'domain' => 'maps.google.com'})
  #   end
  #   emits = d1.emits
  #   assert_equal 3, emits.length
  #   assert_equal 'start_with_www', emits[0][0] # tag
  #   assert_equal 'not_start_with_www', emits[1][0] # tag
  #   assert_equal 'not_start_with_www', emits[2][0] # tag
  # end
  #
  # def test_emit7_jump_index
  #   d1 = create_driver(CONFIG_JUMP_INDEX, 'input.access')
  #   d1.run do
  #     d1.emit({'domain' => 'www.google.com', 'path' => '/', 'agent' => 'Googlebot', 'response_time' => 1000000})
  #     d1.emit({'domain' => 'news.google.com', 'path' => '/', 'agent' => 'Googlebot', 'response_time' => 900000})
  #   end
  #   emits = d1.emits
  #   assert_equal 2, emits.length
  #   assert_equal 'site.Google', emits[0][0] # tag
  #   assert_equal 'site.GoogleNews', emits[1][0] # tag
  # end
  #
  # def test_emit8_split_by_tag
  #   d1 = create_driver(CONFIG_SPLIT_BY_TAG, 'game.production.api')
  #   d1.run do
  #     d1.emit({'user_id' => '10000', 'world' => 'chaos', 'user_name' => 'gamagoori'})
  #     d1.emit({'user_id' => '10001', 'world' => 'chaos', 'user_name' => 'sanageyama'})
  #     d1.emit({'user_id' => '10002', 'world' => 'nehan', 'user_name' => 'inumuta'})
  #     d1.emit({'user_id' => '77777', 'world' => 'space', 'user_name' => 'Lynn Minmay'})
  #     d1.emit({'user_id' => '99999', 'world' => 'space', 'user_name' => 'Harlock'})
  #   end
  #   emits = d1.emits
  #   assert_equal 5, emits.length
  #   assert_equal 'application.game.chaos_server', emits[0][0]
  #   assert_equal 'application.game.chaos_server', emits[1][0]
  #   assert_equal 'application.production.future_server', emits[2][0]
  #   assert_equal 'vip.production.remember_love', emits[3][0]
  #   assert_equal 'api.game.production', emits[4][0]
  # end
  #
  # def test_emit9_invalid_byte
  #   invalid_utf8 = "\xff".force_encoding('UTF-8')
  #   d1 = create_driver(CONFIG_INVALID_BYTE, 'input.activity')
  #   d1.run do
  #     d1.emit({'client_name' => invalid_utf8})
  #   end
  #   emits = d1.emits
  #   assert_equal 1, emits.length
  #   assert_equal "app.?", emits[0][0]
  #   assert_equal invalid_utf8, emits[0][2]['client_name']
  #
  #   invalid_ascii = "\xff".force_encoding('US-ASCII')
  #   d1 = create_driver(CONFIG_INVALID_BYTE, 'input.activity')
  #   d1.run do
  #     d1.emit({'client_name' => invalid_ascii})
  #   end
  #   emits = d1.emits
  #   assert_equal 1, emits.length
  #   assert_equal "app.?", emits[0][0]
  #   assert_equal invalid_ascii, emits[0][2]['client_name']
  # end
end
