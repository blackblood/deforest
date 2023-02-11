module Deforest
  class Log < ActiveRecord::Base
    def model_name
      idx = self.file_name.index(/\/app\/models\/(\w)*.rb/)
      if idx.present?
        self.file_name[idx, file_name.size].gsub("/app/models/", "").chomp(".rb").camelize
      end
    end

    def self.percentile()
      grouped_logs = Deforest::Log.where("file_name like '%/app/models/%'").group(:file_name, :line_no, :method_name).select("file_name, line_no, method_name, SUM(count) AS count_sum")
      groups_of_count_sum = grouped_logs.group_by { |r| r.count_sum }
      n = groups_of_count_sum.size
      result = Hash.new { |h,k| h[k] = nil }
      groups_of_count_sum.sort_by { |count, logs| count }.each_with_index do |(_, logs), idx|
        logs.each do |log, _|
          result[log] = (idx.to_f / n) * 100
        end
      end
      result
    end

    def self.get_highlight_colors_for_file(file_name)
      result = {}
      self.percentile.select { |log, _| log.file_name == file_name }.each do |log, pcnt|
        result[log.line_no] = if pcnt <= Deforest.least_used_percentile_threshold
          "highlight-green"
        elsif pcnt >= Deforest.most_used_percentile_threshold
          "highlight-red"
        else
          "highlight-yellow"
        end
      end
      result
    end
  end
end
