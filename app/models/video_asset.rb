class VideoAsset < ActiveRecord::Base
  belongs_to :league
  belongs_to :team
  belongs_to :user

  VIDEO_UPLOADED = VIDEO_BASE+"/uploaded"

  # Virtual attribute to handle uploaded file
  def video=(video_file)
    @temp_file = video_file
    self.uploaded_file_path = sanitize_filename video_file.original_filename
    #self.ext = self.uploaded_file_path.split('.').last
  end

  def video_upload_path(uploaded_file_path=self.uploaded_file_path)
    "#{VIDEO_UPLOADED}/#{id}-#{uploaded_file_path}"
  end

  # Save file after new record is saved so we have the id
  after_save :save_upload_file

  # Quietly delete file when record is destroyed
  after_destroy :delete_file

  private 

  def save_upload_file
    if  @temp_file
      if !File.exist?(VIDEO_BASE)
        Dir.mkdir(VIDEO_BASE)
      end
      if !File.exist?(VIDEO_UPLOADED)
        Dir.mkdir(VIDEO_UPLOADED)
      end
      
      File.open(video_upload_path,"wb") do |f|
        f.write(@temp_file.read)
      end
    end
  end

  def delete_file
    File.rm_f "#{VIDEO_UPLOADED}/#{uploaded_file_path}"
  end

  def sanitize_filename (new_file_name)
    File.basename(new_file_name).gsub(/[^\w\.\-\_]/,'_').gsub(/\\/,'/')
  end
  
end
