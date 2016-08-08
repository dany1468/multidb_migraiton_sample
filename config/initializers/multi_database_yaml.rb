module MultiDatabaseYaml
  def self.slice(database_name, default_config_file = 'database.yml')
    multi_db_config = YAML.load(ERB.new(Rails.root.join('config', default_config_file).read).result)

    %w(production development test).each_with_object({}) {|env, configs|
      config_key = "#{env}_#{database_name}"

      configs[env] = multi_db_config[config_key] if multi_db_config.key?(config_key)
    }.to_yaml
  end
end
