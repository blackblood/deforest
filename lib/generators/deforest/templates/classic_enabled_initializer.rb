Deforest.initialize! do |config|
  config.write_logs_to_db_every = 1.minute
  config.most_used_percentile_threshold = 80
  config.least_used_percentile_threshold = 20
  config.track_dirs = ["/app/models", "/app/controllers", "/app/helpers"]
end