module Deforest
  class Log < ActiveRecord::Base
    def self.percentile(file_name)
      line_no_count_hash = Log.where("file_name like '%/app/models/%'").where(file_name: file_name).group(:line_no).count
      count_line_no_hash = line_no_count_hash.group_by { |k,v| v }
      n = count_line_no_hash.size
      result = {}
      count_line_no_hash.sort_by { |k,v| k }.each_with_index do |(count, line_numbers), idx|
        line_numbers.each do |line_no, _|
          result[line_no] = (idx.to_f / n) * 100
        end
      end
      result
    end

    def self.get_highlight_colors_from_percentile(percentile_hash)
      result = {}
      percentile_hash.each do |line_no_count, pnct|
        line_no, _ = line_no_count
        result[line_no] = if pnct <= 20
          "highlight-green"
        elsif pnct >= 80
          "highlight-red"
        else
          "highlight-yellow"
        end
      end
      result
    end
  end
end
