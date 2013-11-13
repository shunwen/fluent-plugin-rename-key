class Fluent::RenameKeyOutput < Fluent::Output
  Fluent::Plugin.register_output 'rename-key', self

  config_param :remove_tag_prefix, :string, default: nil

  MATCH_OPERATOR_EXCLUDE = '!'


end
