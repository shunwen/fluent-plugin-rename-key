require 'fluent/plugin/rename_key_util'

class Fluent::RenameKeyOutput < Fluent::Output
  Fluent::Plugin.register_output 'rename_key', self

  include Fluent::RenameKeyUtil

  # To support Fluentd v0.10.57 or earlier
  unless method_defined?(:router)
    define_method("router") { Fluent::Engine }
  end

  # Define `log` method for v0.10.42 or earlier
  unless method_defined?(:log)
    define_method("log") { $log }
  end

  # For fluentd v0.12.16 or earlier
  class << self
    unless method_defined?(:desc)
      def desc(description)
      end
    end
  end

  DEFAULT_APPEND_TAG = 'key_renamed'

  desc 'Specify and remove tag prefix.'
  config_param :remove_tag_prefix, :string, default: nil
  desc "Append custom tag postfix (default: #{DEFAULT_APPEND_TAG})."
  config_param :append_tag, :string, default: DEFAULT_APPEND_TAG
  desc 'Deep rename/replace operation.'
  config_param :deep_rename, :bool, default: true

  def configure conf
    super

    create_rename_rules(conf)
    create_replace_rules(conf)

    raise Fluent::ConfigError, "No rename or replace rules are given" if @rename_rules.empty? && @replace_rules.empty?

    @remove_tag_prefix = /^#{Regexp.escape @remove_tag_prefix}\.?/ if @remove_tag_prefix
  end

  def emit tag, es, chain
    es.each do |time, record|
      new_tag = @remove_tag_prefix ? tag.sub(@remove_tag_prefix, '') : tag
      new_tag = "#{new_tag}.#{@append_tag}".sub(/^\./, '')
      new_record = rename_key record
      new_record = replace_key new_record
      router.emit new_tag, time, new_record
    end

    chain.next
  end
end
