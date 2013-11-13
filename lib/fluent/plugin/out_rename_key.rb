class Fluent::RenameKeyOutput < Fluent::Output
  Fluent::Plugin.register_output 'rename-key', self

  config_param :remove_tag_prefix, :string, default: nil

  def configure conf
    super

    @rename_rules = []

    conf_rename_rules = conf.keys.select { |k| k =~ /^rename_rule(\d+)$/ }
    conf_rename_rules.sort_by { |r| r.sub('rename_rule', '').to_i }.each do |r|
      key_regexp, new_key, new_tag = parse_rename_rule conf[r]

      if key_regexp.nil? || new_key.nil? || new_tag.nil?
        raise Fluent::ConfigError, "Failed to parse[#{key_regexp},#{new_key},#{new_tag}]: #{r} #{conf[r]}"
      end

      if new_tag.match /\$\{tags\[\d\.\.\.?\d\]\}/
        raise Fluent::ConfigError, "${tag} does not support range: #{r} #{conf[r]}"
      end

      if @rename_rules.map { |e| e.first }.include? /#{key_regexp}/
        raise Fluent::ConfigError, "Duplicated rules for key #{key_regexp}: #{@rename_rules}"
      end

      @rename_rules << [/#{key_regexp}/, new_key, new_tag]
      $log.info "Added rename key rule: #{r} #{@rename_rules.last}"
    end

    raise Fluent::ConfigError, "No rename rules are given" if @rename_rules.empty?
    @remove_tag_prefix = /^#{Regexp.escape @remove_tag_prefix}/ if @remove_tag_prefix
  end

  def emit tag, es, chain
    es.each do |time, record|
      new_tag = retag tag, record
      next if new_tag.nil? || new_tag == tag
      Fluent::Engine.emit new_tag, time, record
    end
  end

  # private

  def parse_rename_rule rule
    if rule.match /^([^\s]+)\s+([^\s]+)\s+([^\s]+)$/
      return $~.captures
    end
  end

  def retag tag, record

  end

  def filter_key_starts_with_dollar_sign original_params
    filtered_params = {}
    original_params.each do |key, value|
      key = 'x$' + key[1..-1] if key.start_with? '$'
      value = filter_key_starts_with_dollar_sign value if value.is_a? Hash
      filtered_params[key] = value
    end

    filtered_params
  end
end
