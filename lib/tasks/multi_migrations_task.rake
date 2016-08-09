module MultiMigrations
  def self.make_connection(db_name = nil)
    raise "DATABASE is required" unless ENV['DATABASE']

    connection_key = self.identify_configuration

    raise "VALID DATABASE is required" unless connection_key

    ActiveRecord::Base.establish_connection(connection_key)
  end

  def self.identify_configuration
    if ActiveRecord::Base.configurations.has_key?("#{Rails.env}_#{ENV['DATABASE']}")
      return "#{Rails.env}_#{ENV['DATABASE']}"
    else
      match = ActiveRecord::Base.configurations.find { |config| config[1]['database'] == ENV['DATABASE'] }
      return match[0] unless match.nil?
    end
  end
end

namespace :db do
  namespace :multi do
    task :set_custom_db_config_paths do
      database = ENV['DATABASE']

      ENV['SCHEMA'] = Rails.root.join("db/schema_#{database}.rb").to_s

      Rails.application.config.paths['db/migrate'] = [Rails.root.join("db/migrate_#{database}").to_s]
      Rails.application.config.paths['db/seeds.rb'] = [Rails.root.join("db/seeds_#{database}.rb").to_s]

      MultiMigrations.make_connection database
    end

    multi_db_task = ->(name) {
      desc "Multi DB Migration db:#{name}"
      task name => [:environment, :set_custom_db_config_paths] do
        Rake::Task["db:#{name}"].invoke
      end
    }

    (%w(drop create purge schema:load) + %w(migrate migrate:reset reset rollback seed version
   schema:dump structure:dump structure:load)).each do |task_name|
      multi_db_task[task_name]
    end
  end
end
