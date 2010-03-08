
  gs.video_assets = {}

  gs.video_assets.select_sport = function() {
    select = $('video_asset_sport_select')
    input = $('video_asset_sport')

    if(select.value == 'Other'){
      select.hide();
      input.show();
    }else{
      input.value = select.value
    }
    autofill_video_title()
  }

  gs.video_assets.select_game_level = function() {
    select = $('video_asset_game_level_select')
    input = $('video_asset_game_level')

    if(select.value == 'Other'){
      select.hide();
      input.show();
    }else{
      input.value = select.value
    }
    autofill_video_title()
  }

  gs.video_assets.select_game_type = function() {
    select = $('video_asset_game_type_select')
    input = $('video_asset_game_type')

    if(select.value == 'Other'){
      select.hide();
      input.show();
    }else{
      input.value = select.value
    }
    autofill_video_title()
  }



  //javascript:gs.video_assets.start_upload()

  gs.video_assets.send_meta = function() {
    $('video_asset_submit').value = "Uploading...";
    $('video_asset_submit').disabled = true;

    form = $('upload_form')
    url = '/video_assets/create'

    var jax = new Ajax.Request(url, {
      method: 'post',
      parameters: Form.serialize(form),
      onSuccess:  function (transport) {
          //uploader.swfu.settings.post_params['id'] = transport.responseText
          obj = eval( '(' + transport.responseText + ')' )

          if(obj.id > 0) {
            uploader.swfu.addPostParam('id', obj.id)
            gs.video_assets.start_upload()
          }else{
            flasherror(obj.err)
          }
      },
      onError: function(transport) {
        flashnow('Could not save video');
        $('video_asset_submit').value = "Upload";
        $('video_asset_submit').disabled = false;
      }
    })
  }


  gs.video_assets.start_upload = function() {
    $('video_asset_submit').value = "Uploading Video...";
    $('video_asset_submit').disabled = true;
    uploader.swfu.startUpload();
  }

  gs.video_assets.video_loaded = function() {
    $('video_asset_submit').value = "Upload Complete";
    var form = document.getElementById('submit_form');
    //form.submit();
    window.location='/video_assets/submit_video/'+uploader.swfu.settings.post_params['id']
  }

  gs.video_assets.video_failed = function(msg) {
//    var txtFileName = document.getElementById("uploaded_file_path");
//    txtFileName.value = "";

    //video_asset_submit.value = "Try Again";
    //video_asset_submit.disabled = false;

    //flasherror(msg);
  }