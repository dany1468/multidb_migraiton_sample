namespace :db do
  namespace :multi_ext do
    def configurations(database_name)
      original_configuration = Rails.application.config.database_configuration

      %w(production development test).each_with_object({}) {|env, configs|
        config_key = "#{env}_#{database_name}"
        configs[env] = original_configuration[config_key] if original_configuration.key?(config_key)
      }
    end

    def set_custom_db_config_paths
      database = ENV['DATABASE']

      ENV['SCHEMA'] = Rails.root.join("db/schema_#{database}.rb").to_s

      Rails.application.config.paths['db/seeds.rb'] = [Rails.root.join("db/seeds_#{database}.rb").to_s]

      # NOTE load_config の代わり
      ActiveRecord::Base.configurations = configurations(database)
      ActiveRecord::Tasks::DatabaseTasks.migrations_paths = [Rails.root.join("db/migrate_#{database}").to_s]
      ActiveRecord::Migrator.migrations_paths = ActiveRecord::Tasks::DatabaseTasks.migrations_paths

      ActiveRecord::Base.establish_connection

      yield
    end

    multi_db_task = ->(name) {
      desc "Multi DB Migration db:#{name}"
      task name do
        Rake::Task['environment'].invoke

        # NOTE invoke だと依存タスクの load_config が呼ばれて、ActiveRecord::Base.configurations が
        #      再度上書きされてしまうため、execute を使って、対象のタスクだけを呼び出すようにしている。
        set_custom_db_config_paths do
          Rake::Task["db:#{name}"].execute
        end
      end
    }

    %w(drop create purge schema:load migrate rollback seed version
   schema:dump structure:dump structure:load).each do |task_name|
      multi_db_task[task_name]
    end

    namespace :all do
      multi_db_all_task = ->(name) {
        desc "Multi DB All Migration db:#{name}"
        task name do
          %w(blog user).each do |database|
            ENV['DATABASE'] = database

            Rake::Task["db:multi_ext:#{name}"].execute
          end
        end
      }

      %w(drop create purge schema:load migrate seed version
   schema:dump).each do |task_name|
        multi_db_all_task[task_name]
      end
    end
  end
end
