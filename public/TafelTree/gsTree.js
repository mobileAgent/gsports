  
  var tree = null;
	var reports_tree_request = null;



  function gs_reports_loadclips(branch) {

    vid = branch.getId();

		if( !(reports_tree_request == null) ){
			reports_tree_request.transport.abort();
		}

    $('clip-window').update('Loading clips...')
    
    new Ajax.Updater('clip-window', '/reports/clips', {
			parameters: { "video_asset_id": vid }
    });




  }





  var tree_struct1 = [
    {
      'id' : 'root_1',
      'txt' : 'Root 1',
      'items' : [
        {
          'id' : 'branch_1',
          'txt' : 'Branch 1 CLICKME',
          'onclick': 'gsTafelTreeClick'
        },{
          'id' : 'branch_2',
          'txt' : 'Branch 2'
        }
      ]
    }
  ];
  
  function TafelTreeInit () {
    tree = new TafelTree('tree-view', tree_struct, {
    'generate' : true,
    'imgBase' : '/TafelTree/imgs/',
    'width' : '300px',
    'height' : '300px',
    'openAtLoad' : true,
    'cookies' : false
    });
  }




