class Vidavee < ActiveRecord::Base

  # These are parameter (form element) names for vidavee 
  # GET and POST messages
  TS_PARAM = 'api_ts'
  SIG_PARAM = 'api_sig'
  KEY_PARAM = 'api_key'
  TOKEN_PARAM = 'api_token'
  USER_PARAM = 'userName'
  PASS_PARAM = 'password'
  SESSION_PARAM = ';jsessionid='
  DOCKEY_PARAM = 'dockey'
  PAGE_PARAM = 'AF_page'
  UPLOAD_ID_PARAM = 'AF_uploadId'
  
  # These are for upload control
  LEGAL_FILE_EXTENSIONS = [".3g2",".3gp",".3gp2",".3gpp",".asf",".avi",".avs",".dv",".flc",".fli",".flv",".gvi",".m1v",".m2v",".m4e",".m4u",".m4v",".mjp",".mkv",".moov",".mov",".movie",".mp4",".mpe",".mpeg",".mpg",".mpv2",".qt",".rm",".ts",".vfw",".vob",".wm",".wmv"]
		

  # Our HTTP Client to communicate with Vidavee service
  CLIENT = HTTPClient.new

  # Turn this on for debug of HTTP traffic to Vidavee
  # CLIENT.debug_dev = STDERR

  # http://tribeca.vidavee.com/hsstv/rest/session/CheckUser;jsessionid=39555E57BCF38625CF7DEA2EDD9038F7.node1?api_key=5342smallworld&api_ts=1214532647018&api_token=39555E57BCF38625CF7DEA2EDD9038F7.node1&api_sig=830678DF3E967D0392F936122F767754&session_id=
  # Seems to always return false, not sure what good it is
  def check_user(sessionid)
    response = vrequest('session/CheckUser',sessionid)
    extract(response.content, '//isUserLoggedIn').text
  end

  # http://tribeca.vidavee.com/hsstv/rest/session/Login?api_key=5342smallworld&api_ts=1214531598256&api_sig=EFF68F8B9CBC146FCEE39EA3D4AFED79&userName=hsstv&password=hsstvUser
  def login
    response = vrequest('session/Login')
    puts "Logging into the Vidavee backend"
    extract(response.content,'//newToken').text;
  end

  # Logout of the session
  def logout(sessionid)
    response = vrequest('session/Logout')
    response.status == 200
  end

  def customer_groups(sessionid)
    response = vrequest('customers/GetCustomerGroups',sessionid)
    extract(response.content,'//group')
  end

  def delete_content(sessionid,dockey)
    response = vrequest('assets/DeleteAsset',sessionid,DOCKEY_PARAM => dockey)
    'ok' == extract(response.content,'/response')['status']
  end

  # Returns the thumbnail jpeg bytes for the dockey
  def file_thumbnail(sessionid,dockey)
    response = vrequest('file/GetFileThumbnail',sessionid,DOCKEY_PARAM => dockey)
    response.content
  end
  
  # Returns the thumbnail jpeg bytes for the dockey, low res version
  def file_thumbnail_low(sessionid,dockey)
    response = vrequest('file/GetFileThumbnailLow',sessionid,DOCKEY_PARAM => dockey)
    response.content
  end
  
  # Returns the thumbnail jpeg bytes for the dockey, medium res version
  def file_thumbnail_medium(sessionid,dockey)
    response = vrequest('file/GetFileThumbnailMedium',sessionid,DOCKEY_PARAM => dockey)
    response.content
  end

  # Returns the artifact data for the dockey
  def file_artifact(sessiond,dockey)
    response = vrequest('file/GetFileArtifact',sessionid,DOCKEY_PARAM => dockey)
    response.content
  end
  
  # Returns the asset data for the dockey
  def file_asset(sessiond,dockey)
    response = vrequest('file/GetFileAsset',sessionid,DOCKEY_PARAM => dockey)
    response.content
  end

  # Returns the flv data for the dockey
  def file_flv(sessiond,dockey)
    response = vrequest('file/GetFileFlv',sessionid,DOCKEY_PARAM => dockey)
    response.content
  end
  
  # Returns the mpg data for the dockey
  def file_mpg(sessiond,dockey)
    response = vrequest('file/GetFileMpg',sessionid,DOCKEY_PARAM => dockey)
    response.content
  end

  # Result is paginated, see currentPage, totalPages
  # also takes optional date range, creator, set, and search keyword
  # Use param AF_page to see other than the first page
  def gallery_playlists(sessionid, extra_params = {})
    response = vrequest('playlist/GetGalleryPlaylists',sessionid,extra_params)
    extract(response.content,'//asset')
  end

  # List items in gallery, result is paginated, see currentPage, totalPages
  # Use rowsPerPage to change the default of 15, set to 0 for all
  # AF_page to specify a subsequent page
  def gallery_assets(sessionid, extra_params = {})
    response = vrequest('gallery/GetGalleryAssets',sessionid, extra_params)
    extract(response.content,'//asset')
  end

  # Load gallery assets from vidavee xml into our video_assets models
  # Use rowsPerPage to change the default of 15, set to 0 for all
  def load_gallery_assets(sessionid, extra_params = {})
    response = vrequest('gallery/GetGalleryAssets',sessionid, extra_params)
    assets = extract(response.content,'//asset')
    admin = User.find_by_email('admin@globalsports.net')
    save_count = 0
    assets.each do |a|
      v = VideoAsset.new
      v.dockey= a.search('//dockey').text
      v.title= a.search('//title').text
      v.description= a.search('//description').text
      v.author_name= a.search('//authorName').text
      v.author_email= a.search('//authorEmail').text
      v.video_length= a.search('//length').text
      v.frame_rate= a.search('//frameRate').text
      v.video_type= a.search('//type').text
      v.video_status= a.search('//status').text
      v.can_edit= a.search('//canEdit').text
      v.thumbnail= a.search('//thumbnail').text
      v.thumbnail_low= a.search('//thumbnailLow').text
      v.thumbnail_medium= a.search('//thumbnailMedium').text
      if admin
        v.user_id = admin.id
      end
      existing = VideoAsset.find_by_dockey(v.dockey)
      if existing
        puts "Video aset for dockey already exists #{v.dockey}"
      else
        if v.save!
          save_count+=1
          puts "Saved video #{v.dockey} - #{v.video_type} as id #{v.id}"
        else
          puts "Failed to save #{v.dockey}"
        end
      end
    end
    save_count
  end

  def new_vtag(sessionid, dockey, startTime, endTime, title, snapshotOffset, extra_params = {})
    my_params = {'asset' => dockey, 'startTime' => startTime, 'endTime' => endTime, 'snapshotOffset' => snapshotOffset}
    extra_params.each { |p| my_params[p[0]] = p[1] }
    response = vrequest('assets/NewVTag',sessionid,my_params)
  end

  # a <script> tag to use for the embed
  def asset_embed_code(sessionid, dockey, width=400, height=350, autoplay="off")
    response = vrequest('assets/GetDetailsAssetEmbedCode',sessionid,DOCKEY_PARAM => dockey, 'width'=>width,'height'=>height, 'autoplay'=>autoplay)
    extract(response.content,'//assetEmbedCode').text
  end

  # This moves the entire asset to the trash, it should be deleted from there
  def delete_asset(sessionid, dockey)
    response = vrequest('assets/DeleteAsset',sessionid,DOCKEY_PARAM => dockey)
    extract(response.content,'//status')
  end

  # looking for 'ready', 'queued', 'blocked'
  def asset_status(sessionid, dockey)
    response = vrequest('assets/GetDetailsAssetStatus',sessionid,DOCKEY_PARAM => dockey)
    el = extract(response.content,'//status')
    el.text if el 
  end

  # zero or more asset tags
  def asset_tags(sessionid,dockey)
    response = vrequest('assets/GetDetailsAssetTags',sessionid,DOCKEY_PARAM => dockey)
    extract(response.content,'//tags')
  end

  # Gets info for the media in dockey, such as
  # lengthInSeconds, fps, bitrate, hasVideo, hasAudio,
  # width, height, pixelFormat, videoBitrate, sampleRate
  # audioChannels, audioBitrate, ...
  def media_info(sessionid, dockey)
    response = vrequest('assets/GetMediaInfo',sessionid,DOCKEY_PARAM => dockey)
    extract(response.content,'//mediaInfo')
  end

  # Owner is from what is listed in getCustomerGroups (I think)
  def sets(sessionid, owner)
    response = vrequest('users/GetSets',sessionid,'setOwner' => owner)
    extract(response.content,'//set')
  end

  # Get the action where the upload form will
  # post to send a new video asset file to vidavee
  # not calling the action here, just helping to display the form
  # Returns [action, uploadid] for tracking progress
  def old_upload_action(sessionid)
    url = url_for('html/NewAsset',sessionid)
    uploadid = "#{Time.now.to_i.to_s}|#{sessionid}"
    params = build_request_params('html/NewAsset',sessionid,
                                  {UPLOAD_ID_PARAM => uploadid })
    url = query_url(url,params)
    [url,uploadid]
  end

  # Called from the activemessaging processor once we get the video
  # uploaded to our server, the info will be saved to the 
  # video_assets table, waiting to be pushed over to vidavee
  # and obtain a dockey to associate with the video_asset
  # video_asset dockey and video_status are updated and saved on success
  def push_video(sessionid, video_asset, file_path)

    # Build the url, yeah, with parameters on it
    url = url_for('assets/NewAssetVideo',sessionid)
    params = build_request_params('assets/NewAssetVideo',sessionid)
    url = query_url(url,params)
    
    # Convince HttpClient to post multipart data by sending a boundary
    boundary = Array::new(8){ "%2.2d" % rand(99) }.join('__')
    extheader = {'content-type' => "multipart/form-data; boundary=--------#{ boundary }__xyzzy"}

    # Name and open the files
    upload_params = {'Asset' => open(file_path)}

    # Send in any extra parameters the upload form requires
    upload_params['title'] = video_asset.title
    upload_params['description'] = video_asset.description
    upload_params['transcoderVersion'] = 3
    upload_params['type'] = 'video'
    asis=file_path.downcase.end_with? '.flv'
    upload_params['asisFlv'] = asis

    # Send the post
    begin
      response = CLIENT.post(url, upload_params, extheader)
    rescue TimeoutError
      logger.error "Could not contact Vidavee backend"
      response = nil
    end
    dockey_elem = extract(response.content,'//dockey')

    # update attributes in the asset
    if dockey_elem
      video_asset.dockey= dockey_elem.text
      video_asset.video_status= asis ? 'ready' : 'queued'
      video_asset.save!
      dockey_elem.text
    else
      video_asset.video_status= 'upload failed'
      video_asset.save!
      logger.debug "Video push failed: #{response.content}"
      nil
    end
  end

  #### Internal methods follow here
  protected

  # Build a query url from the base url given plus the query parameters
  def query_url(url, params)
    url +"?" + params.inject([]) { |s,(k,v)| s << "#{k}=#{v}" }.join("&")
  end

  # extract some element from the response document
  def extract(doc,fragment)
    h = Hpricot.XML(doc)
    status = h.search('/response').attr('status')
    if (status == 'ok')
      token = h.search(fragment)
    else
      token = nil
    end
    token
  end

  # Compute the MD5 sum on the required params for the security token
  def sign(service,ts,sessionid='')
    digest = Digest::MD5.new
    str = "/" + service + "/" + secret + KEY_PARAM + key +
      (sessionid.length > 0 ? (TOKEN_PARAM + sessionid) : "") +
      TS_PARAM + ts
    digest.update str
    digest.hexdigest.upcase
  end

  # Post a standard request, get a standard (usually xml) answer
  def vrequest(action,sessionid='',extra_params={})
    url = url_for(action,sessionid)
    params = build_request_params(action,sessionid,extra_params)
    begin
      response = CLIENT.post(query_url(url,params))
    rescue TimeoutError
      logger.error "Could not contact Vidavee backend"
      nil
    end
  end

  # Build and sign the request params
  def build_request_params(action,sessionid='',extra_params={})
    # get a timestamp in vidavee format for use in the http api
    ts = Time.now.to_i.to_s + "000"
    params = {KEY_PARAM => key,
      TS_PARAM => ts,
      SIG_PARAM => sign(action,ts),
      USER_PARAM => username,
      PASS_PARAM => password}
    if extra_params && extra_params.class == Hash
      extra_params.each { |p| params[p[0]] = p[1] }
    end
    params
  end
  
  # Create base url for vidavee rest service 
  def url_for(service,sessionid='')
    url = "http://" + uri +
      "/" + context +
      "/" + servlet +
      "/" + service
    if sessionid.length > 0
      url = url + SESSION_PARAM  + sessionid
    end
    url
  end

  
end
