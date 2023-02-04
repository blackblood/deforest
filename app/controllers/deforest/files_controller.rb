require_dependency "deforest/application_controller"

module Deforest
  class FilesController < ApplicationController
    before_action :check_if_admin_logged_in

    def dashboard
      @top_percentile_methods = {}
      @medium_percentile_methods = {}
      @low_percentile_methods = {}

      Deforest::Log.percentile().each do |log, pcnt|
        if pcnt >= Deforest.most_used_percentile_threshold
          @top_percentile_methods["#{log.model_name}##{log.method_name}"] = { color: "highlight-red", total_call_count: log.count_sum }
        elsif pcnt <= Deforest.least_used_percentile_threshold
          @low_percentile_methods["#{log.model_name}##{log.method_name}"] = { color: "highlight-green", total_call_count: log.count_sum }
        else
          @medium_percentile_methods["#{log.model_name}##{log.method_name}"] = { color: "highlight-yellow", total_call_count: log.count_sum }
        end
      end
    end

    def index
      @dirs = []
      @files = []
      @path = params[:path] || "#{Rails.root}/app/models"
      Dir.entries(@path)[2..-1].each do |m|
        if Dir.exists?("#{@path}/#{m}")
          @dirs << m
        else
          @files << m
        end
      end
      @dirs.uniq!
    end

    def show
      @full_path = "#{params[:path]}/#{params[:file_name]}.rb"
    end

    private

    def check_if_admin_logged_in
      if send(Deforest.current_admin_method_name).blank?
        raise ActionController::RoutingError.new('Not Found')
      end
    end
  end
end
