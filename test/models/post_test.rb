require 'test_helper'

class PostTest < ActiveSupport::TestCase
  test "calling a model class method should create a log entry" do
    orig_count = Deforest::Log.count
    File.open("deforest_db_sync.txt", "w") { |f| f.write(1.hour.ago.to_i.to_s) }
    Deforest.initialize_db_sync_file
    Post.get_titles
    assert Deforest::Log.count == orig_count + 1
  end

  test "calling a model instance method should create a log entry" do
    orig_count = Deforest::Log.count
    File.open("deforest_db_sync.txt", "w") { |f| f.write(1.hour.ago.to_i.to_s) }
    Deforest.initialize_db_sync_file
    p = posts(:one)
    p.get_title_with_italics
    assert Deforest::Log.count == orig_count + 1
  end

  test "get app models" do
    app_models = [Post, User, Special::Post, Special::Custom::Post]
    Deforest.get_app_classes("/app/models") do |m|
      assert_includes app_models, m
      app_models.delete(m)
    end
  end
end
