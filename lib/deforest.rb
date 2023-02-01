require "deforest/engine"
require "deforest/version"
require "active_support"
require "active_record"

module Deforest
  mattr_accessor :write_logs_to_db_every_mins, :current_admin_method_name
  @@last_saved_log_file_at = nil
  @@saving_log_file = false

  def self.initialize!
    if block_given?
      yield self
    end
    self.initialize_db_sync_file()
    models = Dir["#{Rails.root}/app/models/**/*.rb"].map do |f|
      idx = f.index("app/models")
      models_heirarchy = f[idx..-1].gsub("app/models/","")
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
      rescue Exception => e
        puts "warning: could not load #{exec_str}"
      end
      puts "Inside Deforest: #{model}"
      if model.present?
        model.instance_methods(false).each do |mname|
          model.instance_eval do
            alias_method "old_#{mname}", mname
            define_method mname do |*args, &block|
              old_method = self.class.instance_method("old_#{mname}")
              file_name, line_no = old_method.source_location
              puts "insert_into_logs(#{mname}, #{file_name}, #{line_no})"
              Deforest.insert_into_logs(mname, file_name, line_no)
              if @@last_saved_log_file_at < Deforest.write_logs_to_db_every_mins.ago && !@@saving_log_file
                Deforest.parse_and_save_log_file()
                t = Time.zone.now
                @@last_saved_log_file_at = t
                File.open("deforest_db_sync.txt", "w") { |f| f.write(t.to_i) }
              end
              old_method.bind(self).call(*args, &block)
            end 
          end
        end
        model.singleton_methods(false).each do |mname|
          model.singleton_class.send(:alias_method, "old_#{mname}", mname)
          model.define_singleton_method mname do |*args, &block|
            old_method = self.singleton_method("old_#{mname}")
            file_name, line_no = old_method.source_location
            puts "insert_into_logs(#{mname}, #{file_name}, #{line_no})"
            Deforest.insert_into_logs(mname, file_name, line_no)
            if @@last_saved_log_file_at < Deforest.write_logs_to_db_every_mins.ago && !@@saving_log_file
              Deforest.parse_and_save_log_file()
              t = Time.zone.now
              @@last_saved_log_file_at = t
              File.open("deforest_db_sync.txt", "w") { |f| f.write(t.to_i) }
            end
            old_method.unbind.bind(self).call(*args, &block)
          end
        end
      end
    end
  end

  def self.initialize_db_sync_file
    if File.exists?("deforest_db_sync.txt")
      @@last_saved_log_file_at = Time.at(File.open("deforest_db_sync.txt").read.to_i)
    else
      File.open("deforest_db_sync.txt", "w") do |f|
        current_time = Time.zone.now.to_i
        @@last_saved_log_file_at = current_time
        f.write(current_time)
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
      sql_stmt += "(#{loc.split("|").map { |s| "'#{s}'" }.join(",")}, #{count}, current_timestamp, current_timestamp),"
    end
    sql_stmt.chomp!(",")
    sql_stmt += ";"
    ActiveRecord::Base.connection.execute(sql_stmt)
    if File.exists?("deforest_tmp.log")
      File.delete("deforest.log")
      File.rename("deforest_tmp.log", "deforest.log")
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
        "<span class='highlight-line #{current_highlight_color}'>" +
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