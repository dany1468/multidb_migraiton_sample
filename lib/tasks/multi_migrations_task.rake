namespace :db do
  namespace :multi do
    def configurations(database_name)
      original_configuration = ActiveRecord::Base.configurations

      %w(production development test).each_with_object({}) {|env, configs|
        config_key = "#{env}_#{database_name}"
        configs[env] = original_configuration[config_key] if original_configuration.key?(config_key)
      }
    end

    task :set_custom_db_config_paths do
      database = ENV['DATABASE']

      ENV['SCHEMA'] = Rails.root.join("db/schema_#{database}.rb").to_s

      Rails.application.config.paths['db/migrate'] = [Rails.root.join("db/migrate_#{database}").to_s]
      Rails.application.config.paths['db/seeds.rb'] = [Rails.root.join("db/seeds_#{database}.rb").to_s]
      ActiveRecord::Base.configurations = configurations(database)
      ActiveRecord::Base.establish_connection
    end

    multi_db_task = ->(name) {
      desc "Multi DB Migration db:#{name}"
      task name => [:environment, :set_custom_db_config_paths] do
        Rake::Task["db:#{name}"].execute
      end
    }

    %w(drop create purge schema:load migrate rollback seed version
   schema:dump).each do |task_name|
      multi_db_task[task_name]
    end
  end
end
