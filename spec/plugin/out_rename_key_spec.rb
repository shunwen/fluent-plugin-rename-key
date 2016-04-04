require 'spec_helper'
require 'fluent/plugin/out_rename_key'

describe Fluent::RenameKeyOutput do
  before :each do
    Fluent::Test.setup
  end

  CONFIG = %q[
    rename_rule1 ^\$(.+) x$${md[1]}
    rename_rule2 ^(level)(\d+) ${md[1]}_${md[2]}
  ]

  def create_driver conf=CONFIG, tag='test'
    Fluent::Test::OutputTestDriver.new(Fluent::RenameKeyOutput, tag).configure(conf)
  end

  context "private methods" do
    describe "#parse_rename_rule" do
      let(:rename_rule_example) { '^\$(.+) ${md[1]}' }
      let(:result) { Fluent::RenameKeyOutput.new.parse_rename_rule rename_rule_example }

      it "captures 2 items, the key_regexp and new_name" do
        expect(result).to have(2).items
      end
    end

    describe "#rename_key" do

      it "replaces key name using match data" do
        d = create_driver 'rename_rule1 ^\$(.+)\s(\w+) x$${md[2]} ${md[1]}'
        d.run do
          d.emit '$url jump' => 'www.google.com', 'level2' => {'$1' => 'options1'}
        end
        result = d.emits[0][2]
        expect(result).to have_key 'x$jump url'
      end

      it "replaces key using multiple rules" do
        d = create_driver
        d.run do
          d.emit '$url jump' => 'www.google.com', 'level2' => {'$1' => 'options1'}
        end
        result = d.emits[0][2]
        expect(result).to have_key 'eve_2'
        expect(result['eve_2']).to have_key 'x$1'
      end
    end
  end

end
