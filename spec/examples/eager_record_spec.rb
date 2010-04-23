require File.join(File.dirname(__FILE__), 'spec_helper')

describe EagerRecord do
  describe 'with 1:n association' do
    before :each do
      2.times do
        post = Post.create!
        2.times { post.comments.create! }
      end
      @posts = Post.all
      @comments = Comment.all
    end

    describe 'on has_many' do
      it 'should eagerly preload collection' do
        @posts.first.comments.should == @comments[0..1]
        connection.should_not_receive(:select_all)
        @posts.last.comments.should == @comments[2..3]
      end

      it 'should keep new records in collection when eager-loading' do
        @posts.first.comments.to_a
        connection.should_not_receive(:select_all)
        new_comment = @posts.last.comments.build
        @posts.last.comments.should == @comments[2..3] + [new_comment]
      end
    end

    describe 'on belongs_to' do
      it 'should eagerly preload association' do
        @comments[0].post.should == @posts.first
        connection.should_not_receive(:select_all)
        @comments[1].post.should == @posts.first
        @comments[2..3].each { |comment| comment.post.should == @posts.last }
      end
    end
  end

  private

  def connection
    ActiveRecord::Base.connection
  end
end
