class Post < ActiveRecord::Base
  has_many :comments

  def self.get_titles
    Post.all.map(&:title)
  end

  def get_title_with_italics
    "<i>#{self.title}</i>"
  end

  def self.get_posts_created_after(date)
    self.where("DATE(created_at) > DATE(?)", date)
  end

  def self.posts_created_yesterday
    self.where("DATE(created_at) = DATE(?)", Date.yesterday)
  end
end
