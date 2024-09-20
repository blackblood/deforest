require "deforest/engine"
require "deforest/version"
require "active_support"
require "active_record"

module Deforest
  mattr_accessor :write_logs_to_db_every, :current_admin_method_name, :most_used_percentile_threshold, :least_used_percentile_threshold, :track_dirs, :last_saved_log_file_at, :saving_log_file

  def self.get_app_classes(dir)
    Dir["#{Rails.root}#{dir}/**/*.rb"].each do |f|
      idx = f.index(dir)
      models_heirarchy = f[idx..-1].gsub(dir,"")
      exec_str = models_heirarchy.split("/").map(&:camelize).join("::").chomp(".rb")
      begin
        model = exec_str.constantize
        yield model
      rescue
        puts "Deforest warning: could not track #{exec_str}"
      end
    end
  end

  def self.inject_tracking_module(klass, dir, method_type)
    track_methods = if method_type == 'instance'
      klass.instance_methods(false)
    elsif method_type == 'class'
      klass.singleton_methods(false)
    else
      raise "Unknown method type: #{method_type}"
    end
    Module.new do
      track_methods.each do |mname|
        method_location = if method_type == 'instance'
          klass.instance_method(mname).source_location
        else
          klass.singleton_method(mname).source_location
        end
        if method_location.first.ends_with?("#{klass.to_s.underscore}.rb")
          define_method mname do |*args, &block|
            file_name, line_no = method_location
            if file_name.include?(dir)
              Deforest.insert_into_logs(mname, file_name, line_no)
            end
            if Deforest.last_saved_log_file_at < Deforest.write_logs_to_db_every.ago && !Deforest.saving_log_file
              Deforest.parse_and_save_log_file()
              t = Time.zone.now
              Deforest.last_saved_log_file_at = t
              File.open("deforest_db_sync.#{Process.pid}.txt", "w") { |fl| fl.write(t.to_i) }
            end
            super(*args, &block)
          end
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
      self.get_app_classes(dir) do |klass|
        if klass.present?
          klass.prepend(Deforest.inject_tracking_module(klass, dir, 'instance'))
          klass.singleton_class.prepend(Deforest.inject_tracking_module(klass, dir, 'class'))
        end
      end
    end
  end

  def self.initialize_db_sync_file
    File.open("deforest.#{Process.pid}.log", "w") unless File.exist?("deforest.#{Process.pid}.log")
    if File.exist?("deforest_db_sync.#{Process.pid}.txt")
      Deforest.last_saved_log_file_at = Time.at(File.open("deforest_db_sync.#{Process.pid}.txt").read.to_i)
    else
      File.open("deforest_db_sync.#{Process.pid}.txt", "w") do |f|
        current_time = Time.zone.now
        Deforest.last_saved_log_file_at = current_time
        f.write(current_time.to_i)
      end
    end
  end

  def self.insert_into_logs(method_name, file_name, line_no)
    key = "#{file_name}|#{line_no}|#{method_name}\n"
    log_file_name = Deforest.saving_log_file ? "deforest_tmp.#{Process.pid}.log" : "deforest.#{Process.pid}.log"
    File.open(log_file_name, "a") do |f|
      f.write(key)
    end
  end

  def self.parse_and_save_log_file
    Deforest.saving_log_file = true
    sql_stmt = "INSERT INTO deforest_logs (file_name, line_no, method_name, count, created_at, updated_at) VALUES "
    hash = {}
    File.foreach("deforest.#{Process.pid}.log") do |line|
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
      if File.exist?("deforest_tmp.#{Process.pid}.log")
        File.delete("deforest.#{Process.pid}.log")
        File.rename("deforest_tmp.#{Process.pid}.log", "deforest.#{Process.pid}.log")
      else
        File.delete("deforest.#{Process.pid}.log")
      end
    end
    Deforest.saving_log_file = false
  end

  def self.most_used_methods(dir, size=1)
    query = Deforest::Log.group(:file_name, :line_no, :method_name)
    if dir.present?
      query = query.where("file_name like '%#{dir}/%'")
    end
    res = query.pluck("file_name, line_no, method_name, SUM(count)")
              .sort_by { |fname, lno, method, cnt| cnt }
              .reverse
    if size == nil
      return res
    else
      return res.take(size)
    end
  end

  def self.least_used_methods(dir, size=1)
    if size == nil
      self.most_used_methods(dir, nil).reverse
    else
      self.most_used_methods(dir, nil).reverse.take(size)
    end
  end
end