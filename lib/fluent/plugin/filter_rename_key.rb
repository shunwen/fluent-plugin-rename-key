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

    if @rename_rules.empty? && @replace_rules.empty?
      raise Fluent::ConfigError, 'No rename nor replace rule given'
    end
  end

  def filter _tag, _time, record
    replace_key(rename_key(record))
  end
end
