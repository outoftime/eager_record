class Comment < ActiveRecord::Base
  belongs_to :post

  named_scope :approved, :conditions => { :approved => true }
end
