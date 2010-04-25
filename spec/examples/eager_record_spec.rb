require File.join(File.dirname(__FILE__), 'spec_helper')

describe EagerRecord do
  before :each do
    2.times do
      blog = Blog.create!
      2.times do
        post = blog.posts.create!
        2.times { post.comments.create! }
        2.times { post.users.create! }
      end
    end
    @blogs = Blog.all
    @posts = Post.all
    @comments = Comment.all
    @users = User.all
  end

  describe 'with has_many' do
    it 'should eagerly preload collection' do
      @posts.first.comments.should == @comments[0..1]
      fail_on_select
      @posts[1].comments.should == @comments[2..3]
    end

    it 'should keep new records in collection when eager-loading' do
      @posts[0].comments.to_a
      fail_on_select
      new_comment = @posts[1].comments.build
      @posts[1].comments.should == @comments[2..3] + [new_comment]
    end

    it 'should not attempt to reload collection if empty' do
      Post.create!
      @posts = Post.all
      @posts.first.comments.to_a
      fail_on_select
      @posts.last.comments.should == []
    end
  end

  describe 'with belongs_to' do
    it 'should eagerly preload association' do
      @comments[0].post.should == @posts.first
      fail_on_select
      @comments[1].post.should == @posts.first
      @comments[2..3].each { |comment| comment.post.should == @posts[1] }
    end

    it 'should not attempt to reload association if empty' do
      Comment.create!
      @comments = Comment.all
      @comments[0].post.inspect
      fail_on_select
      @comments.last.post.should be_nil
    end

    it 'should not attempt to reload association if broken' do
      pending 'getting this to work'
      Comment.create! { |c| c.post_id = 0 }
      @comments = Comment.all
      @comments[0].post.inspect
      fail_on_select
      @comments.last.post.should be_nil
    end
  end

  describe 'with has_many :through association' do

    it 'should eager load second-level collection' do
      @blogs.first.comments.inspect
      fail_on_select
      @blogs.last.comments.should == @comments[4..7]
    end
  end

  describe 'HABTM association' do
    before :each do
      2.times do
        post = Post.create!
      end
      @posts = Post.all
      @users = User.all
    end

    it 'should eager load collection' do
      @posts[0].users.inspect
      fail_on_select
      @posts[1].users.should == @users[2..3]
    end
  end

  describe 'chained associations' do
    it 'should eager-load second chained association' do
      @blogs[0].posts[0].comments.inspect
      fail_on_select
      @blogs[1].posts[0].comments.should == @comments[4..5]
    end
  end
end
