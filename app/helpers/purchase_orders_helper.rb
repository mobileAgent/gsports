module PurchaseOrdersHelper

  def purchase_order_org_path(po)
    if po.user.team_staff?
      team_path(po.user.team)
    else #if po.user.league_staff?
      league_path(po.user.league)
    end
  end
  
end