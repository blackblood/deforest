require 'rails/generators/base'
require 'rails/generators/migration'

class DeforestGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)

  def copy_migration_file
    migration_template "migration.rb", "db/migrate/create_deforest_logs.rb", migration_version: migration_version
  end

  def copy_initializer_file
    if rails5_and_up? && Rails.autoloaders.zeitwerk_enabled?
      copy_file "zeitwerk_enabled_initializer.rb", "config/initializers/deforest.rb"
    else
      copy_file "classic_enabled_initializer.rb", "config/initializers/deforest.rb"
    end
  end

  def rails5_and_up?
    Rails::VERSION::MAJOR >= 5
  end

  def migration_version
    if rails5_and_up?
      "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
    end
  end

  def self.next_migration_number(dirname)
    if ActiveRecord::Base.timestamped_migrations
      current_time = Time.now.utc
      current_time.strftime("%Y%m%d%H%M%S")
    else
      "%.3d" % (current_numeric_version(dirname) + 1)
    end
  end
end
