var htn;
var vtn;
var ajaxRespCount = 0;

function set_game_date_today()
{
    d = new Date()
    month = (d.getMonth()+1)
    day = d.getDate()
    if (month < 10) {
        month = "0" + month
    }
    if (day < 10) {
        day = "0" + day
    }
    $('video_asset_game_date').value =
        d.getFullYear() + "-" + month + "-" + day
}
        
function generate_video_title_if_blank()     
{
    if ($('video_asset_title').value.length == 0)
        generate_video_title()
}

function generate_video_title()
{
    var ht = $F('video_asset_home_team_name')
    var vt = $F('video_asset_visiting_team_name')
    htn = ht
    vtn = vt
    if (ht && ht.length > 0)
    {
        var url = '/teamname/' + escape(ht).replace(/\./g,"%2e")
        var htajax = new Ajax.Request(url, {method: 'get',
            parameters: 'nick=true',
            onSuccess:  function (transport) {
                //alert (' in ht rsp ' + transport.responseText + ' >> ' + htn)
                htn = transport.responseText
                ajaxRespCount++
            },
            onError: function(transport) {
                ajaxRespCount++
            }})
    }
    else
    {
        ajaxRespCount++;
    }
    if (vt && vt.length > 0)
    {
        var url = '/teamname/' + escape(vt).replace(/\./g,"%2e")
        var vtajax = new Ajax.Request(url, {method: 'get',
            parameters: 'nick=true',
            onSuccess:  function (transport) {
                //alert (' in vt rsp ' + transport.responseText + ' >> ' + vtn );
                vtn = transport.responseText
                ajaxRespCount++
            },
            onError: function(transport) {
                ajaxRespCount++
            }})
    }
    else
    {
        ajaxRespCount++
    }
    if (ajaxRespCount == 2)
    {
        buildTitle()
    }
    else
    {
        setTimeout("buildTitle()",100)
    }
}
    
function buildTitle()
{
    if (ajaxRespCount < 2)
    {
        setTimeout('buildTitle()',100);
        return;
    }
    ajaxRespCount = 0;
    hscore = $F('video_asset_home_score')
    vscore = $F('video_asset_visitor_score')
    game_date = format_game_date($F('video_asset_game_date'))
    bg = $F('video_asset_game_gender')
    sport = $F('video_asset_sport')
    game_level_field = $('video_asset_game_level')
    game_level = ''
    game_type_field = $('video_asset_game_type')
    game_type = ''
    if (game_level_field)
    {
        game_level = game_level_field.value
    }
    else /* look for a dhtml x combox box by name */
    {
        game_level_field =
            document.getElementsByName('video_asset[game_level]')[0]
        if (game_level_field)
            game_level = game_level_field.value
    }

    if (game_type_field)
    {
        game_type = game_type_field.value
    }
    else /* look for a dhtmlx combo box by name */
    {
        game_type_field =
            document.getElementsByName('video_asset[game_type]')[0]
        if (game_type_field)
            game_type = game_type_field.value
    }
    title = htn
    if (hscore.length > 0)
        title += '('+hscore+')'
    if (vtn.length > 0)
    {
        title += ' vs ' + vtn
        if (vscore.length > 0)
            title += '('+vscore+')'
    }
    title += ','
    if (bg.length > 0)
        title += ' ' + bg
    if (game_level.length > 0)
        title += ' ' + game_level
    if (sport.length > 0)
        title += ' ' + sport
    if (game_date.length > 0)
        title += ' [' + game_date + ']'
    if (game_type.length > 0 && game_type != 'Regular Season')
        title += ' ' + game_type
    $('video_asset_title').value = title
}


function format_game_date(str)
{
    var ymd = new RegExp(/^(\d\d\d\d)-(\d\d)-(\d\d)$/)
    var m = ymd.exec(str)
    if (m && m.length == 4)
        return m[2] + "-" + m[3] + "-" + m[1]
    
    var ym = new RegExp(/^(\d\d\d\d)-(\d\d)$/)
    m = ym.exec(str)
    if (m && m.length == 3)
        return m[2] + "-" + m[1]
    
    return str
}