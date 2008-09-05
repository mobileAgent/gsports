class PhotosController < BaseController

  session :cookie_only => false, :only => [:swfupload]
  protect_from_forgery :except => :swfupload

  # POST /photos
  # POST /photos.xml
  # @Override
  def create
    @user = current_user

    @photo = Photo.new(params[:photo])
    @photo.user = @user

    respond_to do |format|
      if @photo.save
        @photo.tag_with(params[:tag_list] || '') 
        
        # update team or league image
        
        h=@photo.height
        w=@photo.width
        if ((h==100 && w==100) || (h==60 && w=234))
          
          if current_user.team_staff? and params[:team_photo]
            @team = @user.team
            @team.avatar= @photo
            
            if @team.save!
              flash[:notice] = "Your changes were saved."
            else
              flash[:notice] = "The change could not be saved: #{@team.errors}"
            end
            
          elsif current_user.league_staff? and params[:league_photo]
            @league = @user.league
            @league.avatar= @photo
            
            if @league.save!
              flash[:notice] = "Your changes were saved."
            else
              flash[:notice] = "The change could not be saved: #{@league.errors}"
            end
            
          end
          
          
        else
          flash[:notice] = "League logo photos must be 100x100 or 234x60, this one is #{w}x#{h}"
        end
        
          
        
        #start the garbage collector
        GC.start        
        flash[:notice] = 'Photo was successfully created.'
        
        format.html { 
          render :action => 'inline_new', :layout => false and return if params[:inline]
          redirect_to user_photo_url(:id => @photo, :user_id => @photo.user) 
        }
        format.js {
          responds_to_parent do
            render :update do |page|
              page << "upload_image_callback('#{@photo.public_filename()}', '#{@photo.display_name}', '#{@photo.id}');"
            end
          end                
        }
      else
        format.html { 
          render :action => 'inline_new', :layout => false and return if params[:inline]                
          render :action => "new" 
        }
        format.js {
          responds_to_parent do
            render :update do |page|
              page.alert('Sorry, there was an error uploading the photo.')
            end
          end                
        }
      end
    end
  end
  
  def verify_team_league_photo

  end
  
  

end
