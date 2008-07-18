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
  def self.legal_file_extensions
    ["*.3g2","*.3gp","*.3gp2","*.3gpp","*.asf","*.avi","*.avs","*.dv","*.flc","*.fli","*.flv","*.gvi","*.m1v","*.m2v","*.m4e","*.m4u","*.m4v","*.mjp","*.mkv","*.moov","*.mov","*.movie","*.mp4","*.mpe","*.mpeg","*.mpg","*.mpv2","*.qt","*.rm","*.ts","*.vfw","*.vob","*.wm","*.wmv"]
  end

  # Our HTTP Client to communicate with Vidavee service
  CLIENT = HTTPClient.new
  CLIENT.connect_timeout = 60
  CLIENT.receive_timeout = 300
  CLIENT.send_timeout = 0
  
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
    if response && response.content
      logger.debug "Logging into the Vidavee backend"
      extract(response.content,'//newToken').text;
    else
      nil
    end
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
  def thumbnail_bytes(sessionid,dockey)
    response = vrequest('file/GetFileThumbnail',sessionid,DOCKEY_PARAM => dockey)
    response.content
  end

  # Returns the thumbnail jpeg bytes for the dockey, low res version
  def thumbnail_low_bytes(sessionid,dockey)
    response = vrequest('file/GetFileThumbnailLow',sessionid,DOCKEY_PARAM => dockey)
    response.content
  end
  
  # Returns the thumbnail jpeg bytes for the dockey, medium res version
  def thumbnail_bytes(sessionid,dockey)
    response = vrequest('file/GetFileThumbnailMedium',sessionid,DOCKEY_PARAM => dockey)
    response.content
  end

  # Returns the thumbnail url for the dockey
  def file_thumbnail_low(dockey)
    s = url_for('file/GetFileThumbnailLow')
    "#{s}?#{DOCKEY_PARAM}=#{dockey}"
  end
    
  # Returns the thumbnail url for the dockey
  def file_thumbnail_medium(dockey)
    s = url_for('file/GetFileThumbnailMedium')
    "#{s}?#{DOCKEY_PARAM}=#{dockey}"
  end
    
  # Returns the thumbnail url for the dockey
  def file_thumbnail(dockey)
    s = url_for('file/GetFileThumbnail')
    "#{s}?#{DOCKEY_PARAM}=#{dockey}"
  end
  

  # Returns a url suitable for getting the transcoded content (flv)
  def file_flv(sessionid,dockey)
    url = url_for('file/GetFile',sessionid)
    params = build_request_params('file/GetFile',sessionid,{"field" => "AssetTranscoded", DOCKEY_PARAM => dockey },false)
    url = query_url(url,params)
    return url + "&ftype=.flv"
  end

  def file_flv_as_flash_param(sessionid,dockey)
    url = file_flv(sessionid,dockey)
    url = CGI::escape(url)
    puts "Flash URL : #{url}"
    url
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
  def gallery_assets(sessionid, asset_type='videoAsset', extra_params = {})
    url = url_for('gallery/GetGalleryAssets',sessionid)
    params = build_request_params('gallery/GetGalleryAssets',sessionid,extra_params,false)
    url = query_url(url,params)
    assets = nil
    # Send the post
    form_params = { 'assetType' => asset_type, 'dateRange' => 'All' }
    begin
      response = CLIENT.post(url, form_params)
      assets = extract(response.content,'//asset')
    rescue TimeoutError
      logger.error "Could not contact Vidavee backend"
    end
    logger.debug "Asking for #{asset_type} with #{url} got #{assets.size}"
    assets
  end

  # Get all the vtag records for a video_asset
  # Uses rowsPerPage and AF_page to control paging
  def vtags_for_asset(sessionid,dockey,extra_params = {})
    extra_params[DOCKEY_PARAM] = dockey
    response = vrequest('gallery/GetGalleryVtagsByAsset',sessionid,extra_params,false)
    extract(response.content,'//vtag')
  end


  # Load gallery assets from vidavee xml into our video_assets models
  # Use rowsPerPage to change the default of 15, set to 0 for all
  # AssetType can be videoAsset, imageAsset, audioAsset, vtag, vidad
  # Returns [count_found, count_loaded]
  def load_gallery_assets(sessionid, asset_type='videoAsset', extra_params = {})
    assets = gallery_assets(sessionid,asset_type,extra_params)
    if assets.nil?
      return [0,0]
    end
    admin = User.find_by_email(ADMIN_EMAIL)
    save_count = 0
    assets.each do |a|
      v = VideoAsset.new
      update_asset_record_from_xml(v,a)
      next if v.dockey.nil?
      if admin
        v.user_id = admin.id
      end
      existing = VideoAsset.find_by_dockey(v.dockey)
      if existing
        puts "Video asset for dockey already exists #{v.dockey}"
      else
        if v.save!
          save_count+=1
          logger.debug "Saved video #{v.dockey} - #{v.video_type} as id #{v.id}"
        else
          logger.warn "Failed to save #{v.dockey}"
        end
      end
    end
    [assets.size, save_count]
  end

  def update_asset_record(sessionid,video_asset)
    response = vrequest('assets/GetDetailsAssetContent',sessionid, { DOCKEY_PARAM => video_asset.dockey })
    if response && response.content
      body = extract(response.content,"//content")
      if body
        update_asset_record_from_xml(video_asset,body)
      else
        logger.debug "Bad response #{response.content}"
      end
    else
      logger.debug "No content in response #{response}"
    end
    video_asset
  end
    

  # Load the vtags for the specified dockey into
  # our database by querying the vidavee backend
  # Returns [found, saved]
  def load_vtags(sessionid,video_asset)
    vtags = vtags_for_asset(sessionid,video_asset.dockey)
    return [0,0] if vtags.nil?
    save_count = 0
    vtags.each do |v|
      vt = VideoClip.new
      vt.dockey= v.search('//dockey').text
      vt.title= v.search('//title').text
      vt.length= v.search('//length').text
      vt.description= v.search('//description').text
      vt.view_url= v.search('//videoViewUrl').text
      vt.video_asset_id = video_asset.id
      vt.user_id = video_asset.user_id
      existing = VideoClip.find_by_dockey(vt.dockey)
      if existing
        logger.debug "VideoClip #{vt.dockey} already saved"
      else
        if vt.save!
          logger.debug "Saved vtag #{vt.dockey} for asset #{video_asset.dockey}"
          save_count += 1
        else
          logger.warn "Failed to save vtag #{vt.dockey}"
        end
      end
    end
    [vtags.size,save_count]
  end

  def new_vtag(sessionid, dockey, startTime, endTime, title, snapshotOffset, extra_params = {})
    my_params = {'asset' => dockey, 'startTime' => startTime, 'endTime' => endTime, 'snapshotOffset' => snapshotOffset}
    extra_params.each { |p| my_params[p[0]] = p[1] }
    response = vrequest('assets/NewVTag',sessionid,my_params)
  end

  # a <script> tag to use for the embed
  def asset_embed_code(sessionid, dockey, width=400, height=350, autoplay="off", vtag="off")
    response = vrequest('assets/GetDetailsAssetEmbedCode',sessionid,
                        DOCKEY_PARAM => dockey,
                        'width'=>width,'height'=>height,
                        'shareWidgets'=>'off',
                        'autoplay'=>autoplay, 'vtagView'=>vtag)
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
      response = "Timeout"
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

  #### Class methods

  # Load videos from the back end, up to limit
  def self.load_backend_video (limit = -1)
    v = Vidavee.find(:first)
    token = v.login
    save_count = 0
    find_count = 0
    fc = -1
    page = 1
    rowsPerPage = 50
    while fc != 0
      if limit > 0 && rowsPerPage > (limit-find_count)
        rowsPerPage = limit-find_count
      end
      fc,sc =
        v.load_gallery_assets(token,'videoAsset','rowsPerPage' => rowsPerPage,'AF_page' => page)
      save_count += sc
      find_count += fc
      page += 1
      break if limit > 0 && find_count >= limit
    end
    puts "Pulled #{find_count} and saved #{save_count} video assets from Vidavee"
  end
  
  # Load clips up from the vidavee backend
  # that correspond to the video_assets passed in
  # or all video_assets
  def self.load_backend_clips(video_assets = VideoAssets.find(:all))
    v = Vidavee.find(:first)
    token = v.login
    total_found, total_saved = 0,0
    video_assets.each do |video_asset|
      found,saved = v.load_vtags token,video_asset
      puts "Found #{found} clips for video #{video_asset.dockey}, saved #{saved}"
      total_found += found
      total_saved += saved
    end
    [total_found, total_saved]
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
  def vrequest(action,sessionid='',extra_params={},login=true)
    url = url_for(action,sessionid)
    params = build_request_params(action,sessionid,extra_params,login)
    begin
      response = CLIENT.post(query_url(url,params))
    rescue TimeoutError
      logger.error "Could not contact Vidavee backend"
      nil
    end
  end

  # Build and sign the request params
  def build_request_params(action,sessionid='',extra_params={}, include_login=true)
    # get a timestamp in vidavee format for use in the http api
    ts = Time.now.to_i.to_s + "000"
    params = {KEY_PARAM => key,
      TS_PARAM => ts,
      SIG_PARAM => sign(action,ts),
    }
    if include_login
      params[USER_PARAM] = username
      params[PASS_PARAM] = password
    end
    if extra_params && extra_params.class == Hash
      extra_params.each { |p| params[p[0]] = p[1] }
    end
    params
  end
  
  # Create base url for vidavee rest service 
  def url_for(service,sessionid='')
    url = "http://#{uri}/#{context}/#{servlet}/#{service}"
    if sessionid.length > 0
      url = "#{url}#{SESSION_PARAM}#{sessionid}"
    end
    url
  end

  def update_asset_record_from_xml(video_asset,asset_xml)
    dockey = asset_xml.search('//dockey')
    if dockey.nil?
      logger.debug "No valid response in #{asset_xml}"
      return
    end
    video_asset.dockey= dockey.text
    video_asset.video_type= asset_xml.search('//type').text
    title= asset_xml.search('//title').text
    if ((title.nil? || title.length == 0) && video_asset.title.nil?)
      video_asset.title = 'no title supplied'
    end
    video_asset.description= asset_xml.search('//description').text
    video_asset.author_name= asset_xml.search('//authorName').text
    video_asset.author_email= asset_xml.search('//authorEmail').text
    video_asset.video_length= asset_xml.search('//length').text
    video_asset.frame_rate= asset_xml.search('//frameRate').text
    video_asset.video_status= asset_xml.search('//status').text
    video_asset.can_edit= asset_xml.search('//canEdit').text
    video_asset.thumbnail= asset_xml.search('//thumbnail').text
    video_asset.thumbnail_low= asset_xml.search('//thumbnailLow').text
    video_asset.thumbnail_medium= asset_xml.search('//thumbnailMedium').text
  end
  
end
