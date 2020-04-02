class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  # GET /posts
  # GET /posts.json
  def index
    @posts = Post.all
  end

  # GET /posts/1
  # GET /posts/1.json
  def show
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts
  # POST /posts.json
  def create
    if (params[:post][:post_type] == "single")
      upload_single_file(params[:post][:detail])
    elsif params[:post][:post_type] == "multiple"
      upload_multiple_file(params[:post][:detail])
    elsif params[:post][:post_type] == "mp4"
      upload_video_file(params[:post][:detail])
    end
    respond_to do |format|
      if @post.present?
        format.html { redirect_to @post, notice: 'Post was successfully created.' }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { redirect_to new_post_path}
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1
  # PATCH/PUT /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to @post, notice: 'Post was successfully updated.' }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.json
  def destroy
    obj = S3_BUCKET.object(@post.detail)
    obj.delete && @post.destroy 
    respond_to do |format|
      format.html { redirect_to posts_url, notice: 'Post was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def post_params
      params.require(:post).permit(:title, :detail)
    end
    
    def upload_single_file(file_details)
      if file_details.content_type == "image/jpeg"
        upload_file(file_details)
      end
    end
    
    def upload_multiple_file(file_details)
      if (file_details.count > 1)
        file_details.each do |data|
          upload_file(data)
        end
      end
    end
    
    def upload_video_file(file_details)
      if file_details.content_type == "video/mp4"
         upload_file(file_details)
      end
    end
    
    def upload_file(file_payload)
      obj = S3_BUCKET.object(file_payload.original_filename)
      obj.put(body: file_payload.to_io)
      @post = Post.create(title: obj.public_url, detail: obj.key)
    end
end