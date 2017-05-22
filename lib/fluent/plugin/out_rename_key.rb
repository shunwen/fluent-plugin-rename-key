require 'fluent/plugin/output'
require 'fluent/plugin/rename_key_util'

class Fluent::Plugin::RenameKeyOutput < Fluent::Plugin::Output
  Fluent::Plugin.register_output 'rename_key', self

  helpers :event_emitter

  include Fluent::Plugin::RenameKeyUtil

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

    raise Fluent::ConfigError, 'No rename nor replace rules are given' if @rename_rules.empty? && @replace_rules.empty?

    @remove_tag_prefix = /^#{Regexp.escape @remove_tag_prefix}\.?/ if @remove_tag_prefix
  end

  def multi_workers_ready?
    true
  end

  def process tag, es
    es.each do |time, record|
      new_tag = @remove_tag_prefix ? tag.sub(@remove_tag_prefix, '') : tag
      new_tag = "#{new_tag}.#{@append_tag}".sub(/^\./, '')
      new_record = rename_key record
      new_record = replace_key new_record
      router.emit new_tag, time, new_record
    end
  end
end
