# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper

  # These helpers come from community engine, but when coming
  # from one of our templates (e.g. static/tos) they aren't included
  # by default but if we still want the CE layout override then
  # we need to force them in here
  include BaseHelper
  include ForumsHelper
  include FriendshipsHelper
  include PostsHelper
  include SitemapHelper
  include UsersHelper

  include SortableTable::App::Helpers::ApplicationHelper

  # For rjs pages to tickle the flash on the current page
  def flashnow(page,msg,level='notice')
    page.select("#flash_#{level} span").first.replace("<span>#{msg}</span>")
    page.select("#flash_#{level}").first.show
  end

  def game_date(dtm, tz=TimeZone.new('Eastern Time (US & Canada)'))
    return '' if dtm.nil?
    return dtm.in_time_zone(tz).to_s(:game_date)
  end
  
  def human_date(dtm, tz=TimeZone.new('Eastern Time (US & Canada)'))
    return '' if dtm.nil?
    return dtm.in_time_zone(tz).to_s(:readable)
  end

  def human_date_time(dtm, tz=TimeZone.new('Eastern Time (US & Canada)'))
    return '' if dtm.nil?
    
    # Temporarily forces use of EST/EDT always
    dtm = dtm.in_time_zone(tz)

    case Date.today - dtm.to_date
    when 1 
      day = "Yesterday"
    when 0
      day = "Today"
    when -1
      day = "Tomorrow"
    else
      day = dtm.strftime("%B %e, %Y")
    end

    day + " at " + dtm.strftime("%I:%M %p %Z")
  end
    
  class Pair
    attr_accessor :name, :number
  end

  def cc_years
    arr = Array.new
    for i in (Time.now.year .. Time.now.year+12) do
      p = Pair.new
      p.name = "#{i}"
      p.number = "#{i}"
      arr << p
    end
    arr
  end

  def cc_months
    names = ["January","February","March","April","May","June",
             "July","August","September","October","November","December"]
    arr = Array.new
    for i in (0..11) do
      p = Pair.new
      p.name="#{names[i]} (#{i+1})"
      p.number="#{(i+1)}"
      arr << p
    end
    arr
  end

  def video_image_link(video)
    title = h(video.title.gsub(/\'/,''))
    target = '#'
    case video
    when VideoAsset
      target = video_asset_path(video)
    when VideoClip
      target = video_clip_path(video)
    when VideoReel
      target = video_reel_path(video)
    end
    
    vsrc = @vidavee.file_thumbnail_medium(video.thumbnail_dockey)
    link_to "<img src='#{vsrc}' title='#{title}' alt='Video'/>", target
  end

  def generate_link_for_message(item)
    case item
    when User
      link = "/#{item.id}"
    when Comment
      link = "/#{item.class.to_s.tableize}/show/#{item.id}"
    when Photo, Post, VideoClip, VideoReel, VideoAsset
      if item.user_id
        link = "/#{item.user_id}/#{item.class.to_s.tableize}/#{item.id}"
      end
    when MessageThread
      link = "/messages/thread/#{item.id}"
    end

    if link.nil?
      logger.debug "Generating generic link for class #{item.class.to_s}"
      link ="/#{item.class.to_s.tableize}/#{item.id}"
    end

    link
  end

  # extend the ActionView::Helpers::AssetTagHelper#image_tag to support mouseclick image
  def image_tag(source, options={})
    if mouseclick = options.delete(:mouseclick)
      options[:onmousedown] = "this.src='#{image_path(mouseclick)}';return true"
      options[:onmouseup]  = "this.src='#{path_to_image(source)}'; return true"
      options[:onmouseout]  = "this.src='#{path_to_image(source)}'; return true"
    end

    super source, options
  end
  
  def remaining_char_count(field_id, update_id, max=0, options={})
    function = "$('#{update_id}').innerHTML = #{max > 0 ? (max.to_s + '-') : ''} $F('#{field_id}').length;"
    out = javascript_tag(function) # set current length
    options = {:frequency => 0.1, :function => function}.merge(options) # default options
    out += observe_field(field_id, options) # and observe it    
  end
  
  def character_count(field_id, update_id, options={})
    remaining_char_count(field_id,update_id,0,options)
  end


  # in place editor


  def edit_inplace(record, attr, options={}, &block)

    defaults = { :rows=>1, :cols=>12 }

    options = defaults.merge(options)

    options[:value] ||= (record.attributes()[attr] rescue '-')
    options[:url] = "/#{record.class.to_s.pluralize.downcase}/update/#{record.id}"

    options[:editor_id] = "#{record.class}_#{attr}_editor"

    options[:input_id]=   "#{options[:editor_id]}_input"
    options[:input_name]= "#{record.class.to_s.downcase}[#{attr}]"


    options.merge!(:body => capture(options, &block)) if block
    #options.merge!(:body => block)

    if false && block
      concat(render(:partial=>'shared/inplace_edit', :locals=>{ :model=>record, :attr=>attr, :options=>options }), block.binding)
    else
      render(:partial=>'shared/inplace_edit', :locals=>{ :model=>record, :attr=>attr, :options=>options })
    end

#    if block_given?
#      concat(render(:partial=>'shared/inplace_edit', :locals=>{ :model=>record, :attr=>attr, :options=>options }), block.binding)
#    else
#      concat(render(:partial=>'shared/inplace_edit', :locals=>{ :model=>record, :attr=>attr, :options=>options }))
#    end
  end

  def xedit_inplace(record, attr, options)
    render :partial=>'shared/inplace_edit', :locals=>{ :model=>record, :attr=>attr, :options=>options }
  end


end
