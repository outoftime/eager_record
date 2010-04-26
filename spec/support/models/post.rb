class Post < ActiveRecord::Base
  has_many :comments
  has_and_belongs_to_many :users
  has_many :assets
end
