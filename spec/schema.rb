ActiveRecord::Schema.define do
  create_table :blogs, :force => true do
  end
  create_table :posts, :force => true do |t|
    t.references :blog
  end
  create_table :comments, :force => true do |t|
    t.references :post
  end
  create_table :users, :force => true do |t|
  end
  create_table :posts_users, :force => true, :id => false do |t|
    t.references :post
    t.references :user
  end
end
