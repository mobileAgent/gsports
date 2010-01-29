module TeamSportsHelper


  def gs_team_sports_sortable_table_header(opts = {})
    raise ArgumentError if opts[:name].nil? || opts[:sort].nil?
    anchor = opts[:anchor].blank? ? "" : "##{opts[:anchor]}"
    content_tag :th,
      link_to(opts[:name],
        "javascript:gs.team_sports.sort_row('#{sortable_url(opts)}')" + anchor,
        :title => opts[:title]),
      :class => sortable_table_header_classes(opts)
  end

  
end