Deforest.initialize! do |config|
  config.write_logs_to_db_every_mins = 1.minute
  config.current_admin_method_name = :current_admin
end