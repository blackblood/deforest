require 'test_helper'

class DeforestTest < ActiveSupport::TestCase
  setup do
    File.open("deforest_db_sync.#{Process.pid}.txt", "w") { |f| f.write(1.hour.ago.to_i.to_s) }
    Deforest.initialize_db_sync_file
    Deforest.class_variable_set('@@write_logs_to_db_every', 1.minute)
  end

  teardown do
    File.delete("deforest_db_sync.#{Process.pid}.txt") if File.exist?("deforest_db_sync.#{Process.pid}.txt")
    File.delete("deforest.#{Process.pid}.log") if File.exist?("deforest.#{Process.pid}.log")
  end

  test "initialize db_sync_file when db_sync_file does not exist" do
    File.delete("deforest_db_sync.#{Process.pid}.txt")
    Deforest.initialize_db_sync_file
    assert Deforest.class_variable_get("@@last_saved_log_file_at") > 1.minute.ago
  end

  test "initialize db_sync_file when db_sync_file does exist" do
    File.open("deforest_db_sync.#{Process.pid}.txt", "w") { |f| f.write("1676127114") }
    Deforest.initialize_db_sync_file
    assert Deforest.class_variable_get("@@last_saved_log_file_at") == Time.at(1676127114)
  end

  test "insert into logs" do
    Deforest.insert_into_logs("lock_user", "/Users/johndoe/workspace/app/models/doctor.rb", 2144)
    File.foreach("deforest.#{Process.pid}.log") do |line|
      line = line.chomp("\n")
      file_name, line_no, method_name  = line.split("|")
      assert file_name == "/Users/johndoe/workspace/app/models/doctor.rb", "file_name mismatched"
      assert method_name == "lock_user", "method_name mismatched"
      assert line_no == "2144", "line_no mismatched"
    end
  end

  test "parse_and_save_log_file" do
    Deforest.insert_into_logs("get_email", "/Users/johndoe/workspace/app/models/corporate.rb", 2144)
    Deforest.insert_into_logs("get_name", "/Users/johndoe/workspace/app/models/myuser.rb", 120)
    Deforest.insert_into_logs("get_title", "/Users/johndoe/workspace/app/models/post.rb", 2211)
    Deforest.insert_into_logs("get_title", "/Users/johndoe/workspace/app/models/post.rb", 2211)
    Deforest.insert_into_logs("get_body", "/Users/johndoe/workspace/app/models/comment.rb", 879)

    Deforest.parse_and_save_log_file()

    assert Deforest::Log.where(file_name: "/Users/johndoe/workspace/app/models/corporate.rb").last.count == 1
    assert Deforest::Log.where(file_name: "/Users/johndoe/workspace/app/models/post.rb").last.count == 2
    assert Deforest::Log.where(file_name: "/Users/johndoe/workspace/app/models/myuser.rb").last.count == 1
    assert Deforest::Log.where(file_name: "/Users/johndoe/workspace/app/models/comment.rb").last.count == 1
  end
end
