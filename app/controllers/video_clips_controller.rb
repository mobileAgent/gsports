class VideoClipsController < ApplicationController
  # GET /video_clips
  # GET /video_clips.xml
  def index
    @video_clips = VideoClip.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @video_clips }
    end
  end

  # GET /video_clips/1
  # GET /video_clips/1.xml
  def show
    @video_clip = VideoClip.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @video_clip }
    end
  end

  # GET /video_clips/new
  # GET /video_clips/new.xml
  def new
    @video_clip = VideoClip.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @video_clip }
    end
  end

  # GET /video_clips/1/edit
  def edit
    @video_clip = VideoClip.find(params[:id])
  end

  # POST /video_clips
  # POST /video_clips.xml
  def create
    @video_clip = VideoClip.new(params[:video_clip])

    respond_to do |format|
      if @video_clip.save
        flash[:notice] = 'VideoClip was successfully created.'
        format.html { redirect_to(@video_clip) }
        format.xml  { render :xml => @video_clip, :status => :created, :location => @video_clip }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @video_clip.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /video_clips/1
  # PUT /video_clips/1.xml
  def update
    @video_clip = VideoClip.find(params[:id])

    respond_to do |format|
      if @video_clip.update_attributes(params[:video_clip])
        flash[:notice] = 'VideoClip was successfully updated.'
        format.html { redirect_to(@video_clip) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @video_clip.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /video_clips/1
  # DELETE /video_clips/1.xml
  def destroy
    @video_clip = VideoClip.find(params[:id])
    @video_clip.destroy

    respond_to do |format|
      format.html { redirect_to(video_clips_url) }
      format.xml  { head :ok }
    end
  end
end
