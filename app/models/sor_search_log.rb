require 'rubygems'
require 'mechanize'
require 'logger'

class SorSearchLog < ActiveRecord::Base
  def self.do_search
    @users = User.find(:all, :conditions => "enabled = true and created_at > '#{1.days.ago}'")

    if @users.size >0
      agent = WWW::Mechanize.new
      for user in @users
        self.search_user_with_sor(user, agent)
      end
    end
  end

  def self.search_user_with_sor(user,agent)
    if user.state_id
      SorSearchLog.send("search_user_state_#{user.state_id}".to_sym, user, agent)
    end
  end

  # id = 1 state AL (Alabama)
  # Search field: (LastName) ctl00$BodyArea1$UcSexOffender1$txtLastName, ,(City) ctl00$BodyArea1$UcSexOffender1$txtCity
  # more field: (ZipCode) ctl00$BodyArea1$UcSexOffender1$txtZipCode ,(County) ctl00$BodyArea1$UcSexOffender1$txtCounty
  # accept : N/A
  # link result : N/A
  def self.search_user_state_1(user,agent)
    page = agent.get("http://community.dps.alabama.gov/Default.aspx")
    search_form = page.forms.with.name("aspnetForm").first
    unless user.lastname =='' or user.city ='' or user.city==nil
      search_form.field("ctl00$BodyArea1$UcSexOffender1$txtLastName").value =user.lastname
      search_form.field("ctl00$BodyArea1$UcSexOffender1$txtCity").value= user.city
      button = search_form.buttons.with.name("ctl00$BodyArea1$UcSexOffender1$btnSearch")
      doc = search_form.click_button(button)
      if doc.links.size >64
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'AL'
        result.link ="N/A"
        result.save
      end
    end
  end

  # id =2 state = AK (Alaska)
  # search field: LastName, FirstName
  # more field:  SearchForm$City , SearchForm$ZipCodes
  # accept : N/A
  # link result : yes
  def self.search_user_state_2(user,agent)
    page = agent.get("http://www.dps.state.ak.us/Sorweb/Search.aspx")
    search_form = page.forms.with.name("SearchFormControl").first
    search_form.FirstName =user.firstname
    search_form.LastName =user.lastname
    doc = agent.submit(search_form)
    if doc.links.size >16
      result = SorSearchLog.new
      result.lastname = user.lastname
      result.firstname = user.firstname
      result.user_id =user.id
      result.state_name = 'AK'
      result.link ="http://www.dps.state.ak.us/Sorweb/list.aspx?Preview=FALSE&PgNum=1&SEARCH_TYPE=search&FirstName=#{user.firstname}&LastName=#{user.lastname}&AddressType=&StreetName=&SearchForm%24ZipCodes=All+Zip+Codes&SearchForm%24City=All+Cities&ExecuteQry=Submit+Query"
      result.save
    end
  end

  # id = 3 state = AZ (Arizona)
  # Search field: lastName
  # more field: (more form)
  # accept : N/A
  # link result : N/A
  def self.search_user_state_3(user,agent)
    page = agent.get("http://az.gov/webapp/offender/searchName.do")
    search_form = page.forms.with.name("nameSearchForm").first
    search_form.lastName =user.lastname
    doc = agent.submit(search_form)
    unless doc.uri == page.uri
      result = SorSearchLog.new
      result.lastname = user.lastname
      result.user_id =user.id
      result.state_name = 'AZ'
      result.link ="N/A"
      result.save
    end
  end

  # id = 4 state = AR (arkansas)
  # Search field: name
  # more field: city, county, state
  #http://www.acic.org/soff/index.php
  def self.search_user_state_4(user,agent)
    page = agent.get("http://www.acic.org/soff/index.php")
    accept_form = page.forms.first
    unless  accept_form.buttons.with.value("I Agree").nil?
      button=accept_form.buttons.with.value("I Agree")
      page = accept_form.click_button(button)
    end
    search_form = page.forms.first
    search_form.field("name").value =user.firstname + ', ' +  user.lastname
    button=search_form.buttons.with.value("Search")
    doc = search_form.click_button(button)
    if doc.links.size >13
      result = SorSearchLog.new
      result.lastname = user.lastname
      result.firstname = user.firstname
      result.user_id =user.id
      result.state_name = 'AR'
      result.link ="N/A"
      result.save
    end
  end

  # id = 5 state = CA (California)
  # Search field: LastName, FirstName
  # more form:
  # accept : yes
  # link result : yes
  #http://meganslaw.ca.gov/disclaimer.htm
  def self.search_user_state_5(user,agent)
    page = agent.get("http://meganslaw.ca.gov/disclaimer.htm")
    accept_form = page.forms.first
    unless  accept_form.buttons.with.value("Continue").nil?
      accept_form.checkboxes.first.checked =true
      button=accept_form.buttons.with.value("Continue")
      page = accept_form.click_button(button)
      link = page.links.text('Name Search')
      page = agent.click(link)
    end
    search_form = page.forms.first
    search_form.lastName =user.lastname
    search_form.firstName =user.firstname
    doc = agent.submit(search_form)
    if doc.links.size >9
      result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'CA'
        result.link ="http://meganslaw.ca.gov/cgi/prosoma.dll?lastName=#{user.lastname}&firstName=#{user.firstname}&Address=&City=&zipcode=&City2=&zipcode2=&ParkName=&City3=&zipcode3=&schoolName=&City4=&zipcode4=&pan=&distacross=107211&centerlat=38409907&centerlon=-121514242&starlat=&starlon=&startext=&x1=&y1=&x2=&y2=&mapwidth=525&mapheight=400&zoom=&searchBy=name&id=&docountycitylist=0&OFDTYPE=&searchDistance=.75&countyLocation=&SelectCounty=&searchDistance2=.75&countyLocation3=&searchDistance3=.75&countyLocation4=&refineID=---------------------------&zoomAction=Box"
        result.save
    end
  end

  # id = 6 state = CO (Colorado)
  # can't use auto browser
  def self.search_user_state_6(user,agent)


  end

  # id = 7 state = CT (Connecticut)
  def self.search_user_state_7(user,agent)


  end

  # id = 8 state = DE (Delaware)
  # http://sexoffender.dsp.delaware.gov/sor_search.htm
  # search field: lname, fname
  # linkresult :N/A
  # Acceptment :N/A
  def self.search_user_state_8(user,agent)
    page = agent.get("http://sexoffender.dsp.delaware.gov/sor_search.htm")
    search_form = page.forms.with.name("nsearch").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.field("lname").value =user.lastname
      search_form.field("fname").value =user.firstname
      doc = agent.submit(search_form)
      if doc.links.size >36
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'DE'
        result.link ="N/A"
        result.save
      end
    end
  end

  # id = 9 state = DC (District Of Columbia )
  # Search field: txtLast (lastname), txtFirst (firstname)
  # more field: txtDictric1 (District), drpQuad (City Quadrant)
  def self.search_user_state_9(user,agent)
    page = agent.get("http://sor.csosa.net/sor/public/publicSearch.asp")
    search_form = page.forms.with.name("form").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.field("txtLast").value =user.lastname
      search_form.field("txtFirst").value =user.firstname
      doc = agent.submit(search_form)
      if doc.links.size >1
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'DC'
        result.link ="N/A"
        result.save
      end
    end
  end

  # id = 10 state = FL (Florida)
  def self.search_user_state_10(user,agent)


  end

  # id = 11 state = GA (Georgia)
  def self.search_user_state_11(user,agent)


  end

  # id = 12 state = HI (Hawaii)
  def self.search_user_state_12(user,agent)


  end

  # id = 13 state = ID (Idaho)
  def self.search_user_state_13(user,agent)


  end

  # id = 14 state = IL (Illinois)
  def self.search_user_state_14(user,agent)


  end

  # id = 15 state = IN (Indiana)
  def self.search_user_state_15(user,agent)


  end

  # id = 16 state = IA (Iowa)
  def self.search_user_state_16(user,agent)


  end

  # id = 17 state = KS (Kansas)
  def self.search_user_state_17(user,agent)


  end

  # id = 18 state = KY (Kentucky)
  def self.search_user_state_18(user,agent)


  end

  # id = 19 state = LA (Louisiana)
  def self.search_user_state_19(user,agent)


  end

  # id = 20 state = ME (Maine)
  def self.search_user_state_20(user,agent)


  end

  # id = 21 state = MA (Maryland)
  def self.search_user_state_21(user,agent)


  end

  # id =22 state = MA (Massachusetts)
  # LastName, County , City Name
  def self.search_user_state_22(user,agent)
    page = agent.get("http://sorb.chs.state.ma.us/search.htm")
    accept_link = page.links.text("PROCEED")
    unless accept_link == nil
      page =agent.click(link)
    end
    search_form = page.forms.with.name("Search1").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.LastName =user.lastname
      doc = agent.submit(search_form)
      if doc.forms.buttons.size >0
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'MA'
        result.link ="N/A"
        result.save
      end
    end
  end


  # id = 23 state = MI (Michigan)
  def self.search_user_state_23(user,agent)


  end

  # id = 24 state = MN (Minnesota)
  def self.search_user_state_24(user,agent)


  end

  # id = 25 state = MS (Missisippi)
  def self.search_user_state_25(user,agent)


  end

  # id = 26 state = M0 (Missouri)
  def self.search_user_state_26(user,agent)


  end

  # id = 27 state = MT (Montana)
  def self.search_user_state_27(user,agent)


  end

  # id = 28 state = NE (Nebraska)
  def self.search_user_state_28(user,agent)


  end

  # id = 29 state = NV (Nevada)
  def self.search_user_state_29(user,agent)


  end

  # id = 30 state = NH (New Hampshire)
  def self.search_user_state_30(user,agent)


  end

   # id =31 , state NJ (New Jersey)
  def self.search_user_state_31(user,agent)
    page = agent.get("https://www6.state.nj.us/LPS_spoff/individualsearch.jsp")
    accept_form =page.forms.with.name("OK").first
    unless accept_form == nil
      page =agent.submit(accept_form)
      page = agent.get("https://www6.state.nj.us/LPS_spoff/individualsearch.jsp")
    end
    search_form = page.forms.with.name("IS").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.lnme =user.lastname
      search_form.fnme =user.firstname
      doc = agent.submit(search_form)
      if doc.links.size >49
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'NJ'
        result.link ="N/A"
        result.save
      end
    end
  end

  # id = 32 state = NM (New Mexico)
  def self.search_user_state_32(user,agent)


  end

   # id =33 , state NY (New York)
  def self.search_user_state_33(user,agent)
    page = agent.get("http://www.criminaljustice.state.ny.us/nsor/search_index.htm")
    search_form = page.forms.with.action("/cgi/internet/nsor/fortecgi").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.LastName =user.lastname
      doc = agent.submit(search_form)
      if doc.links.size >1
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'NY'
        result.link ="http://www.criminaljustice.state.ny.us/cgi/internet/nsor/fortecgi?ServiceName=WebNSOR&TemplateName=results.htm&RequestingHandler=WebNSORSearchResultsHandler&LastName=#{user.lastname}&Zip=&reset=Clear&County=+"
        result.save
      end
    end
  end

  # id = 34 state = NC (North Carolina)
  def self.search_user_state_34(user,agent)


  end

  # id = 35 state = ND (North Dakota)
  def self.search_user_state_35(user,agent)


  end

  # id = 36 state = OH (Ohio)
  def self.search_user_state_36(user,agent)


  end

  # id = 37 state = OK (Oklahoma)
  def self.search_user_state_37(user,agent)


  end

  # id = 38 state = OR (Oregon)
  def self.search_user_state_38(user,agent)


  end

  # id = 39 state = PA (Pennsylvania)
  def self.search_user_state_39(user,agent)


  end

  # id = 40 state = RI (Rhode Island)
  def self.search_user_state_40(user,agent)


  end

  # id = 41 state = SC (South Carolina)
  def self.search_user_state_41(user,agent)


  end

  # id = 42 state = SD (South Dakota)
  def self.search_user_state_42(user,agent)


  end

  # id = 43 state = TN (Tennessee)
  def self.search_user_state_43(user,agent)


  end

  # id = 44 state = TX (Texas)
  def self.search_user_state_44(user,agent)


  end

  # id = 45 state = UT (Utah)
  def self.search_user_state_45(user,agent)


  end

  # id = 46 state = VT (Vermont)
  def self.search_user_state_46(user,agent)


  end

  # id = 47 state = VA (Virginia)
  def self.search_user_state_47(user,agent)


  end

  # id = 48 state = WA (Washington)
  def self.search_user_state_48(user,agent)


  end

  # id = 49 state = WV (West Virginia)
  def self.search_user_state_49(user,agent)


  end

  # id = 50 state = WI (Wisconsin)
  def self.search_user_state_50(user,agent)


  end

  # id = 51 state = WY (Wyoming)
  def self.search_user_state_51(user,agent)


  end
end
