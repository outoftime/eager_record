require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'collection find preloading' do
  before :each do
    @blog = Blog.create!
    2.times do
      post = Post.create!(:blog => @blog)
      post.comments.create!(:approved => true)
    end
    @posts = @blog.posts
    @comments = Comment.all
  end

  it 'should preload collection #find results for has_many' do
    @posts[0].comments.should == [@comments[0]]
    fail_on_select
    @posts[1].comments.should == [@comments[1]]
  end

  it 'should use normal find if record did not originate in a collection' do
    Post.first.comments.approved.should == [@comments[0]]
  end
end

describe 'collection find preloading' do
  before :each do
    @post = Post.create!
    @replies = []
    10.times do
      c = @post.comments.create!(:approved => true)
      @replies << @post.comments.create!(:approved => true, :reply_to => c)
    end
  end

  it 'should not perform selects for items in association without a foreign key' do
    p = @post.reload
    comments = p.comments
    comments.inspect
    fail_on_select
    comments.each { |c| c.reply_to.inspect unless c.reply_to_id }
  end
end
