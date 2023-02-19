require 'test_helper'

module Deforest
  class LogTest < ActiveSupport::TestCase
    setup do
      Deforest.least_used_percentile_threshold = 20
      Deforest.most_used_percentile_threshold = 80
      Deforest.track_dirs = ["/app/models"]
      Setting = nil
      User = nil
    end

    test "get model name" do
      log = deforest_logs(:one)
      assert log.model_name.to_s, Setting
    end

    test "percentile" do
      Log.percentile("/app/models").each do |l,n|
        case l.method_name
        when "refresh_cache"
          assert_equal n, 0
        when "lock_user"
          assert_equal n, 20
        when "open"
          assert_equal n, 40
        when "get_user_name"
          assert_equal n, 60
        when "get_email"
          assert_equal n, 80
        end
      end
    end

    test "get highlight colors for file" do
      res = Log.get_highlight_colors_for_file("/Users/johndoe/workspace/app/models/user.rb")
      res.each do |line_no, color_class|
        if line_no == 100
          assert_equal color_class, "highlight-yellow"
        elsif line_no == 200
          assert_equal color_class, "highlight-red"
        end
      end
    end
  end
end
