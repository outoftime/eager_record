class Asset < ActiveRecord::Base
end

class Photo < Asset
  belongs_to :post
end

class Video < Asset
end
