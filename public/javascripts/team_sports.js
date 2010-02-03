


  // Team Sports

  gs.team_sports = {}

  gs.team_sports.current_open_panel = null;
  gs.team_sports.current_open_panel_id = null;

  gs.team_sports.panel_info = function(id) {
    panel_name = 'team-sport-'+id
    sport_div = $(panel_name)
    roster_div = sport_div.select('.roster')[0]

    map = {
      panel_name: panel_name,
      sport_div: sport_div,
      roster_div: roster_div
    }
    
    return map
  }

  gs.team_sports.sport_div_for = function(id) {
    return 'team-sport-'+id
  }

  gs.team_sports.open_panel = function(id) {
    map = this.panel_info(id)

    if(this.current_open_panel){
      this.current_open_panel.select('.opener')[0].select('a')[0].removeClassName('open')
      current_roster =  this.current_open_panel.select('.roster')[0]
      current_roster.hide();
    }
    if(this.current_open_panel_id != id){
      map.roster_div.update('Loading roster...')
      map.sport_div.select('.opener')[0].select('a')[0].addClassName('open')
      new Ajax.Updater(map.roster_div, '/roster_entries/roster', {
        parameters: { "id": id },
        evalScripts: true
      });
    
      this.current_open_panel = map.sport_div
      this.current_open_panel_id = id
      map.roster_div.show()
    }else{
      //just closing
      gs.team_sports.current_open_panel = null;
      gs.team_sports.current_open_panel_id = null;
    }

  }

  gs.team_sports.sort_row = function(url) {
    id = gs.team_sports.current_open_panel_id
    map = this.panel_info(id)

    //map.roster_div.update('Loading roster...')

    new Ajax.Updater(map.roster_div, url, {
        parameters: { "id": id },
        evalScripts: true
      });
  }

  gs.team_sports.edit_row = function(ts_id, re_id) {
    url = '/roster_entries/roster'

    new Ajax.Updater(map.roster_div, url, {
        parameters: { "id": ts_id, "edit":re_id },
        evalScripts: true
      });
  }

  gs.team_sports.show_videos = function(id) {
    new dijit.Dialog({
        title: "Restricted Videos",
        style: "width: 400px",
        href:'/team_sports/videos/'+id
    }).show()
  }


  gs.team_sports.match_user = function(id) {
    new dijit.Dialog({
        title: "Possible Athlete Match",
        style: "width: 400px",
        href:'/roster_entries/match/'+id
    }).show()
  }