require 'fluent/plugin/filter'
require 'fluent/plugin/rename_key_util'

class Fluent::Plugin::RenameKeyFilter < Fluent::Plugin::Filter
  Fluent::Plugin.register_filter 'rename_key', self

  include Fluent::Plugin::RenameKeyUtil

  desc 'Deep rename/replace operation.'
  config_param :deep_rename, :bool, default: true

  def configure conf
    super

    create_rename_rules(conf)
    create_replace_rules(conf)

    raise Fluent::ConfigError, "No rename or replace rules are given" if @rename_rules.empty? && @replace_rules.empty?
  end

  def filter tag, time, record
    new_record = rename_key record
    new_record = replace_key new_record
    new_record
  end
end
