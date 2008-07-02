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

  # Our HTTP Client to communicate with Vidavee service
  CLIENT = HTTPClient.new

  # Turn this on for debug of HTTP traffic to Vidavee
  CLIENT.debug_dev = STDERR

  # http://tribeca.vidavee.com/hsstv/rest/session/CheckUser;jsessionid=39555E57BCF38625CF7DEA2EDD9038F7.node1?api_key=5342smallworld&api_ts=1214532647018&api_token=39555E57BCF38625CF7DEA2EDD9038F7.node1&api_sig=830678DF3E967D0392F936122F767754&session_id=
  # Seems to always return false, not sure what good it is
  def check_user(sessionid)
    response = vrequest('session/CheckUser',sessionid)
    extract(response.content, '//isUserLoggedIn').text
  end

  # http://tribeca.vidavee.com/hsstv/rest/session/Login?api_key=5342smallworld&api_ts=1214531598256&api_sig=EFF68F8B9CBC146FCEE39EA3D4AFED79&userName=hsstv&password=hsstvUser
  def login
    response = vrequest('session/Login')
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

  def file_upload_progress(sessionid,uploadid)
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

  def new_playlist(sessionid, extra_params = {})
  end

  def update_playlist(sessionid, extra_params = {})
  end

  # Result is paginated, see currentPage, totalPages
  # also takes optional date range, creator, set, and search keyword
  # Use param AF_page to see other than the first page
  def gallery_playlists(sessionid, extra_params = {})
    response = vrequest('playlist/GetGalleryPlaylists',sessionid,extra_params)
    extract(response.content,'//asset')
  end

  # List items in gallery, result is paginated, see currentPage, totalPages
  # Use 
  def gallery_assets(sessionid, extra_params = {})
    response = vrequest('gallery/GetGalleryAssets',sessionid, extra_params)
    extract(response.content,'//asset')
  end

  # Load gallery assets from vidavee xml into our video_assets models
  def load_gallery_assets(sessionid, extra_params = {})
    response = vrequest('gallery/GetGalleryAssets',sessionid, extra_params)
    assets = extract(response.content,'//asset')
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
      if v.save!
        puts "Saved video #{v.dockey} - #{v.type} as id #{v.id}"
      else
        puts "Failed to save #{v.dockey}"
      end
    end
    assets.size
  end

  def new_vtag(sessionid, dockey, startTime, endTime, title, snapshotOffset, extra_params = {})
    my_params = {'asset' => dockey, 'startTime' => startTime, 'endTime' => endTime, 'snapshotOffset' => snapshotOffset}
    extra_params.each { |p| my_params[p[0]] = p[1] }
    response = vrequest('assets/NewVTag',sessionid,my_params)
  end

  # a <script> tag to use for the embed
  def asset_embed_code(sessionid, dockey)
    response = vrequest('assets/GetDetailsAssetEmbedCode',sessionid,DOCKEY_PARAM => dockey)
    extract(response.content,'//assetEmbedCode').text
  end

  # The html code is not available via an api call in this
  # version, but does not depend on the logged in user or session
  # so we can just plug the dockey into the template
  def asset_embed_html(sessionid,dockey,height=500,width=425)
    '<object width="'+width.to_s+'" height="'+height.to_s+'" align="middle" classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0" id="movie1185893226841"><param name="allowScriptAccess" value="always"></param><param name="movie" value="http://publish.vidavee.com/publish/vidavee/playerv3/vFlasher_debug.swf?p19=movie1185893226841&p2=off&p3=on&p4=50&p5=off&p7=on&p8=on&p22=http://analytics.vidavee.com/v3.1/gateway/&p13=no&p16=v3Skin.swf&p17=http%3A%2F%2Fpublish.vidavee.com%2Fpublish%2Fvidavee%2Fplayerv3%2Fskins%2F&p11=0&p15=http%3A%2F%2Fpublish.vidavee.com%2Fpublish%2FvClientXML.view%3FAF_renderParam_contentType%3Dtext%2Fxml%26dockey%3D'+dockey+'&p21=http%3A%2F%2Fpublish.vidavee.com%2Fpublish%2Fvidavee%2Fplayerv3%2Fjs%2FFlashProxyLoader.js&p18=timeDisplay%3Dyes%3Bwatermark%3Dno%3BtextureStripe%3Dyes%3BvtagDisplay%3Dno"></param><param name="quality" value="high"></param><param name="bgcolor" value="#ffffff" ></param><param name="wmode" value="opaque"></param><embed width="500" height="425" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" quality="high" name="movie1185893226841" src="http://publish.vidavee.com/publish/vidavee/playerv3/vFlasher_debug.swf?p19=movie1185893226841&p2=off&p3=on&p4=50&p5=off&p7=on&p8=on&p22=http://analytics.vidavee.com/v3.1/gateway/&p13=no&p16=v3Skin.swf&p17=http%3A%2F%2Fpublish.vidavee.com%2Fpublish%2Fvidavee%2Fplayerv3%2Fskins%2F&p11=0&p15=http%3A%2F%2Fpublish.vidavee.com%2Fpublish%2FvClientXML.view%3FAF_renderParam_contentType%3Dtext%2Fxml%26dockey%3D'+dockey+'&p21=http%3A%2F%2Fpublish.vidavee.com%2Fpublish%2Fvidavee%2Fplayerv3%2Fjs%2FFlashProxyLoader.js&p18=timeDisplay%3Dyes%3Bwatermark%3Dno%3BtextureStripe%3Dyes%3BvtagDisplay%3Dno" wmode="opaque"></embed></object>'
  end

  # This moves the entire asset to the trash, it should be deleted from there
  def delete_asset(sessionid, dockey)
    response = vrequest('/assets/DeleteAsset',sessionid,DOCKEY_PARAM => dockey)
    extract(response.content,'//status')
  end

  # looking for 'ready' or 'blocked'
  def asset_status(sessionid, dockey)
    response = vrequest('/assets/GetDetailsAssetStatus',sessionid,DOCKEY_PARAM => dockey)
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

  #### Internal methods follow here
  protected 

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

  # Ask a standard request, get a standard answer
  def vrequest(action,sessionid='',extra_params={})
    url = url_for(action,sessionid)
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
    response = CLIENT.post(url,params)
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
