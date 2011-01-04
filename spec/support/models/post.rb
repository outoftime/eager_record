class Post < ActiveRecord::Base
  belongs_to :blog
  has_many :comments
  has_and_belongs_to_many :users
  has_many :assets
  has_many :approved_commenters,
           :through => :comments,
           :conditions => { 'comments.approved' => true },
           :readonly => true,
           :source => :user
end
