require "deforest/engine"
require "deforest/version"
require "active_support"
require "active_record"

module Deforest
  mattr_accessor :write_logs_to_db_every, :current_admin_method_name, :most_used_percentile_threshold, :least_used_percentile_threshold, :track_dirs, :render_source_on_browser
  @@last_saved_log_file_at = nil
  @@saving_log_file = false

  def self.get_app_classes(dir)
    Dir["#{Rails.root}#{dir}/**/*.rb"].each do |f|
      idx = f.index(dir)
      models_heirarchy = f[idx..-1].gsub(dir,"")
      exec_str = ""
      loop do
        parent, *children = models_heirarchy.split("/")
        if children.any?
          exec_str += "#{parent.camelize}::"
        else
          exec_str += parent.chomp(".rb").camelize
          break
        end
        models_heirarchy = children.join("/")
      end
      begin
        model = exec_str.constantize
        yield model
      rescue
        puts "Deforest warning: could not track #{exec_str}"
      end
    end
  end

  def self.override_instance_methods_for(klass, dir)
    klass.instance_methods(false).each do |mname|
      if klass.instance_method(mname).source_location.first.ends_with?("#{klass.to_s.underscore}.rb")
        klass.instance_eval do
          alias_method "old_#{mname}", mname
          define_method mname do |*args, &block|
            old_method = self.class.instance_method("old_#{mname}")
            file_name, line_no = old_method.source_location
            if file_name.include?(dir)
              Deforest.insert_into_logs(mname, file_name, line_no)
            end
            if @@last_saved_log_file_at < Deforest.write_logs_to_db_every.ago && !@@saving_log_file
              Deforest.parse_and_save_log_file()
              t = Time.zone.now
              @@last_saved_log_file_at = t
              File.open("deforest_db_sync.txt", "w") { |fl| fl.write(t.to_i) }
            end
            old_method.bind(self).call(*args, &block)
          end 
        end
      end
    end
  end

  def self.override_class_methods_for(klass, dir)
    klass.singleton_methods(false).each do |mname|
      if klass.singleton_method(mname).source_location.first.ends_with?("#{klass.to_s.underscore}.rb")
        klass.singleton_class.send(:alias_method, "old_#{mname}", mname)
        klass.define_singleton_method mname do |*args, &block|
          old_method = self.singleton_method("old_#{mname}")
          file_name, line_no = old_method.source_location
          if file_name.include?(dir)
            Deforest.insert_into_logs(mname, file_name, line_no)
          end
          if @@last_saved_log_file_at < Deforest.write_logs_to_db_every.ago && !@@saving_log_file
            Deforest.parse_and_save_log_file()
            t = Time.zone.now
            @@last_saved_log_file_at = t
            File.open("deforest_db_sync.txt", "w") { |fl| fl.write(t.to_i) }
          end
          old_method.unbind.bind(self).call(*args, &block)
        end
      end
    end
  end
  
  def self.initialize!
    if block_given?
      yield self
    end
    self.initialize_db_sync_file()
    Deforest.track_dirs.each do |dir|
      self.get_app_classes(dir) do |model|
        if model.present?
          self.override_instance_methods_for(model, dir)
          self.override_class_methods_for(model, dir) unless dir.include?("/app/controllers")
        end
      end
    end
  end

  def self.initialize_db_sync_file
    File.open("deforest.log", "w") unless File.exist?("deforest.log")
    if File.exist?("deforest_db_sync.txt")
      @@last_saved_log_file_at = Time.at(File.open("deforest_db_sync.txt").read.to_i)
    else
      File.open("deforest_db_sync.txt", "w") do |f|
        current_time = Time.zone.now
        @@last_saved_log_file_at = current_time
        f.write(current_time.to_i)
      end
    end
  end

  def self.insert_into_logs(method_name, file_name, line_no)
    key = "#{file_name}|#{line_no}|#{method_name}\n"
    log_file_name = @@saving_log_file ? "deforest_tmp.log" : "deforest.log"
    File.open(log_file_name, "a") do |f|
      f.write(key)
    end
  end

  def self.parse_and_save_log_file
    @@saving_log_file = true
    sql_stmt = "INSERT INTO deforest_logs (file_name, line_no, method_name, count, created_at, updated_at) VALUES "
    hash = {}
    File.foreach("deforest.log") do |line|
      line = line.chomp("\n")
      if hash.has_key?(line)
        hash[line] += 1
      else
        hash[line] = 1
      end
    end
    hash.each do |loc, count|
      t = Time.zone.now
      sql_stmt += "(#{loc.split("|").map { |s| "'#{s}'" }.join(",")}, #{count}, '#{t}', '#{t}'),"
    end
    sql_stmt.chomp!(",")
    sql_stmt += ";"
    if hash.present?
      ActiveRecord::Base.connection.execute(sql_stmt)
      if File.exist?("deforest_tmp.log")
        File.delete("deforest.log")
        File.rename("deforest_tmp.log", "deforest.log")
      else
        File.delete("deforest.log")
      end
    end
    @@saving_log_file = false
  end

  def self.prepare_file_for_render(file)
    line_no_count = Log.where(file_name: file).group(:line_no).select("line_no,SUM(count) AS count_sum").inject({}) { |h, el| h.merge!(el.line_no => el.count_sum) }
    stack = []
    current_highlight_color = nil
    highlight = Log.get_highlight_colors_for_file(file)
    prepare_for_render(File.open(file).read) do |line, idx|
      idx += 1
      if line_no_count.has_key?(idx)
        stack = [1]
        current_highlight_color = highlight[idx]
        last_log_for_current_line = Log.where(file_name: file).where(line_no: idx).order("created_at DESC").limit(1).first
        "<span id='#{idx}' class='highlight-line #{current_highlight_color}'>" +
          line +
        "</span>&nbsp;&nbsp;" +
        "<span class='method_call_count'>#{line_no_count[idx]}</span>" +
        "<span class='last_accessed'>last called at: #{last_log_for_current_line.created_at.strftime('%m/%d/%Y')}</span>"
      else
        "<span>#{line}</span>"
      end
    end
  end

  def self.prepare_for_render(source_code, add_line_number = true)
    source_code.split("\n").map.with_index do |line, index|
      first_letter_idx = line.chars.index { |ch| ch != " " }
      if first_letter_idx && first_letter_idx >= 0 && first_letter_idx < line.size
        leading_nbsp = (0...first_letter_idx).map { "&nbsp;" }.join("")
        prepared_line = leading_nbsp.present? ? leading_nbsp + line.lstrip : line.strip
        result_line = if block_given?
          yield prepared_line + "\n", index
        else
          "<span>#{prepared_line}</span>"
        end
        "<span class='line-no'>#{index + 1}</span>" + result_line
      end
    end.join("<br/>")
  end
end