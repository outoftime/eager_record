ActiveRecord::Schema.define do
  create_table :blogs, :force => true do
  end
  create_table :posts, :force => true do |t|
    t.references :blog
  end
  create_table :comments, :force => true do |t|
    t.references :post
    t.boolean :approved, :null => false, :default => false
  end
  create_table :users, :force => true do |t|
  end
  create_table :posts_users, :force => true, :id => false do |t|
    t.references :post
    t.references :user
  end
  create_table :assets, :force => true do |t|
    t.references :post
    t.string :type
  end
end
