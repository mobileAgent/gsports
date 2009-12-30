  // Place your application-specific JavaScript functions and classes here
  // This file is automatically included by javascript_include_tag :defaults


  // modeled after: # For rjs pages to tickle the flash on the current page
  function flashnow(msg) {
    $('flash_notice').select('span')[0].replace("<span>"+msg+"</span>")
    $('flash_notice').show()
  }


  var gs = {}

  gs.$N = function(tag, attrs, content){
    e = $(document.createElement(tag));
    if(attrs){
      for(attr in attrs)
        if( attrs.hasOwnProperty(attr) )
          e.setAttribute(attr, attrs[attr]);
    }
    if(content){
      e.update(content)
    }
    return e
  }





  // Team Management

  gs.team = {}

  gs.team.sport_list = [];

  gs.team.add_coach_panel_counter = 0;

  gs.team.add_coach = function(selected_sport) {

    counter_id = this.add_coach_panel_counter++
    panel_id = 'coach-panel-'+counter_id

    container = gs.$N('div', {'id': panel_id, 'class': 'team-coach-panel' })

    select = gs.$N('select', {
      'type': 'text',
      'name': 'coach[sport-'+counter_id+']',
      'onchange': 'javascript:gs.team.pick_sport(this)'
    })

    selection_found = false

    len = gs.team.sport_list.size()
    for( s=0; s<len; s++) {
      sport = gs.team.sport_list[s]
      attrs = {}
      if(sport == selected_sport){
        selection_found = true
        attrs['selected'] = 1
      }
      select.appendChild( gs.$N('option', attrs, sport) )
    }

    select_other = selected_sport && !selection_found

    attrs = {'value':-1}
    if(select_other)
      attrs['selected'] = 1
    select.appendChild( gs.$N('option', attrs, 'Other') )

    container.appendChild(select);


    input = gs.$N('input', {
      'style': 'display: none',
      'type': 'text',
      'name': 'coach[sporttext-'+counter_id+']'
    })

    if(select_other)
      input.value = selected_sport

    container.appendChild(input);


    remove = gs.$N('a', {
      'href': "javascript:gs.team.remove_sport('"+panel_id+"')",
      'name': 'coach[sport-'+counter_id+']'
    })
    remove.update('X')
    container.appendChild(remove);


    $('coaching-roles').appendChild(container);

    this.pick_sport(select)

  }


  gs.team.pick_sport = function(target){
    target = $(target)
    console.log(target.value)
    if(target.value == -1){
      $(target).hide()
      input = $($(target).parentNode).select('input')[0]
      input.show()
    }
  }

  gs.team.remove_sport = function(target){
    target = $(target)
    console.log(target)
    target.remove()
  }


