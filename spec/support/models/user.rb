class User < ActiveRecord::Base
  has_and_belongs_to_many :posts

  has_many :groupings
  has_many :groups,
    :through => :groupings,
    :order => 'groups.active_at DESC, groups.id DESC'
end
