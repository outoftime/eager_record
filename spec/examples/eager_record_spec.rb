require File.join(File.dirname(__FILE__), 'spec_helper')

describe EagerRecord do
  before :each do
    2.times do
      blog = Blog.create!
      2.times do
        post = blog.posts.create!
        2.times { post.users.create! }
        2.times { post.comments.create! { |comment| comment.user = post.users.first }}
        2.times { post.assets << Photo.create!(:post_id => post.id) }
        2.times { post.assets << Video.create!(:post_id => post.id) }
      end
    end
    @blogs = Blog.all
    @posts = Post.all
    @comments = Comment.all
    @users = User.all
    @assets = Asset.all

    Grouping.create(
      :user => @posts.first.users.first,
      :group => Group.create(:active_at => DateTime.now)
    )
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

    it 'should not query separately for the instance after preload' do
      Comment.should_receive(:find_by_sql).once.and_return(@comments)
      @posts[0].comments.to_a
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

    it 'should not query separately for the instance after preload' do
      Post.should_receive(:find_by_sql).once.and_return(@posts)
      @comments[0].post.inspect
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

  describe 'collection with STI' do
    it 'should eager-load associated instances without error' do
      lambda { @assets[0].post }.should_not raise_error
    end
  end

  # 
  # There is a bug in ActiveRecord which causes has-many through associations
  # with conditions that reference columns in the joining table to fail, because
  # AR does not include the appropriate join in the query. The least-bad option
  # is just to avoid automatic preloading on associations are has_many :through
  # with conditions.
  #
  describe 'has_many :through associations with conditions' do
    it 'should eager-load associations without error' do
      Comment.update_all(:approved => true)
      post = Post.all.first
      user = post.users.first
      Post.all.first.approved_commenters.should == [user, user]
    end
  end

  #
  # Has-many and has-many-through associations with :finder_sql generate
  # incorrect SQL, because eager_record assumes the wrong (or even
  # non-existing) foreign key. We avoid automatic preloading of these.
  #
  describe 'has_many associations with :finder_sql' do
    it 'should not eagerly load' do
      post = Post.all.first
      user = post.users.first
      Post.all.first.unapproved_commenters.should == [user, user]
    end
  end

  describe 'has_many :through associations with :order' do
    it 'should not generate invalid query' do
      User.all.map(&:groups).flatten.should == [Group.all.first]
    end
  end

  describe 'serialization and deserialization' do
    it 'should not seralize originating collection' do
      post = Marshal.load(Marshal.dump(Post.all.first))
      post.instance_variable_get(:@originating_collection).should be_nil
    end
  end
end
