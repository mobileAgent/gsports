class VideoAsset < ActiveRecord::Base
  
  belongs_to :league
  belongs_to :team
  belongs_to :user
  belongs_to :home_team, :class_name => 'Team', :foreign_key => 'home_team_id'
  belongs_to :visiting_team, :class_name => 'Team', :foreign_key => 'visiting_team_id'
  has_many :video_clips
  
  acts_as_commentable
  acts_as_taggable
  has_many :favorites, :as => :favoritable, :dependent => :destroy
  acts_as_activity :user, :if => Proc.new{|r| r.video_status == 'ready' }
  
  attr_protected :team_name
  
  # Every video needs a title
  validates_presence_of :title

  # Video upload repository
  VIDEO_REPOSITORY = VIDEO_BASE+"/uploaded"

  def self.video_repository
    VIDEO_REPOSITORY
  end

  # Move the swfuploaded tmp file into the repo with the user specified name
  def self.move_upload_to_repository(tmpfile,filename)
    File.makedirs VIDEO_REPOSITORY if ! File.exists?(VIDEO_REPOSITORY)
    fname = self.sanitize_filename(filename)
    if File.exists? "#{VIDEO_REPOSITORY}/#{fname}"
      dup=2
      if fname.index('.')
        ext=fname.split('.').last
        base=fname[0..(0-(ext.size+2))]
      else
        base=fname
        ext='unk'
      end
      while (File.exists? "#{VIDEO_REPOSITORY}/#{base}(#{dup}).#{ext}")
        dup+=1
      end
      fname = "#{base}(#{dup}).#{ext}"
    end
    full_path = "#{VIDEO_REPOSITORY}/#{fname}"
    if File.mv(tmpfile.path,full_path)
      full_path
    else
      nil
    end
  end

  def self.sanitize_filename(filename)
    name = filename.strip
    # Filename only no path
    name.gsub! /^.*(\\|\/)/, ''
    # replace all non alphanumeric, underscore or periods with underscore
    name.gsub! /[^\w\.\-]/, '_'
    
    # Remove multiple underscores
    name.gsub!(/\_+/, '_')

    name
  end

  def team_name= team_name
    self.team_id = team_by_name(team_name).id
  end

  def team_name
    team ? team.name : nil
  end

  def home_team_name= team_name
    self.home_team = team_by_name team_name
  end

  def home_team_name
    home_team ? home_team.name : nil
  end
  
  def visiting_team_name= team_name
    self.visiting_team = team_by_name team_name
  end

  def visiting_team_name
    visiting_team ? visiting_team.name : nil
  end

  private
  
  def team_by_name team_name
    team = Team.find_by_name team_name
    if team.nil?
      team = Team.create :name => team_name
    end
    team
  end
  
end
