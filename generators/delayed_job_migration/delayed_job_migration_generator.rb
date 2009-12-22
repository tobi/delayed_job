class DelayedJobMigrationGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      options = {
        :migration_file_name => 'create_delayed_jobs'
      }

      m.migration_template 'migration.rb', 'db/migrate', options
    end
  end
  
  def banner
    "Usage: #{$0} #{spec.name}"
  end
end
