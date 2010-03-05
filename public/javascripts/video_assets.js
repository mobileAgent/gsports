
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



  gs.video_assets.start_upload = function() {
    $('video_asset_submit').value = "Uploading...";
    $('video_asset_submit').disabled = true;
    uploader.swfu.startUpload();
  }

  gs.video_assets.video_loaded = function() {
    $('video_asset_submit').value = "Upload Complete";
    var form = document.getElementById('submit_form');
    form.submit();
  }

  gs.video_assets.video_failed = function(msg) {
//    var txtFileName = document.getElementById("uploaded_file_path");
//    txtFileName.value = "";

    //video_asset_submit.value = "Try Again";
    //video_asset_submit.disabled = false;

    //flasherror(msg);
  }