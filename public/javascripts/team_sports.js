


  // Team Sports

  gs.team_sports = {}

  gs.team_sports.current_open_panel = null;
  gs.team_sports.current_open_panel_id = null;


  gs.team_sports.open_panel = function(id) {
    panel_name = 'team-sport-'+id
    sport_div = $(panel_name)
    roster_div = sport_div.select('.roster')[0]

    if(this.current_open_panel){
      this.current_open_panel.select('.opener')[0].select('a')[0].removeClassName('open')
      current_roster =  this.current_open_panel.select('.roster')[0]
      current_roster.hide();
    }
    if(this.current_open_panel_id != id){
      roster_div.update('Loading roster...')
      sport_div.select('.opener')[0].select('a')[0].addClassName('open')
      new Ajax.Updater(roster_div, '/team_sports/roster', {
        parameters: { "id": id },
        evalScripts: true
      });
    
      this.current_open_panel = sport_div
      this.current_open_panel_id = id
      roster_div.show()
    }

  }
