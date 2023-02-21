class Comment < ActiveRecord::Base
  belongs_to :post

  def stupid_comment?
    stupid_words = ["very good", "nice"]
    self.body.length < 20 && stupid_words.find { |w| self.body.include?(w) }
  end

  def contains_embedded_links?
    (self.body =~ /<a.*>.+<\/a>/i) != nil
  end
end
