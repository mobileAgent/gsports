  
  var tree = null;
	var reports_tree_request = null;

  function gs_reports_loadclips(branch) {
    var vid, tid;
    
    bid = ""+branch.getId();
    
    [vid,tid]=bid.split('-')

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
    clickstr = "javascript:gs_reports_clip_select("+rid+", "+oid+", '"+ocls+"')"

    drop = new Element("div", { id: divid, onclick:clickstr })
    drop.addClassName('report-clip')
    drop.innerHTML = $(dragName).innerHTML
    $('clip-strip').insert( drop )
    //Event.observe(divid, 'click', function(event) { gs_reports_clip_select(oid, ocls) } )


    Sortable.destroy('clip-strip')
    Sortable.create('clip-strip', { tag: 'div'});

    gs_reports_clip_select(rid, oid, ocls)
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

  function gs_reports_clip_select(rid,ctype,cid) {
    $('report-player').update('Loading...')
    
    params = { 'id': rid, 'video_id': ctype, 'video_type': cid }
    if(gs_reports_small_player)
      params['small_player']=1

    new Ajax.Updater('report-player', '/reports/player', {
			parameters: params,
			evalScripts: true
    });
  }


  function gs_reports_update(rid, publish) {
    req = []
    
    $A($('clip-strip').childNodes).each(
      function(child) {
        oid = child.down('.tag').readAttribute('oid')
        ocls = child.down('.tag').readAttribute('ocls')
        req.push( { 'video_id': oid, 'video_type': ocls } )
      }
    );

    window.meow = req

    params = { 'id': rid, 'video_list':Object.toJSON(req) }
    if(publish)
      params['publish']=publish
    if(gs_reports_small_player)
      params['small_player']=1
   
    target = (publish ? 'dialog' : 'report-player')

    new Ajax.Updater(target, '/reports/sync', {
      parameters: params,
      evalScripts: true
    });

  }

  function gs_reports_drop_video(source) {
    source.parentNode.remove()
  }

  function gs_reports_update_clip_droppers() {
    clips = 0
    $A($('clip-strip').childNodes).each(function(child) {     if(child.id && child.hasClassName('report-clip')){ clips++ }     });
    droppers = 0
    $A($('clip-strip-decoy').childNodes).each(function(child) {     if(child.id && child.hasClassName('clip-dropper')){ droppers++ }     });

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
  
  function TafelTreeInit () {
    tree = new TafelTree('tree-view', tree_struct, {
    'generate' : true,
    'imgBase' : '/TafelTree/imgs/',
    'width' : '280px',
    'height' : '290px',
    'openAtLoad' : false,
    'cookies' : false
    });
  }




