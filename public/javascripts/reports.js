



  var tree = null;
	var reports_tree_request = null;
	var reports_active_tooltip = null;

  function gs_reports_loadclips(branch) {
    var vid, tid;
    
    bid = ""+branch.getId();
    
    //[vid,tid]=bid.split('-')
    var ids=bid.split('-')
    vid = ids[0]
    bid = ids[1]

    params = { "video_asset_id": vid }
    if(tid)
      params["tag_id"] = tid

		if( !(reports_tree_request == null) ){
			reports_tree_request.transport.abort();
		}

    $('clip-window').update('Loading clips...')
    
    new Ajax.Updater('clip-window', '/reports/clips', {
			parameters: params,
			evalScripts: true
    });

    branch.openIt(true);
  }

  function gs_reports_expandme(branch){
    branch.openIt(true);
  }

  function gs_reports_drop_clip(rid,dragName,dropName) {

    divid = $(dragName).id+"_"

    oid = $(dragName).down('.tag').readAttribute('oid')
    ocls = $(dragName).down('.tag').readAttribute('ocls')
    //clickstr = "javascript:gs_reports_clip_select("+rid+", "+oid+", '"+ocls+"')"
    clickstr = "javascript:gs_reports_clip_select("+rid+", '"+divid+"')"

    drop = new Element("div", { id: divid, onclick:clickstr })
    drop.addClassName('report-clip')
    drop.innerHTML = $(dragName).innerHTML
    $('clip-strip').insert( drop )
    //Event.observe(divid, 'click', function(event) { gs_reports_clip_select(oid, ocls) } )


    Sortable.destroy('clip-strip')
    Sortable.create('clip-strip', { tag: 'div'});

    gs_reports_clip_select(rid, divid) //oid, ocls)
    gs_reports_update_clip_droppers()
  
  }
  
  function gs_reports_add_all(rid) {
    target = $('clip-strip')
    $A($('clip-window').childNodes).each(function(child) {
      if(child.id && child.hasClassName('report-clip')){
        gs_reports_drop_clip(1,child,target)
      }
    });
    gs_reports_update_clip_droppers()
  }

  function gs_reports_clip_select(rid,divid) { //ctype,cid) {

    cid = $(divid).down('.tag').readAttribute('oid')
    ctype = $(divid).down('.tag').readAttribute('ocls')
    dockey = $(divid).down('.tag').readAttribute('dockey')

    $('report-detail').update('Loading...')
    
    params = { 'id': rid, 'video_id': cid, 'video_type': ctype }
    //if(gs_reports_small_player)
    //  params['small_player']=1

    new Ajax.Updater('report-detail', '/reports/clip_detail', {
			parameters: params,
			evalScripts: true
    });

    gs_reports_playDockey(dockey)
  }


  function gs_reports_playDockey(dockey) {
    $("flashAreaIFrame").playDockey(dockey);
  }

  var gs_reports_dockey_list = new Array();
  var gs_reports_dockey_active_list = null;

  function getNextDockey() {
    key = gs_reports_dockey_active_list.shift()
    if(key){
      //gs_reports_playDockey(key)

      //find clip by dockey
      divid = null

      $A($('clip-strip').select('div')).each(
        function(child) {
          //tag = child.down('.tag')
          tag = child.select('span[class=tag]')[0]
          if(tag){
            dockey = tag.readAttribute('dockey')
            if(dockey == key)
              divid = child.id
          }
        }
      );

      if(divid)
        gs_reports_clip_select(gs_report_id, divid)
    }
  }

  function gs_reports_play_all() {
    if($("flashAreaIFrame").playDockey){
      gs_reports_dockey_active_list = gs_reports_dockey_list.clone()
      getNextDockey()
    } else {
      setTimeout ( "gs_reports_play_all()", 2000 ); 
    }
  }


  function gs_reports_update(rid, publish) {
    req = []
    
    $A($('clip-strip').select('div')).each(   //.childNodes).each(
      function(child) {
        //tag = child.down('.tag')
        tag = child.select('span[class=tag]')[0]
        if(tag){
          oid = tag.readAttribute('oid')
          ocls = tag.readAttribute('ocls')
          req.push( { 'video_id': oid, 'video_type': ocls } )
        }
      }
    );

    window.meow = req

    params = { 'id': rid, 'video_list':Object.toJSON(req) }
    if(publish)
      params['publish']=publish
    if(gs_reports_small_player)
      params['small_player']=1
   
    target = (publish ? 'dialog' : 'report-player')

    flashnow('Saving report.')

    new Ajax.Updater(target, '/reports/sync', {
      parameters: params,
      evalScripts: true,
      onComplete: function() {
        flashnow('Report saved.')
      }
    });

  }

  function gs_reports_drop_video(source) {
    source.parentNode.remove()
  }

  function gs_reports_update_clip_droppers() {
    clips = 0
    $A($('clip-strip').childNodes).each(function(child) {     if(child.id && $(child).hasClassName('report-clip')){ clips++ }     });
    droppers = 0
    $A($('clip-strip-decoy').childNodes).each(function(child) {     if(child.id && $(child).hasClassName('clip-dropper')){ droppers++ }     });

    if(clips >= droppers){
      dropper_no = droppers+1

      dropper_id = "clip-dropper-"+dropper_no

      dropper = new Element("div", { id: dropper_id })
      dropper.addClassName('clip-dropper')
        table = new Element("table")
          tr = new Element("tr")
            td = new Element("td")
            td.innerHTML = dropper_no
          tr.appendChild(td);
        table.appendChild(tr);
      dropper.appendChild(table);

      $('clip-strip-decoy').insert( dropper )

    }
  }

  function gs_reports_clear_tips() {
    //$('tooltip').update('')
    //if(reports_active_tooltip)
    //  reports_active_tooltip.remove();
  }


  function gs_reports_clip_hover(target) {
    t = $(target)
    img = t.select('img')[0]
    img.setStyle('border: 1px solid yellow')
  }


  function gs_reports_clip_leave(target) {
    t = $(target)
    img = t.select('img')[0]
    img.setStyle('border: 1px solid black')
  }
















  function TafelTreeInit () {
    tree = new TafelTree('tree-view', tree_struct, {
    'generate' : true,
    'imgBase' : '/TafelTree/imgs/',
    'width' : '280px',
    'height' : '290px',
    'openAtLoad' : false,
    'cookies' : false,
    'lineStyle' : 'none'
    });

  }






