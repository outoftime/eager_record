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
  has_many :unapproved_commenters,
           :class_name => 'User',
           :finder_sql => %q{
             SELECT users.* FROM comments
             INNER JOIN users ON (users.id = comments.user_id)
             WHERE comments.post_id = #{id} AND comments.approved = 'f'
           }
end
