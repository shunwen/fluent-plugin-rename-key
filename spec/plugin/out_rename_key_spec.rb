require 'spec_helper'
require 'fluent/plugin/out_rename_key'

describe Fluent::RenameKeyOutput do
  before :each do
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
      expect(d.instance.config['rename_rule1']).to eq '^\$(.+) x$${md[1]}'
      expect(d.instance.config['rename_rule2']).to eq '^l(eve)l(\d+) ${md[1]}_${md[2]}'
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
      let(:rename_rule_example) { '^\$(.+) ${md[1]}' }
      let(:rename_rule_result) { Fluent::RenameKeyOutput.new.parse_rename_rule rename_rule_example }

      it "captures 2 items, the key_regexp and new_name" do
        expect(rename_rule_result.size).to eq 2
      end
    end

    describe "#parse_replace_rule" do
      let(:replace_rule_example1) { '- _' } # Replace hyphens with underscores
      let(:replace_rule_result1) { Fluent::RenameKeyOutput.new.parse_replace_rule replace_rule_example1 }

      let(:replace_rule_example2) { '[()-\s]' } # Remove all parethesis hyphens and spaces
      let(:replace_rule_result2) { Fluent::RenameKeyOutput.new.parse_replace_rule replace_rule_example2 }

      it "captures 2 items, the key_regexp and replacement" do
        expect(replace_rule_result1.size).to eq 2
        expect(replace_rule_result1[0]).to eq '-'
        expect(replace_rule_result1[1]).to eq '_'
      end

      it "captures 1 items, the key_regexp to remove" do
        expect(replace_rule_result2.size).to eq 2
        expect(replace_rule_result2[0]).to eq '[()-\s]'
        expect(replace_rule_result2[1]).to eq nil
      end
    end

    describe "#rename_key" do
      it "replace key name which matches the key_regexp at all level" do
        d = create_driver %q[
          rename_rule1 ^\$(.+) x$${md[1]}
        ]
        d.run do
          d.emit '$url' => 'www.google.com', 'level2' => {'id'=>'something', 'a'=>{'$1' => 'option1'}}
        end
        result = d.emits[0][2]
        p result
        expect(result).to have_key 'x$url'
        expect(result['level2']['a']).to have_key 'x$1'
      end

      it "replace key name only at the first level when deep_rename is false" do
        d = create_driver %q[
          rename_rule1 ^\$(.+) x$${md[1]}
          deep_rename false
        ]
        d.run do
          d.emit '$url' => 'www.google.com', 'level2' => {'id'=>'something', 'a'=>{'$1' => 'option1'}}
        end
        result = d.emits[0][2]
        expect(result).to have_key 'x$url'
        expect(result['level2']['a']).to have_key '$1'
      end

      it "replace key of hashes in an array" do
        d = create_driver 'rename_rule1 ^\$(.+)\s(\w+) x$${md[2]} ${md[1]}'
        d.run do
          d.emit 'array' => [{'$url jump' => 'www.google.com'}, {'$url run' => 'www.google.com'}], 'level2' => {'$1' => 'options1'}
        end
        result = d.emits[0][2]
        expect(result['array'][0]).to have_key 'x$jump url'
        expect(result['array'][1]).to have_key 'x$run url'
      end

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

    describe "#replace_key" do

      it "replace key name which matches the key_regexp at all level" do
        d = create_driver %q[
          replace_rule1 ^(\$) x
        ]
        d.run do
          d.emit '$url' => 'www.google.com', 'level2' => {'id'=>'something', 'a'=>{'$1' => 'option1'}}
        end
        result = d.emits[0][2]
        p result
        expect(result).to have_key 'xurl'
        expect(result['level2']['a']).to have_key 'x1'
      end

      it "replace key name only at the first level when deep_rename is false" do
        d = create_driver %q[
          replace_rule1 ^\$ x
          deep_rename false
        ]
        d.run do
          d.emit '$url' => 'www.google.com', 'level2' => {'id'=>'something', 'a'=>{'$1' => 'option1'}}
        end
        result = d.emits[0][2]
        expect(result).to have_key 'xurl'
        expect(result['level2']['a']).to have_key '$1'
      end

      it "replace key of hashes in an array" do
        d = create_driver 'replace_rule1 ^(\$) x${md[1]}'
        d.run do
          d.emit 'array' => [{'$url jump' => 'www.google.com'}, {'$url run' => 'www.google.com'}], 'level2' => {'$1' => 'options1'}
        end
        result = d.emits[0][2]
        expect(result['array'][0]).to have_key 'x$url jump'
        expect(result['array'][1]).to have_key 'x$url run'
      end

      it "replaces key name using match data" do
        d = create_driver 'replace_rule1 ^\$(url) x${md[1]}'
        d.run do
          d.emit '$url jump' => 'www.google.com', 'level2' => {'$1' => 'options1'}
        end
        result = d.emits[0][2]
        expect(result).to have_key 'xurl jump'
      end

      it "removes certain characters from key" do
        d = create_driver 'replace_rule1 [\s/()]'
        d.run do
          d.emit 'us/op (read)' => 42
        end
        result = d.emits[0][2]
        expect(result).to have_key 'usopread'
      end

      it "replaces key using multiple rules" do
        d = create_driver %q[
          rename_rule1 ^(.+)$ lt_${md[1]}
          replace_rule1 - _
        ]
        d.run do
          d.emit '100u-200u' => 23
        end
        result = d.emits[0][2]
        expect(result).to have_key 'lt_100u_200u'
      end
    end
  end

end
