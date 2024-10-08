require 'rails/generators/base'
require 'rails/generators/migration'

class DeforestGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)

  def copy_migration_file
    migration_template "migration.rb", "db/migrate/create_deforest_logs.rb", migration_version: migration_version
  end

  def copy_initializer_file
    if DeforestGenerator.rails5_and_up? && Rails.autoloaders.zeitwerk_enabled?
      copy_file "zeitwerk_enabled_initializer.rb", "config/initializers/deforest.rb"
    else
      copy_file "classic_enabled_initializer.rb", "config/initializers/deforest.rb"
    end
  end

  def self.rails5_and_up?
    Rails::VERSION::MAJOR >= 5
  end

  def migration_version
    if DeforestGenerator.rails5_and_up?
      "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
    end
  end

  def self.next_migration_number(dirname)
    if (rails5_and_up? && ActiveRecord.timestamped_migrations) || ActiveRecord::Base.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    else
      "%.3d" % (current_numeric_version(dirname) + 1)
    end
  end
end
