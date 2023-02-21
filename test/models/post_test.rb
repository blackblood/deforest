require 'test_helper'

class PostTest < ActiveSupport::TestCase
  setup do
    File.open("deforest_db_sync.txt", "w") { |f| f.write(1.hour.ago.to_i.to_s) }
    Deforest.initialize_db_sync_file    
    Deforest.class_variable_set('@@write_logs_to_db_every', 1.minute)
  end

  teardown do
    File.delete("deforest_db_sync.txt") if File.exist?("deforest_db_sync.txt")
    File.delete("deforest.log") if File.exist?("deforest.log")
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
end
