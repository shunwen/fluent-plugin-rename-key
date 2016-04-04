class Fluent::RenameKeyOutput < Fluent::Output
  Fluent::Plugin.register_output 'rename_key', self

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

    @rename_rules = []
    conf_rename_rules = conf.keys.select { |k| k =~ /^rename_rule(\d+)$/ }
    conf_rename_rules.sort_by { |r| r.sub('rename_rule', '').to_i }.each do |r|
      key_regexp, new_key = parse_rename_rule conf[r]

      if key_regexp.nil? || new_key.nil?
        raise Fluent::ConfigError, "Failed to parse: #{r} #{conf[r]}"
      end

      if @rename_rules.map { |r| r[:key_regexp] }.include? /#{key_regexp}/
        raise Fluent::ConfigError, "Duplicated rules for key #{key_regexp}: #{@rename_rules}"
      end

      @rename_rules << { key_regexp: /#{key_regexp}/, new_key: new_key }
      log.info "Added rename key rule: #{r} #{@rename_rules.last}"
    end

    @replace_rules = []
    conf_replace_rules = conf.keys.select { |k| k =~ /^replace_rule(\d+)$/ }
    conf_replace_rules.sort_by { |r| r.sub('replace_rule', '').to_i }.each do |r|
      key_regexp, replacement = parse_replace_rule conf[r]

      if key_regexp.nil?
        raise Fluent::ConfigError, "Failed to parse: #{r} #{conf[r]}"
      end

      if replacement.nil?
          replacement = ""
      end

      if @replace_rules.map { |r| r[:key_regexp] }.include? /#{key_regexp}/
        raise Fluent::ConfigError, "Duplicated rules for key #{key_regexp}: #{@replace_rules}"
      end

      @replace_rules << { key_regexp: /#{key_regexp}/, replacement: replacement }
      log.info "Added replace key rule: #{r} #{@replace_rules.last}"
    end

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

  # private

  def parse_rename_rule rule
    if rule.match /^([^\s]+)\s+(.+)$/
      $~.captures
    end
  end

  def parse_replace_rule rule
    if rule.match /^([^\s]+)(?:\s+(.+))?$/
      $~.captures
    end
  end

  def rename_key record
    new_record = {}

    record.each do |key, value|

      @rename_rules.each do |rule|
        match_data = key.match rule[:key_regexp]
        next unless match_data # next rule

        placeholder = get_placeholder match_data
        key = rule[:new_key].gsub /\${\w+\[\d+\]?}/, placeholder
        break
      end

      if @deep_rename
        if value.is_a? Hash
          value = rename_key value
        elsif value.is_a? Array
          value = value.map { |v| v.is_a?(Hash) ? rename_key(v) : v }
        end
      end

      new_record[key] = value
    end

    new_record
  end

  def replace_key record
    new_record = {}

    record.each do |key, value|

      @replace_rules.each do |rule|
        match_data = key.match rule[:key_regexp]
        next unless match_data # next rule

        placeholder = get_placeholder match_data
        key = key.gsub rule[:key_regexp], rule[:replacement].gsub(/\${\w+\[\d+\]?}/, placeholder)
        break
      end

      if @deep_rename
        if value.is_a? Hash
          value = replace_key value
        elsif value.is_a? Array
          value = value.map { |v| v.is_a?(Hash) ? replace_key(v) : v }
        end
      end

      new_record[key] = value
    end

    new_record
  end

  def get_placeholder match_data
    placeholder = {}

    match_data.to_a.each_with_index do |e, idx|
      placeholder.store "${md[#{idx}]}", e
    end

    placeholder
  end

end
