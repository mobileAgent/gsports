
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


