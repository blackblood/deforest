require_dependency "deforest/application_controller"

module Deforest
  class FilesController < ApplicationController
    def dashboard
      @top_percentile_methods = {}
      @medium_percentile_methods = {}
      @low_percentile_methods = {}

      Deforest::Log.percentile(params[:dir] || "/app/models").each do |log, pcnt|
        if pcnt >= Deforest.most_used_percentile_threshold
          @top_percentile_methods[log.method_name] = { color: "highlight-red", total_call_count: log.count_sum, file_name: log.file_name, line_no: log.line_no }
        elsif pcnt <= Deforest.least_used_percentile_threshold
          @low_percentile_methods[log.method_name] = { color: "highlight-green", total_call_count: log.count_sum, file_name: log.file_name, line_no: log.line_no }
        else
          @medium_percentile_methods[log.method_name] = { color: "highlight-yellow", total_call_count: log.count_sum, file_name: log.file_name, line_no: log.line_no }
        end
      end
    end

    def extension_data
      result = Hash.new { |h,k| h[k] = [] }
      Deforest.track_dirs.each do |dir|
        Log.percentile(dir).each do |log, pcnt|
          if pcnt >= Deforest.most_used_percentile_threshold
            result[log.file_name] << { line_no: log.line_no, use_type: "most_used", call_count: log.count_sum }
          elsif pcnt <= Deforest.least_used_percentile_threshold
            result[log.file_name] << { line_no: log.line_no, use_type: "least_used", call_count: log.count_sum }
          else
            result[log.file_name] << { line_no: log.line_no, use_type: "medium_used", call_count: log.count_sum }
          end
        end
      end
      send_data result.to_json, filename: "deforest.json", type: "application/json", disposition: "attachment"
    end
  end
end
