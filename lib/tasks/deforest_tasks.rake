desc "Copy initializer file to target application"
file "deforest" do
  source_file = "#{Deforest::Engine.root}/lib/tasks/deforest_initializer.rb"
  dest_file = "#{Rails.root}/config/initializers/deforest.rb"
  FileUtils.copy_file source_file, dest_file
  puts "Created initializer config/initiliazer/deforest.rb"
end