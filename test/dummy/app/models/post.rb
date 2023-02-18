class Post < ActiveRecord::Base
  def self.get_titles
    Post.all.map(&:title)
  end

  def get_title_with_italics
    "<i>#{self.title}</i>"
  end
end
