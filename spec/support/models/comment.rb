class Comment < ActiveRecord::Base
  belongs_to :post
  belongs_to :user
  belongs_to :reply_to, :class_name => 'Comment'

  named_scope :approved, :conditions => { :approved => true }
end
