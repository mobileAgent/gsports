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

  # http://tribeca.vidavee.com/hsstv/rest/session/CheckUser;jsessionid=39555E57BCF38625CF7DEA2EDD9038F7.node1?api_key=5342smallworld&api_ts=1214532647018&api_token=39555E57BCF38625CF7DEA2EDD9038F7.node1&api_sig=830678DF3E967D0392F936122F767754&session_id=
  # Seems to always return false, not sure what good it is
  def check_user(sessionid)
    response = vrequest('session/CheckUser',sessionid)
    if response
      extract(response, '//isUserLoggedIn').text
    else
      nil
    end
  end

  # http://tribeca.vidavee.com/hsstv/rest/session/Login?api_key=5342smallworld&api_ts=1214531598256&api_sig=EFF68F8B9CBC146FCEE39EA3D4AFED79&userName=hsstv&password=hsstvUser
  def login
    response = vrequest('session/Login')
    if response
      logger.debug "Logging into the Vidavee backend"
      extract(response,'//newToken').text;
    else
      nil
    end
  end

  # Logout of the session
  def logout(sessionid)
    response = vrequest('session/Logout')
    #response.status == 200
  end

  def customer_groups(sessionid)
    response = vrequest('customers/GetCustomerGroups',sessionid)
    if response
      extract(response,'//group')
    end
  end

  def delete_content(sessionid,dockey)
    response = vrequest('assets/DeleteAsset',sessionid,DOCKEY_PARAM => dockey)
    'ok' == extract(response,'/response')['status']
  end

  # Returns the thumbnail jpeg bytes for the dockey
  def thumbnail_bytes(sessionid,dockey)
    vrequest('file/GetFileThumbnail',sessionid,DOCKEY_PARAM => dockey)
  end

  # Returns the thumbnail jpeg bytes for the dockey, low res version
  def thumbnail_low_bytes(sessionid,dockey)
    vrequest('file/GetFileThumbnailLow',sessionid,DOCKEY_PARAM => dockey)
  end
  
  # Returns the thumbnail jpeg bytes for the dockey, medium res version
  def thumbnail_bytes(sessionid,dockey)
    vrequest('file/GetFileThumbnailMedium',sessionid,DOCKEY_PARAM => dockey)
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

  # This call is a little different from all the others so far in that it isn't
  # part of the restful api (no /rest/ after the context part so we can't use
  # the url_for -> vrequest methods as they are right now). It isn't signed
  # or secure (the sessionid is ignored). But this is the Vidavee recommended
  # method of obtaining the flv access for our player. Works for both videos and clips
  # What comes back in the xml document is a <url type="stream"> element (usually
  # more than one) that have the following format in a cdata:
  #  stream.tribeca.vidavee.com:80/vidad/tribeca.vidavee.com/hsstv/hsstv/4B5E0218C9C29D59862F2E880935BC48.flv
  # (Note there is no http in front -- weird.)
  def file_flv(sessionid,dockey)
    url = "http://#{uri}/#{context}/vClientXML.view?AF_renderParam_contentType=text/xml&#{DOCKEY_PARAM}=#{dockey}"
    response = Curl::Easy.http_post(url)
    video_url = extract_no_status(response.body_str,"//url[@type='stream']/").first
    if video_url.nil?
      logger.debug "Found no valid url objects in response"
      return nil
    end
    "http://#{video_url.inner_text}"
  end

  # Grok the flv url without making a call for the xml document, a faster
  # alternative to file_flv as long as nothing changes on the back end
  #  stream.tribeca.vidavee.com:80/vidad/tribeca.vidavee.com/hsstv/hsstv/4B5E0218C9C29D59862F2E880935BC48.flv
  def file_flv_const(session_id,dockey)
    "http://stream.#{uri}:80/vidad/#{uri}/#{context}/#{context}/#{dockey}.flv"
  end
  
  # Result is paginated, see currentPage, totalPages
  # also takes optional date range, creator, set, and search keyword
  # Use param AF_page to see other than the first page
  def gallery_playlists(sessionid, extra_params = {})
    response = vrequest('playlist/GetGalleryPlaylists',sessionid,extra_params)
    extract(response,'//asset')
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
      response = curl_post(url,form_params)
      assets = extract(response,'//asset')
    rescue TimeoutError
      logger.error "Could not contact Vidavee backend: #{$!}"
    end
    logger.debug "Asking for #{asset_type} with #{url} got #{assets.size}"
    assets
  end

  def curl_post(url,form_params={})
    curl_params=form_params.inject([]) {|s,(k,v)| s << Curl::PostField.content(k,v)}
    r = Curl::Easy.http_post(url,*curl_params)
    if r.response_code == 200
      return r.body_str
    else
      "There was an error #{r.response_code} from #{url}"
    end
  end

  # Get all the vtag records for a video_asset
  # Uses rowsPerPage and AF_page to control paging
  def vtags_for_asset(sessionid,dockey,extra_params = {})
    extra_params[DOCKEY_PARAM] = dockey
    response = vrequest('gallery/GetGalleryVtagsByAsset',sessionid,extra_params,false)
    if (response)
      extract(response,'//vtag')
    else
      nil
    end
  end

  # Get details for a reel (vidavee calls this a playlist)
  def reel_details(sessionid, dockey)
    url = "http://#{uri}/#{context}/pClientXML.view?AF_renderParam_contentType=text/xml&#{DOCKEY_PARAM}=#{dockey}"
    response = curl_post url
    response.gsub!('&dockey=','&amp;dockey=') if response
    h = Hpricot.XML(response)
    vpel = '/VVPlaylist'
    title = h.search(vpel).attr('title')
    title.gsub!(/:uid=\d+/,'') # cruft from the pilot site
    desc = h.search(vpel).attr('description')
    length = h.search(vpel).attr('length')
    part_count = h.search('//item').size
    if (part_count > 0)
      first_item = h.search('//item')
      thumbnail_dockey=first_item.attr('id') if first_item
    end
    { :title => title, :description => desc, :video_length => length, :thumbnail_dockey => thumbnail_dockey, :dockey => dockey }
  end

  # Load gallery assets from vidavee xml into our video_assets models
  # Use rowsPerPage to change the default of 15, set to 0 for all
  # AssetType can be videoAsset, imageAsset, audioAsset, vtag, vidad
  # Returns [count_found, count_loaded]
  def load_gallery_assets(sessionid, asset_type='videoAsset', extra_params = {})
    assets = gallery_assets(sessionid,asset_type,extra_params)
    return [0,0] if assets.nil?
    admin = User.admin.first
    save_count = 0
    assets.each do |a|
      v = VideoAsset.new
      update_asset_record_from_xml(v,a)
      next if v.dockey.nil?
      if admin
        v.user_id = admin.id
      end
      existing = VideoAsset.find_by_dockey(v.dockey) || DeletedVideo.find_by_dockey(v.dockey)
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
  
  # Load gallery playlists from vidavee xml into our video_reels models
  # Use rowsPerPage to change the default of 15, set to 0 for all
  # It's a two step process, We get the playlist dockey in a paged list
  # then we have to look up the details on that in a separate call
  # Returns [count_found, count_loaded]
  def load_gallery_playlists(sessionid, user_id, extra_params = {})
    assets = gallery_playlists(sessionid,extra_params)
    return [0,0] if assets.nil?
    save_count,found_count = 0,0
    assets.each do |a|
      playlist_dockey = a.search('//dockey')
      next if playlist_dockey.nil?
      playlist_dockey=playlist_dockey.text
      found_count+=1
      next if(VideoReel.find_by_dockey(playlist_dockey)  || DeletedVideo.find_by_dockey(playlist_dockey))
      v = VideoReel.new(reel_details(sessionid,playlist_dockey))
      if v.title.nil? || v.title.size == 0
        v.title = 'no title supplied'
      end
      v.user_id = user_id
      if v.save!
        save_count+=1
      end
    end
    [found_count,save_count]
  end
  
  def update_asset_record(sessionid,video_asset,only={})
    response = vrequest('assets/GetDetailsAssetContent',sessionid, { DOCKEY_PARAM => video_asset.dockey })
    if response
      body = extract(response,"//content")
      if body
        update_asset_record_from_xml(video_asset,body,only)
      else
        logger.debug "Bad response #{response}"
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
      vt.video_length= v.search('//length').text
      vt.description= v.search('//description').text
      vt.video_asset_id = video_asset.id
      vt.user_id = video_asset.user_id
      existing = VideoClip.find_by_dockey(vt.dockey) || DeletedVideo.find_by_dockey(vt.dockey)
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
    extract(response,'//assetEmbedCode').text
  end

  # This moves the entire asset to the trash, it should be deleted from there
  def delete_asset(sessionid, dockey)
    response = vrequest('assets/DeleteAsset',sessionid,DOCKEY_PARAM => dockey)
    extract(response,'//status')
  end

  # looking for 'ready', 'queued', 'blocked'
  def asset_status(sessionid, dockey)
    response = vrequest('assets/GetDetailsAssetStatus',sessionid,DOCKEY_PARAM => dockey)
    el = extract(response,'//status')
    el.text if el 
  end

  # zero or more asset tags
  def asset_tags(sessionid,dockey)
    response = vrequest('assets/GetDetailsAssetTags',sessionid,DOCKEY_PARAM => dockey)
    extract(response,'//tags')
  end

  # Gets info for the media in dockey, such as
  # lengthInSeconds, fps, bitrate, hasVideo, hasAudio,
  # width, height, pixelFormat, videoBitrate, sampleRate
  # audioChannels, audioBitrate, ...
  def media_info(sessionid, dockey)
    response = vrequest('assets/GetMediaInfo',sessionid,DOCKEY_PARAM => dockey)
    extract(response,'//mediaInfo')
  end

  # Owner is from what is listed in getCustomerGroups (I think)
  def sets(sessionid, owner)
    response = vrequest('users/GetSets',sessionid,'setOwner' => owner)
    extract(response,'//set')
  end

  # Called from the activemessaging processor once we get the video
  # uploaded to our server, the info will be saved to the 
  # video_assets table, waiting to be pushed over to vidavee
  # and obtain a dockey to associate with the video_asset
  # video_asset dockey and video_status are updated and saved on success
  def push_video(sessionid, video_asset, file_path)

    # Build the url, yeah, with parameter on it
    url = url_for('assets/NewAssetVideo',sessionid)
    params = build_request_params('assets/NewAssetVideo',sessionid)
    url = query_url(url,params)
    
    # Send in any extra parameters the upload form requires
    #asis=file_path.downcase.end_with? '.flv'
    upload_params = [
                     Curl::PostField.content('title',video_asset.title),
                     Curl::PostField.content('description',video_asset.description),
                     Curl::PostField.content('transcoderVersion','3'),
                     Curl::PostField.content('type','video'),
                     Curl::PostField.content('asisFlv','false'),
                     Curl::PostField.file('Asset',file_path)
                     ]
    # Send the post
    begin
      response = do_upload(url,*upload_params)
    rescue 
      logger.error "Could not contact Vidavee backend: #{$!}"
      response = "Error"
    end
    dockey_elem = extract(response,'//dockey')

    # update attributes in the asset
    if dockey_elem
      video_asset.dockey= dockey_elem.text
      video_asset.video_status= asis ? 'ready' : 'queued'
      video_asset.save!
      dockey_elem.text
    else
      video_asset.video_status= 'upload failed'
      video_asset.save!
      logger.debug "Video push failed: #{response}"
      nil
    end
  end

  def do_upload(url,*args)
    c = Curl::Easy.new(url)
    c.multipart_form_post= true
    c.connect_timeout= 60
    c.timeout= 0
    logger.debug "Ready to upload to #{url} with #{args.length} args"
    c.http_post(*args)
    logger.debug "Done with upload, response #{c.response_code}"
    c.body_str
  end

  #### Class methods

  # Load videos from the back end, up to limit
  def self.load_backend_video (limit = -1)
    v = Vidavee.first
    token = v.login
    save_count,find_count = 0,0
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
  def self.load_backend_clips(video_assets = VideoAsset.all)
    v = Vidavee.first
    token = v.login
    total_found, total_saved = 0,0
    video_assets.each do |video_asset|
      found,saved = v.load_vtags token,video_asset
      puts "Found #{found} clips for video #{video_asset.dockey}, saved #{saved}"
      total_found += found
      total_saved += saved
    end
    puts "Found #{total_found} clips, saved #{total_saved}"
    [total_found, total_saved]
  end
  
  # Load reels up from the vidavee backend
  def self.load_backend_reels(limit=-1,user_id=User.admin.first.id)
    v = Vidavee.first
    token = v.login
    total_found, total_saved = 0,0
    fc = -1
    page = 1
    rowsPerPage = 50
    while fc != 0
      if limit > 0 && rowsPerPage > (limit-find_count)
        rowsPerPage = limit-find_count
      end
      fc,sc =
        v.load_gallery_playlists(token,user_id,'rowsPerPage' => rowsPerPage,'AF_page' => page)
      total_saved += sc
      total_found += fc
      page += 1
      break if limit > 0 && find_count >= limit
    end
    puts "Pulled #{total_found} and saved #{total_saved} reels from Vidavee"
    [total_found, total_saved]
  end

  #### Internal methods follow here
  protected

  # Build a query url from the base url given plus the query parameters
  def query_url(url, params)
    sep = "?"
    params.each do |pf|
      url = "#{url}#{sep}#{pf.name}=#{pf.content}"
      sep = "&"
    end
    url
  end

  # extract some element from the response document
  def extract(doc,fragment)
    begin
      h = Hpricot.XML(doc)
      status = h.search('/response').attr('status')
      if (status == 'ok')
        token = h.search(fragment)
      else
        token = nil
      end
    rescue
      token = nil
    end
    token
  end

  def extract_no_status(doc,fragment)
    h = Hpricot.XML(doc)
    token = h.search(fragment)
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
      full_url = query_url(url,params)
      response = Curl::Easy.http_post(full_url)
      if (response.response_code == 200)
        return response.body_str
      else
        logger.error "Vidavee response code #{response.response_code} on #{full_url} => #{response.body_str}"
        return nil
      end
    rescue 
      logger.error "Could not contact Vidavee backend for #{url}: #{$!}"
      nil
    end
  end

  # Build and sign the request params
  def build_request_params(action,sessionid='',extra_params={}, include_login=true)
    # get a timestamp in vidavee format for use in the http api
    ts = "%.0f" % (Time.now.to_f * 1000)
    params = []
    params << Curl::PostField.content(KEY_PARAM,key)
    params << Curl::PostField.content(TS_PARAM,ts)
    params << Curl::PostField.content(SIG_PARAM,sign(action,ts))
    if include_login
      params << Curl::PostField.content(USER_PARAM,username)
      params << Curl::PostField.content(PASS_PARAM,password)
    end
    if extra_params && extra_params.class == Hash
      extra_params.each do |k,v|
        params << Curl::PostField.content(k,"#{v}")
      end
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

  def update_asset_record_from_xml(video_asset,asset_xml,only={})
    dockey = asset_xml.search('//dockey')
    if dockey.nil?
      logger.debug "No valid response in #{asset_xml}"
      return
    end
    if (only.empty? || only['dockey'])
      video_asset.dockey= dockey.text
    end
    if (only.empty? || only['video_type'])
      video_asset.video_type= asset_xml.search('//type').text
    end
    if (only.empty? || only['title'])
      title= asset_xml.search('//title').text
      if ((title.nil? || title.length == 0) && video_asset.title.nil?)
        video_asset.title= 'no title supplied'
      else
        video_asset.title= title
      end
    end
    if (only.empty? || only['description'])
      video_asset.description= asset_xml.search('//description').text
    end
    if (only.empty? || only['video_length'])
      video_asset.video_length= asset_xml.search('//length').text
    end
    if (only.empty? || only['video_status'])
      video_asset.video_status= asset_xml.search('//status').text
    end
  end
  
end
