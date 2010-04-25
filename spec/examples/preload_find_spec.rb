require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'collection find preloading' do
  before :each do
    2.times do
      post = Post.create!
      post.comments.create!(:approved => true)
      post.comments.create!(:approved => false)
    end
    @posts = Post.all
    @comments = Comment.all
  end

  it 'should preload collection #find results for has_many' do
    @posts[0].comments.approved.should == [@comments[0]]
    fail_on_select
    @posts[1].comments.approved.should == [@comments[2]]
  end
end
