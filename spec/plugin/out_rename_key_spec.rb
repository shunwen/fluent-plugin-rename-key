require 'spec_helper'
require 'fluent/plugin/out_rename_key'

describe Fluent::RenameKeyOutput do
  before :each do
    Fluent::Test.setup
  end

  CONFIG = %q[
    rename_rule1 ^\$(.+) ${captures[1]} ${tag}.new1
    rename_rule2 ^[.]+([^.]+)[.\s]*([^.]+) ${captures[1]}\ssomthing\s${captures[2]} ${tag}.new2
  ]

  CONFIG_MULTI_RULES_FOR_A_KEY = %q[
    rename_rule1 ^\$(.+) ${captures[1]} new.tag
    rename_rule2 ^\$(.+) ${captures[1]}\ssomthing new.tag
  ]

  CONFIG_REMOVE_TAG_PREFIX = %q[
    rename_rule1 ^\$(.+) ${captures[1]}\ssomthing ${tag}.new
    remove_tag_prefix input
  ]

  def create_driver conf=CONFIG, tag='test'
    Fluent::Test::OutputTestDriver.new(Fluent::RenameKeyOutput, tag).configure(conf)
  end

  context "#configure" do
    it "raises error when no configuration" do
      expect{create_driver ''}.to raise_error Fluent::ConfigError
    end

    it "raises error when rule doesn't provide new tag" do
      expect{create_driver 'rename_rule1 ^$(.+?) ${captures[1]} '}.to raise_error Fluent::ConfigError
    end

    it "raises error when rule is incomplete" do
      expect{create_driver 'rename_rule1 ^$(.+?) '}.to raise_error Fluent::ConfigError
    end

    it "raises error when multiple rules are set for the same key pattern" do
      expect{create_driver CONFIG_MULTI_RULES_FOR_A_KEY}.to raise_error Fluent::ConfigError
    end

    it "configures multiple rules" do
      d = create_driver
      expect(d.instance.config['rename_rule1']).to eq '^\$(.+) ${captures[1]} ${tag}.new1'
      expect(d.instance.config['rename_rule2']).to eq '^[.]+([^.]+)[.\s]*([^.]+) ${captures[1]}\ssomthing\s${captures[2]} ${tag}.new2'
    end
  end

  xit "removes tag prefix" do
    d1 = create_driver CONFIG_REMOVE_TAG_PREFIX, 'input.access'
    d1.run do
      d1.emit '$url' => 'www.google.com', 'path' => '/foo/bar?key=value', 'agent' => 'Googlebot', 'response_time' => 1000000
    end

    emits = d1.emits
    emits.should have(1).items
  end

  context "private methods" do
    describe "#parse_rename_rule" do
      let(:rename_rule_example) { '^\$(.+) #{captures[1]} new.tag' }
      let(:result) { Fluent::RenameKeyOutput.new.parse_rename_rule rename_rule_example }

      it "captures 3 items" do
        expect(result).to have(3).items
      end
    end
  end

end
