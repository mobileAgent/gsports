
  gs.video_assets = {}

  gs.video_assets.base_model = 'video_asset'

  gs.video_assets.select_sport = function() {
    select = $(this.base_model+'_sport_select')
    input = $(this.base_model+'_sport')

    if(select.value == 'Other'){
      select.hide();
      input.show();
    }else{
      input.value = select.value
    }
    autofill_video_title()
  }

  gs.video_assets.select_game_level = function() {
    select = $(this.base_model+'_game_level_select')
    input = $(this.base_model+'_game_level')

    if(select.value == 'Other'){
      select.hide();
      input.show();
    }else{
      input.value = select.value
    }
    autofill_video_title()
  }

  gs.video_assets.select_game_type = function() {
    select = $(this.base_model+'_game_type_select')
    input = $(this.base_model+'_game_type')

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
    $(this.base_model+'_submit').value = "Uploading...";
    $(this.base_model+'_submit').disabled = true;

    form = $('upload_form')
    url = '/'+this.base_model+'s/create'

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
            $(gs.video_assets.base_model+'_submit').value = "Upload";
            $(gs.video_assets.base_model+'_submit').disabled = false;
          }
      },
      onError: function(transport) {
        flasherror('Could not save video');
        $(gs.video_assets.base_model+'_submit').value = "Upload";
        $(gs.video_assets.base_model+'_submit').disabled = false;
      }
    })
  }


  gs.video_assets.start_upload = function() {
    $(this.base_model+'_submit').value = "Uploading Video...";
    $(this.base_model+'_submit').disabled = true;
    uploader.swfu.startUpload();
  }

  gs.video_assets.video_loaded = function() {
    $(this.base_model+'_submit').value = "Upload Complete";
    var form = document.getElementById('submit_form');
    //form.submit();
    window.location='/'+this.base_model+'s/submit_video/'+uploader.swfu.settings.post_params['id']
  }

  gs.video_assets.video_failed = function(msg) {
//    var txtFileName = document.getElementById("uploaded_file_path");
//    txtFileName.value = "";

    //video_asset_submit.value = "Try Again";
    //video_asset_submit.disabled = false;

    //flasherror(msg);
  }