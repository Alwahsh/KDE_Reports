class News < ActiveRecord::Base
  resourcify
  belongs_to :user
  attr_accessible :content, :title
  validates :title , :presence => true
  validates :content , :presence => true
end
