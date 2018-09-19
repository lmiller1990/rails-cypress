class PostsController < ApplicationController
  def index
    @posts = Post.all
  end

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)

    if @post.save
      redirect_to @post
    else
      flash[:errors] = @post.errors.full_messages
      render :new
    end
  end

  def show
    @post = Post.find params[:id]
  end

  def update
    @post = Post.find params[:id]

    if @post.update_attributes(post_params)
      redirect_to @post
    else
      render :edit
    end
  end

  def edit
    @post = Post.find params[:id]
  end

  private

  def post_params 
    params.require(:post).permit(:title, :body, :category_id)
  end
end
