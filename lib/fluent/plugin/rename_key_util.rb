module Fluent::Plugin
  module RenameKeyUtil
    CONF_RENAME = 'rename_rule'
    CONF_REPLACE = 'replace_rule'

    def create_rename_rules(conf)
      @rename_rules = []
      rule_keys = conf.keys.select { |k| k.strip.start_with? CONF_RENAME }.
          sort_by { |k| k.sub(CONF_RENAME, '').to_i }

      rule_keys.each do |rule_key|
        rule = parse_rename_rule conf[rule_key]

        if @rename_rules.any? { |existing_rule| existing_rule[:key_regexp] == rule[:key_regexp] }
          raise Fluent::ConfigError, "Duplicated rules for key #{rule[:key_regexp].source}: #{@rename_rules}"
        end

        @rename_rules << rule
        log.info "Added rename key rule: #{rule_key} #{@rename_rules.last}"
      end
    end

    def create_replace_rules(conf)
      @replace_rules = []
      rule_keys = conf.keys.select { |k| k.strip.start_with? CONF_REPLACE }.
          sort_by { |k| k.sub(CONF_REPLACE, '').to_i }

      rule_keys.each do |rule_key|
        rule = parse_replace_rule conf[rule_key]

        if @replace_rules.any? { |existing_rule| existing_rule[:key_regexp] == rule[:key_regexp] }
          raise Fluent::ConfigError, "Duplicated rules for key #{rule[:key_regexp].source}: #{@replace_rules}"
        end

        @replace_rules << rule
        log.info "Added replace key rule: #{rule_key} #{@replace_rules.last}"
      end
    end

    def rename_key record
      new_record = {}

      record.each do |key, value|

        @rename_rules.each do |rule|
          match_data = key.match rule[:key_regexp]
          next unless match_data # next rule

          placeholder = get_placeholder match_data
          key = rule[:new_key].gsub /\${md\[\d+\]}/, placeholder
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
          key = key.gsub rule[:key_regexp], rule[:replacement].gsub(/\${md\[\d+\]}/, placeholder)
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

    private

    def parse_rename_rule rule
      m = rule.match(/^([^\s]+)\s+(.+)$/).captures
      { key_regexp: /#{m[0]}/, new_key: m[1] }
    rescue => e
      raise Fluent::ConfigError, "Failed to parse rename rule #{rule} : #{e.message}"
    end

    def parse_replace_rule rule
      m = rule.match(/^([^\s]+)(?:\s+(.+))?$/).captures
      { key_regexp: /#{m[0]}/, replacement: m[1] || '' }
    rescue => e
      raise Fluent::ConfigError, "Failed to parse replace rule #{rule} : #{e.message}"
    end

    def get_placeholder match_data
      placeholder = {}

      match_data.to_a.each_with_index do |e, idx|
        placeholder["${md[#{idx}]}"] = e
      end

      placeholder
    end
  end
end
