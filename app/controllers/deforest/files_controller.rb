require_dependency "deforest/application_controller"

module Deforest
  class FilesController < ApplicationController
    def dashboard
      @top_percentile_methods = {}
      @medium_percentile_methods = {}
      @low_percentile_methods = {}

      Deforest::Log.percentile().each do |log, pcnt|
        if pcnt >= 80
          @top_percentile_methods["#{log.model_name}##{log.method_name}"] = { color: "highlight-red", total_call_count: log.count_sum }
        elsif pcnt <= 20
          @low_percentile_methods["#{log.model_name}##{log.method_name}"] = { color: "highlight-green", total_call_count: log.count_sum }
        else
          @medium_percentile_methods["#{log.model_name}##{log.method_name}"] = { color: "highlight-yellow", total_call_count: log.count_sum }
        end
      end
    end

    def index
      @dirs = []
      @files = []
      Dir["#{Rails.root}/app/models/**/*.rb"].each do |m|
        idx = m.index("app/models")
        models_heirarchy = m[idx..-1].gsub("app/models/","")
        parent, *children = models_heirarchy.split("/")
        if children.present?
          @dirs << parent
        else
          @files << parent
        end
      end
      @dirs.uniq!
    end

    def show
      @full_path = "#{Rails.root}/app/models/#{params[:file_name]}.rb"
    end
  end
end
