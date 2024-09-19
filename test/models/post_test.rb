require 'test_helper'

class PostTest < ActiveSupport::TestCase
  setup do
    File.open("deforest_db_sync.#{Process.pid}.txt", "w") { |f| f.write(1.hour.ago.to_i.to_s) }
    Deforest.initialize_db_sync_file    
    Deforest.class_variable_set('@@write_logs_to_db_every', 1.minute)
  end

  teardown do
    File.delete("deforest_db_sync.#{Process.pid}.txt") if File.exist?("deforest_db_sync.#{Process.pid}.txt")
    File.delete("deforest.#{Process.pid}.log") if File.exist?("deforest.#{Process.pid}.log")
  end

  test "calling a model class method should create a log entry" do
    orig_count = Deforest::Log.count
    Post.get_titles
    assert Deforest::Log.count == orig_count + 1
  end

  test "calling a model instance method should create a log entry" do
    orig_count = Deforest::Log.count
    p = Post.last
    p.get_title_with_italics
    assert Deforest::Log.count == orig_count + 1
  end

  test "get app models" do
    app_models = [Post, User, Comment, Special::Post, Special::Custom::Post]
    Deforest.get_app_classes("/app/models") do |m|
      assert_includes app_models, m
      app_models.delete(m)
    end
  end

  test "most used method" do
    _, _, method_name, _ = Deforest.most_used_methods(nil, 1)[0]
    assert method_name == "get_email"
  end

  test "top 2 most used methods" do
    f1, f2 = Deforest.most_used_methods(nil, 2)
    _, _, method_name, _ = f1
    assert method_name == "get_email"
    _, _, method_name, _ = f2
    assert method_name == "get_user_name"
  end

  test "least used method" do
    _, _, method_name, _ = Deforest.least_used_methods(nil, 1)[0]
    assert method_name == "refresh_cache"
  end

  test "top 2 least used methods" do
    f1, f2 = Deforest.least_used_methods(nil, 2)
    _, _, method_name, _ = f1
    assert method_name == "refresh_cache"
    _, _, method_name, _ = f2
    assert method_name == "lock_user"
  end
end
