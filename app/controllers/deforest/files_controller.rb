require_dependency "deforest/application_controller"

module Deforest
  class FilesController < ApplicationController
    def dashboard
      @method_counts = []
      Deforest::Log.group(:file_name, :method_name).count.sort_by { |line_no, n_calls| n_calls }.reverse.each do |file_method_name, call_count|
        file_name, method_name = file_method_name
        idx = file_name.index(/\/app\/models\/(\w)*.rb/)
        next if idx.blank?
        model_class_name = file_name[idx, file_name.size].gsub("/app/models/", "").chomp(".rb").camelize
        @method_counts << ["#{model_class_name}##{method_name}", call_count]
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
