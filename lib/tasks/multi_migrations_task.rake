namespace :multi do
  task :set_custom_db_config_paths do
    database = ENV['DATABASE']

    ENV['SCHEMA'] = Rails.root.join("db/schema_#{database}.rb").to_s

    Rails.application.config.paths['db/migrate'] = [Rails.root.join("db/migrate_#{database}").to_s]
    Rails.application.config.paths['db/seeds'] = [Rails.root.join("db/seeds_#{database}").to_s]
    Rails.application.config.paths['config/database'] = [Rails.root.join("config/database_#{database}.yml").to_s]
  end

  multi_db_task = ->(name) {
    desc "Multi DB Migration #{name}"
    task name => [:environment, :set_custom_db_config_paths] do
      Rake::Task[name].invoke
    end
  }

  %w(db:drop db:create db:purge db:schema:load db:migrate db:migrate:reset db:reset db:rollback db:seed db:version
   db:schema:dump db:structure:dump db:structure:load).each do |task_name|
    multi_db_task[task_name]
  end
end
