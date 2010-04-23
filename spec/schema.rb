ActiveRecord::Schema.define do
  create_table :posts, :force => true do |t|
  end
  create_table :comments, :force => true do |t|
    t.references :post
  end
end
