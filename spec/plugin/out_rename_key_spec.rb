require 'spec_helper'
require 'fluent/plugin/out_rename_key'

describe Fluent::RenameKeyOutput do
  before :each do
    Fluent::Test.setup
  end

  CONFIG = %q[
    rename_rule1 ^\$(.+) ${captures[1]}
    rename_rule2 ^[.]+([^.]+)[.\s]*([^.]+) ${captures[1]}\ssomthing\s${captures[2]}
  ]

  CONFIG_MULTI_RULES_FOR_A_KEY = %q[
    rename_rule1 ^\$(.+) ${captures[1]}
    rename_rule2 ^\$(.+) ${captures[1]}\ssomthing
  ]

  CONFIG_REMOVE_TAG_PREFIX = %q[
    rename_rule1 ^\$(.+) ${captures[1]}\ssomthing
    remove_tag_prefix input
  ]

  CONFIG_APPEND_TAG = %q[
    rename_rule1 ^\$(.+) ${captures[1]}\ssomthing
    append_tag postfix
  ]

  def create_driver conf=CONFIG, tag='test'
    Fluent::Test::OutputTestDriver.new(Fluent::RenameKeyOutput, tag).configure(conf)
  end

  context "configurations" do
    it "raises error when no configuration" do
      expect{create_driver ''}.to raise_error Fluent::ConfigError
    end

    it "raises error when rule is incomplete" do
      expect{create_driver 'rename_rule1 ^$(.+?) '}.to raise_error Fluent::ConfigError
    end

    it "raises error when multiple rules are set for the same key pattern" do
      expect{create_driver CONFIG_MULTI_RULES_FOR_A_KEY}.to raise_error Fluent::ConfigError
    end

    it "configures multiple rules" do
      d = create_driver
      expect(d.instance.config['rename_rule1']).to eq '^\$(.+) ${captures[1]}'
      expect(d.instance.config['rename_rule2']).to eq '^[.]+([^.]+)[.\s]*([^.]+) ${captures[1]}\ssomthing\s${captures[2]}'
    end
  end

  context "emits" do
    it "removes tag prefix" do
      d = create_driver CONFIG_REMOVE_TAG_PREFIX, 'input.test'
      d.run { d.emit 'test' => 'data' }
      expect(d.emits[0][0]).not_to start_with 'input'
    end

    it "appends additional tag" do
      d = create_driver CONFIG_APPEND_TAG, 'input.test'
      d.run { d.emit 'test' => 'data' }
      expect(d.emits[0][0]).to eq 'input.test.postfix'
    end
  end

  context "private methods" do
    describe "#parse_rename_rule" do
      let(:rename_rule_example) { '^\$(.+) #{captures[1]}' }
      let(:result) { Fluent::RenameKeyOutput.new.parse_rename_rule rename_rule_example }

      it "captures 2 items, the key_regexp and new_name" do
        expect(result).to have(2).items
      end
    end

    describe "#rename_key" do
      it "replace key name which matches the key_regexp at the first level" do
        d = create_driver 'rename_rule1 ^\$(.+) x$${captures[1]}'
        d.run do
          d.emit '$url' => 'www.google.com', 'level2' => {'$1' => 'options1'}
        end
        emits = d.emits
        expect(emits).to have(1).items
        expect(emits[0][2]).to have_key 'x$url'
      end
    end
  end

end
