#require 'rubygems'
require 'mechanize'
require 'logger'

class SorSearchLog < ActiveRecord::Base
  def self.do_search
    users1 = User.find(:all, :conditions => "enabled = true and created_at > '#{1.days.ago}'")
    users2 = self.find_memberships_to_bill_next_day
    users =(users1 +users2).uniq
    SorSearchLog.delete_all
    if users.size >0
      agent = WWW::Mechanize.new
      for user in users
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
  # Search field: (LastName) ctl00$BodyArea1$UcSexOffender1$txtLastName -->  used http://www.familywatchdog.us/search.asp
  def self.search_user_state_1(user,agent)
    self.search_user_in_family_watchdog(user,agent)
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
    if user.city?
      search_form.field("SearchForm$City").value =user.city
    end
    if user.zip?
      search_form.field("SearchForm$ZipCodes").value =user.zip
    end
    search_result = agent.submit(search_form)
    if search_result.links.size >16
      result = SorSearchLog.new
      result.lastname = user.lastname
      result.firstname = user.firstname
      result.user_id =user.id
      result.state_name = 'AK'
      result.link ="http://www.dps.state.ak.us/Sorweb/list.aspx?Preview=FALSE&PgNum=1&SEARCH_TYPE=search&FirstName=#{user.firstname}&LastName=#{user.lastname}&AddressType=&StreetName=&SearchForm%24ZipCodes=#{user.zip}&SearchForm%24City=#{user.city}&ExecuteQry=Submit+Query"
      result.html_content =search_result.body
      result.save
    end
  end

  # id = 3 state = AZ (Arizona)
  # Search field: lastName
  # more field: multi form
  # accept : N/A
  # link result : N/A
  # soundex -->  used http://www.familywatchdog.us/search.asp
  def self.search_user_state_3(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 4 state = AR (arkansas)
  # Search field: name
  # more field: city, county, state
  #http://www.acic.org/soff/index.php
  # search use Soundex
  def self.search_user_state_4(user,agent)
    self.search_user_in_family_watchdog(user,agent)
    page = agent.get("http://www.acic.org/soff/index.php")
    accept_form = page.forms.first
    unless  accept_form.buttons.with.value("I Agree").nil?
      button=accept_form.buttons.with.value("I Agree")
      page = accept_form.click_button(button)
    end
    search_form = page.forms.first
    search_form.field("name").value =user.firstname + ', ' +  user.lastname
    if user.zip?
      search_form.zip =user.zip
    end
    if user.city?
      search_form.city =user.city
    end
  #  if user.county?
  #    search_form.county =user.county
  #  end
    button=search_form.buttons.with.value("Search")
    search_result = search_form.click_button(button)
    if search_result.links.size >13
      result = SorSearchLog.new
      result.lastname = user.lastname
      result.firstname = user.firstname
      result.user_id =user.id
      result.state_name = 'AR'
      result.link =""
      result.html_content =search_result.body
      result.save
    end
  end

  # id = 5 state = CA (California)
  # Search field: LastName, FirstName
  # more form: multi form
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
    search_result = agent.submit(search_form)
    if search_result.links.size >9
      result = SorSearchLog.new
      result.lastname = user.lastname
      result.firstname = user.firstname
      result.user_id =user.id
      result.state_name = 'CA'
      result.link ="http://meganslaw.ca.gov/cgi/prosoma.dll?lastName=#{user.lastname}&firstName=#{user.firstname}&Address=&City=&zipcode=&City2=&zipcode2=&ParkName=&City3=&zipcode3=&schoolName=&City4=&zipcode4=&pan=&distacross=107211&centerlat=38409907&centerlon=-121514242&starlat=&starlon=&startext=&x1=&y1=&x2=&y2=&mapwidth=525&mapheight=400&zoom=&searchBy=name&id=&docountycitylist=0&OFDTYPE=&searchDistance=.75&countyLocation=&SelectCounty=&searchDistance2=.75&countyLocation3=&searchDistance3=.75&countyLocation4=&refineID=---------------------------&zoomAction=Box"
      result.html_content =search_result.body
      result.save
    end
  end

  # id = 6 state = CO (Colorado)
  # can't use auto browser --> used http://www.familywatchdog.us/search.asp
  def self.search_user_state_6(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 7 state = CT (Connecticut)
  # network timeout --> used http://www.familywatchdog.us/search.asp
  def self.search_user_state_7(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 8 state = DE (Delaware)
  # http://sexoffender.dsp.delaware.gov/sor_search.htm
  # search field: lname, fname
  # multi form
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
      search_result = agent.submit(search_form)
      if search_result.links.size >36
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'DE'
        result.link =""
        result.html_content =search_result.body
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
      search_form.txtLast =user.lastname
      search_form.txtFirst =user.firstname
      if user.city?
        search_form.drpQuad = user.city
      end
      search_result = agent.submit(search_form)
      if search_result.links.size >1
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'DC'
        result.link =""
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 10 state = FL (Florida)
  # http://offender.fdle.state.fl.us/offender/offenderSearchNav.do?link=advanced
  # search field: firstName, LastName, city, county
  def self.search_user_state_10(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 11 state = GA (Georgia)
  # http://services.georgia.gov/gbi/gbisor/SORSearch.jsp
  # search field = fname, lastname
  # more field = city , county
  def self.search_user_state_11(user,agent)
    page = agent.get("http://services.georgia.gov/gbi/gbisor/SORSearch.jsp")
    search_form = page.forms.with.name("SearchOffender").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.lname =user.lastname
      search_form.fname =user.firstname
      if user.city?
        search_form.city =user.city
      end
    #  if user.county?
    #    search_form.county =user.county
    #  end
      search_result = agent.submit(search_form)
      if search_result.links.size >0
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'GA'
        result.link =""
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 12 state = HI (Hawaii)
  #http://sexoffenders.ehawaii.gov/sexoff/search.jsp
  # search field: LNAME, FNAME
  # more field :ZIP
  def self.search_user_state_12(user,agent)
    page = agent.get("http://sexoffenders.ehawaii.gov/sexoff/search.jsp")
    search_form = page.forms.first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.LNAME =user.lastname
      search_form.FNAME =user.firstname
      if user.zip?
        search_form.ZIP =user.zip
      end
      search_result = agent.submit(search_form)
      if search_result.links.size >12
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'HI'
        result.link =""
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 13 state = ID (Idaho)
  # Search field :fnm (firstname), lnm (lastname)
  # More field :cty (City),cnt (County)
  #http://www.isp.state.id.us/sor_id/search_regnam.htm
  def self.search_user_state_13(user,agent)
    page = agent.get("http://www.isp.state.id.us/sor_id/search_regnam.htm")
    search_form = page.forms.with.name("searchform").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.lnm =user.lastname
      search_form.fnm =user.firstname
      if user.city?
        search_form.cty =user.city
      end
     # if user.county?
     #   search_form.cnt =user.county
     # end
      search_result = agent.submit(search_form)
      if search_result.links.size >17
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'ID'
        result.link =""
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 14 state = IL (Illinois)
  # search field: lastname,  city
  # more field: county, zipcode
# http://www.isp.state.il.us/sor/
  def self.search_user_state_14(user,agent)
    page = agent.get("http://www.isp.state.il.us/sor/")
    accept_form = page.forms.with.name("disc").first
    unless  accept_form.buttons.with.value("I Agree").nil?
      button=accept_form.buttons.with.value("I Agree")
      page = accept_form.click_button(button)
    end
    search_form = page.forms.with.name("SSOR").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.lastname =user.lastname
      if user.city?
        search_form.city =user.city
      end
      if user.zip?
        search_form.zipcode=user.zip
      end
    #  if user.county?
    #    search_form.county =user.county
    #  end
      search_result = agent.submit(search_form)
      if search_result.links.size >28
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'IL'
        result.link =""
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 15 state = IN (Indiana)
  # http://www.insor.org/insasoweb/
  # multi form
  def self.search_user_state_15(user,agent)
    page = agent.get("http://www.insor.org/insasoweb/")
    accept_form = page.forms.with.name("agreementForm").first
    unless accept_form ==nil
      radio_button = accept_form.radiobuttons.first
      radio_button.checked =true
      page =agent.submit(accept_form)
    end
    search_form = page.forms.with.name("advancedSearchForm").first
    search_form.lastName =user.lastname
    search_form.firstName =user.firstname
   # if user.county?
   #   search_form.countyList =user.county
   # end
    search_result = search_form.submit
    if search_result.links.size >9
      result = SorSearchLog.new
      result.lastname = user.lastname
      result.firstname = user.firstname
      result.user_id =user.id
      result.state_name = 'IN'
      result.link =""
      result.html_content =search_result.body
      result.save
    end
  end

  # id = 16 state = IA (Iowa)
  # http://www.iowasexoffender.com/search.php
  # search field: lname, fname
  # more field: city , rzip, countysearch
  def self.search_user_state_16(user,agent)
    page = agent.get("http://www.iowasexoffender.com/search.php")
    link = page.links.href("http://www.iowasexoffender.com/proc01.php")
    unless link.nil?
      page = agent.click(link)
      page = agent.get("http://www.iowasexoffender.com/search.php")
    end
    search_form = page.forms.first
     if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.lname =user.lastname
      search_form.fname = user.firstname
      if user.zip?
        search_form.rzip = user.zip
      end
      if user.city?
        search_form.city = user.city
      end
  #    if user.county?
  #      search_form.countysearch =user.county
  #    end
      search_result =search_form.submit
      if search_result.links.size >19
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'IA'
        result.link ="http://www.iowasexoffender.com/searchENG.php?lname=#{user.lastname}&fname=#{user.firstname}&city=#{user.city}&rzip=#{user.zip}&weight=&aage=&countysearch=ALL&ogender=0&bgender=0&race=0&feet=0&inches=0&hcolor=0&ecolor=0&consearch=ALL"
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 17 state = KS (Kansas)
  #https://www.accesskansas.org/ssrv-registered-offender/index.do
  def self.search_user_state_17(user,agent)
    page = agent.get("https://www.accesskansas.org/ssrv-registered-offender/index.do")
    search_form = page.forms.with.name("nameForm").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.lastName =user.lastname
      search_form.firstName =user.firstname
      search_result =search_form.submit
      if search_result.links.size >21
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'KS'
        result.link =""
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 18 state = KY (Kentucky)
  # http://kspsor.state.ky.us/
  # page = agent.get("http://kspsor.state.ky.us/html/SORSearch.htm")
  def self.search_user_state_18(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 19 state = LA (Louisiana)
  # "http://www.lsp.org/socpr/disclaimer.html"
  # Search field: OfndrLast, OfndrFirst
  # More field : OfndrCity
  # Trang nay su dung frame cua page  http://www.icrimewatch.net
  def self.search_user_state_19(user,agent)
    page = agent.get("http://www.lsp.org/socpr/disclaimer.html")
    accept_form = page.forms.with.action("http://www.icrimewatch.net/louisiana.php").first
    page =accept_form.submit
    page = agent.get("http://www.icrimewatch.net/search2.php?AgencyID=54450")
    search_form = page.forms.first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.OfndrLast = user.lastname
      search_form.OfndrFirst = user.firstname
      if user.city?
        search_form.OfndrCity =user.city
      end
      search_result =search_form.submit(search_form.buttons.first)
      if search_result.links.size >17
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'LA'
        result.link ="http://www.icrimewatch.net/results.php?AgencyID=54450&SubmitNameSearch=1&OfndrCity=#{user.city}&OfndrLast=#{user.lastname}&OfndrFirst=#{user.firstname}"
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 20 state = ME (Maine)
  # http://sor.informe.org/sor/
  # search field: first_name, last_name
  # more field: zip, city
  def self.search_user_state_20(user,agent)
    page = agent.get("http://sor.informe.org/sor/")
    accept_form = page.forms.with.action("/cgi-bin/sor/step1.pl").first
    page =accept_form.submit
    search_form = page.forms.with.name("formtown").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.last_name = user.lastname
      search_form.first_name = user.firstname
      if user.city?
        search_form.city =user.city
      end
      if user.zip?
        search_form.zip =user.zip
      end
      search_result = search_form.submit
      if search_result.links.size >13
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'ME'
        result.link ="http://sor.informe.org/cgi-bin/sor/step2.pl?city=#{user.city}&search=3&zip=#{user.zip}&first_name=#{user.firstname}&last_name=#{user.lastname}&area=0&limiter="
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 21 state = MD (Maryland)
  # http://dpscs.md.gov/onlineservs/socem/portal.shtml
  # multi form
  def self.search_user_state_21(user,agent)
    page = agent.get("http://dpscs.md.gov/onlineservs/socem/portal.shtml")
    accept_form = page.forms.with.action("http://www.dpscs.state.md.us/sorSearch/").first
    unless accept_form == nil
      checkbox =accept_form.checkboxes.with.name("CHECKBOX_1").first
      checkbox.checked =true
      page = accept_form.submit
    end
    search_form = page.forms.with.name("lookUpForm").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.lastnm =user.lastname
      search_form.firstnm =user.firstname
      search_result = search_form.submit
      if search_result.links.size >24
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'MD'
        result.link ="http://www.dpscs.state.md.us/sorSearch/search.do?searchType=byName&anchor=offlist&firstnm=#{user.firstname}&lastnm=#{user.lastname}&category=ALL"
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id =22 state = MA (Massachusetts)
  # LastName, County , CityName
  def self.search_user_state_22(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end


  # id = 23 state = MI (Michigan)
  # http://www.mipsor.state.mi.us/
  # Nhan dang anh --> used http://www.familywatchdog.us/search.asp
  def self.search_user_state_23(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 24 state = MN (Minnesota)
  # https://por.state.mn.us/OffenderSearch.aspx
  # time out --> used http://www.familywatchdog.us/search.asp
  def self.search_user_state_24(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 25 state = MS (Missisippi)
  # http://www.sor.mdps.state.ms.us/sorpublic/hpsor_search.aspx
  # search field: txtFirstName, txtLastName
  # more field: txtZipCode,txtCity ddlCounty
  def self.search_user_state_25(user,agent)
    page = agent.get("http://www.sor.mdps.state.ms.us/sorpublic/hpsor_search.aspx")
    search_form = page.forms.with.name("Form1").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.txtLastName =user.lastname
      search_form.txtFirstName =user.firstname
      if user.city?
        search_form.txtCity =user.city
      end
      if user.zip?
        search_form.txtZipCode =user.zip
      end
     # if user.county?
     #   search_form.ddlCounty = user.county
     # end
      search_result = search_form.submit(search_form.buttons.first)
      if search_result.links.size >1
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'MS'
        result.link =""
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 26 state = M0 (Missouri)
  #http://www.mshp.dps.missouri.gov/MSHPWeb/PatrolDivisions/CRID/SOR/SORPage.html
  #http://www.mshp.dps.mo.gov/CJ38/search.jsp
  # search field: searchLast, searchFirst
  # More field: searchCity, searchZip, searchCounty
  def self.search_user_state_26(user,agent)
   # page = agent.get("http://www.mshp.dps.missouri.gov/MSHPWeb/PatrolDivisions/CRID/SOR/SORPage.html")
    page = agent.get("http://www.mshp.dps.mo.gov/CJ38/search.jsp")
    search_form = page.forms.with.name("searchForm").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.searchLast =user.lastname
      search_form.searchFirst =user.firstname
      if user.city?
        search_form.searchCity =user.city
      end
      if user.zip?
        search_form.searchZip =user.zip
      end
    #  if user.county?
    #    search_form.searchCounty = user.county
    #  end
      search_result = agent.submit(search_form)
      if search_result.links.size >12
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'MO'
        result.link =""
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 27 state = MT (Montana)
  # http://doj.mt.gov/svor/search.asp
  # Search field: NameLast
  # more field: County, City, Zip
  def self.search_user_state_27(user,agent)
    page = agent.get("http://doj.mt.gov/svor/search.asp")
    search_form = page.forms.with.name("frmSearch").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.NameLast =user.lastname
      if user.city?
        search_form.City =user.city
      end
      if user.zip?
        search_form.Zip =user.zip
      end
    #  if user.county?
    #    search_form.County =user.county
    #  end
      search_result = agent.submit(search_form)
      if search_result.links.size >92
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'MT'
        result.link ="http://doj.mt.gov/svor/searchlist.asp?County=&City=#{user.city}&Zip=#{user.zip}&NameLast=#{user.lastname}&OffenderType="
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 28 state = NE (Nebraska)
  # http://www.nsp.state.ne.us/sor/find.cfm
  # Search field: LNAME, FNAME
  # More field: COUNTY, ZIP, CITY
  def self.search_user_state_28(user,agent)
    page = agent.get("http://www.nsp.state.ne.us/sor/find.cfm")
    search_form = page.forms.with.name("search").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.LNAME =user.lastname
      search_form.FNAME =user.firstname
      if user.city?
        search_form.CITY =user.city
      end
      if user.zip?
        search_form.ZIP =user.zip
      end
    #  if user.county?
    #    search_form.COUNTY =user.county
    #  end
      search_result = search_form.submit(search_form.buttons.first)
      if search_result.links.size >17
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'NE'
        result.link ="http://www.nsp.state.ne.us/sor/SearchAction.cfm?LNAME=#{user.lastname}&CITY=#{user.city}&FNAME=#{user.firstname}&COUNTY=&SORT=Name&ZIP=#{user.zip}&PICS=on"
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 29 state = NV (Nevada)
  # http://www.nvsexoffenders.gov/Search.aspx
  # Search field: TextBoxFirstName, TextBoxLastName
  # More field: TextBoxCity,TextBoxZipCode
  def self.search_user_state_29(user,agent)
    page = agent.get("http://www.nvsexoffenders.gov/Search.aspx")
    search_form = page.forms.with.name("SearchForm").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.TextBoxLastName =user.lastname
      search_form.TextBoxFirstName =user.firstname
      if user.city?
        search_form.TextBoxCity =user.city
      end
      if user.zip?
        search_form.TextBoxZipCode =user.zip
      end
     # if user.county?
     #   search_form.COUNTY = user.county
     # end
      search_result = search_form.submit(search_form.buttons.first)
      if search_result.title == "State of Nevada Sexual Offenders Search Result Page"
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'NV'
        result.link =""
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 30 state = NH (New Hampshire)
  # http://www.oit.nh.gov/nsor/search.asp
  # page load error: network timeout --> used http://www.familywatchdog.us/search.asp
  def self.search_user_state_30(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

   # id =31 , state NJ (New Jersey)
   # search field: lnme, fnme
   # multi form
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
      search_result = agent.submit(search_form)
      if search_result.links.size >49
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'NJ'
        result.link ="N/A"
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 32 state = NM (New Mexico)
  # http://www.nmsexoffender.dps.state.nm.us/fname.html
  # Search field: lname_txt
  # multi form
  def self.search_user_state_32(user,agent)
    page = agent.get("http://www.nmsexoffender.dps.state.nm.us/fname.html")
    search_form = page.forms.with.name("form3").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.lname_txt =user.lastname.upcase
      search_result = search_form.submit(search_form.buttons.first)
      if search_result.links.size >0
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'NV'
        result.link ="http://www.nmsexoffender.dps.state.nm.us/servlet/fname_serv.class?lname_txt=#{user.lastname.upcase}"
        result.html_content =search_result.body
        result.save
      end
    end
  end

   # id =33 , state NY (New York)
   # Search field: LastName
   # More field: County, Zip
  def self.search_user_state_33(user,agent)
    page = agent.get("http://www.criminaljustice.state.ny.us/nsor/search_index.htm")
    search_form = page.forms.with.action("/cgi/internet/nsor/fortecgi").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.LastName =user.lastname
      if user.zip?
         search_form.County =user.zip
      end
     # if user.county?
     #   search_form.County =user.county
     # end
      search_result = agent.submit(search_form)
      if search_result.links.size >1
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'NY'
        result.link ="http://www.criminaljustice.state.ny.us/cgi/internet/nsor/fortecgi?ServiceName=WebNSOR&TemplateName=results.htm&RequestingHandler=WebNSORSearchResultsHandler&LastName=#{user.lastname}&Zip=#{user.zip}&reset=Clear&County=+"
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 34 state = NC (North Carolina)
  # http://ncfindoffender.com/disclaimer.aspx
  # search field: fname, lname
  # more field zip,city, county
  def self.search_user_state_34(user,agent)
    page = agent.get("http://ncfindoffender.com/disclaimer.aspx")
    accept_form = page.forms.with.name("Form2").first
    unless accept_form == nil
      page =accept_form.submit(accept_form.buttons.first)
    end
    search_form = page.forms.with.name("Form1").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.lname =user.lastname
      search_form.fname =user.firstname
      if user.city?
        search_form.city =user.city
      end
      if user.zip?
        search_form.zip =user.zip
      end
     # if user.county?
     #   search_form.county=user.county
     # end
      search_result = search_form.submit(search_form.buttons.with.name("searchbutton1").first)
      if search_result.links.size >20
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'NC'
        result.link =""
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 35 state = ND (North Dakota)
  # http://www.sexoffender.nd.gov/
  # http://www.sexoffender.nd.gov/offdisclaimer.aspx
  def self.search_user_state_35(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 36 state = OH (Ohio)
  # http://www.esorn.ag.state.oh.us/Secured/p21_2.aspx
  # Search field: txtLastName,txtFirstName
  # More field: txtZip, cboCounty
  def self.search_user_state_36(user,agent)
    page = agent.get("http://www.esorn.ag.state.oh.us/Secured/p21_2.aspx")
    search_form = page.forms.with.name("frmOffenderSearch").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.txtLastName =user.lastname
      search_form.txtFirstName =user.firstname
      if user.zip?
        search_form.txtZip =user.zip
      end
     # if user.county?
     #   search_form.cboCounty =user.county
     # end
      search_result = search_form.submit(search_form.buttons.first)
      if search_result.links.size >38
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'OH'
        result.link =""
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 37 state = OK (Oklahoma)
  # http://docapp8.doc.state.ok.us/servlet/page?_pageid=190&_dad=portal30&_schema=PORTAL30
  # Search field: first_name, last_name
  # More field: county, zip, city
  # Khong submit duoc ket qua search, chua ro ly do"WWW::Mechanize::ResponseCodeError: 404 => Net::HTTPNotFound" nhung lam ngoai web ra

  def self.search_user_state_37(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 38 state = OR (Oregon)
  # http://sexoffenders.oregon.gov/
  # Search field: LAST, FIRST
  # More field: COUNTY, CITY, ZIP
  def self.search_user_state_38(user,agent)
    page = agent.get("http://sexoffenders.oregon.gov/")
    accept_form = page.forms.with.name("myform").first
    unless accept_form == nil
      page =accept_form.submit(accept_form.buttons.first)
    end
    search_form = page.forms.with.action("/SorPublic/Web.dll/main").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.LAST =user.lastname
      search_form.FIRST =user.firstname
      if user.city?
        search_form.CITY =user.city
      end
      if user.zip?
        search_form.ZIP =user.zip
      end
     # if user.county?
     #   search_form.COUNTY=user.county
     # end
      search_result = search_form.submit(search_form.buttons.with.name("SEND").first)
      if search_result.links.size >12
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'OR'
        result.link =""
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 39 state = PA (Pennsylvania)
  # http://www.pameganslaw.state.pa.us/
  # Search field: txtFirstName, txtLastName
  # multiform
  # Khong submit vao trang trong duoc, chua ro ly do
  def self.search_user_state_39(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 40 state = RI (Rhode Island)
  # http://www.paroleboard.ri.gov/sexoffender/agree.php
  # trang nay chi search theo location khong co search theo name
  def self.search_user_state_40(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 41 state = SC (South Carolina)
  # http://services.sled.sc.gov/sor/search.aspx?Type=Name
  # Note: Name search is a SOUNDEx ("sounds like") search on both name and alias. --> khong dung duoc
  # txt_name
  # multi form
  def self.search_user_state_41(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 42 state = SD (South Dakota)
  # http://sor.sd.gov/disclaimer.asp?page=search&nav=2
  # seach field: lname, fname
  # More field: county, city, zipcode
  def self.search_user_state_42(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 43 state = TN (Tennessee)
  # http://www.ticic.state.tn.us/sorinternet/sosearch.aspx
  # Search field: txtLastName, txtFirstName
  # More field: txtcity, txtZip, ddlCounty
  def self.search_user_state_43(user,agent)
    page = agent.get("http://www.ticic.state.tn.us/sorinternet/sosearch.aspx")
    search_form = page.forms.with.name("Form2").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.txtLastName =user.lastname
      search_form.txtFirstName =user.firstname
      if user.city?
        search_form.txtcity =user.city
      end
      if user.zip?
        search_form.txtZip =user.zip
      end
     # if user.county?
     #   search_form.ddlCounty =user.county
     # end
      button=search_form.buttons.with.name("btnFind").first
      search_result =search_form.submit(button)
      if search_result.links.size >4
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'TN'
        result.link =""
        result.html_content =search_result.body
        result.save
      end
    end
  end

  # id = 44 state = TX (Texas)
  # https://records.txdps.state.tx.us/DPS_WEB/SorNew/PublicSite/index.aspx?SearchType=Name
  # Search field: CurrentDPStemplateBase$ctl06$ctl00$txtLNA_TXT,CurrentDPStemplateBase$ctl06$ctl00$txtFNA_TXT
  # More filed: CurrentDPStemplateBase$ctl06$ctl00$ddlCounty (county)
  # multi form
  def self.search_user_state_44(user,agent)
    page = agent.get("https://records.txdps.state.tx.us/DPS_WEB/SorNew/PublicSite/index.aspx?SearchType=Name")
    accept_link = page.links.text("I have read the Web Site Caveats and agree to the terms ")
    unless accept_link.nil?
      page = agent.click(accept_link)
    end
    search_form =  page.forms.with.name("aspnetForm").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.field("CurrentDPStemplateBase$ctl06$ctl00$txtLNA_TXT").value =user.lastname
      search_form.field("CurrentDPStemplateBase$ctl06$ctl00$txtFNA_TXT").value =user.firstname
     # if user.county?
     #   search_form.field("CurrentDPStemplateBase$ctl06$ctl00$ddlCounty").value=user.county
     # end
      button = search_form.buttons.first
      search_result = search_form.click_button(button)
      if search_result.links.size >15
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'TX'
        result.link =""
        result.html_content=search_result.body
        result.save
      end
    end
  end

  # id = 45 state = UT (Utah)
  # http://corrections.utah.gov/asp-bin/sonar.asp
  # http://www.communitynotification.com/cap_office_disclaimer.php?office=54438
  # multi form
  #Trang nay su dung frame cua page  http://www.icrimewatch.net
  def self.search_user_state_45(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 46 state = VT (Vermont)
  # http://170.222.137.2:8080/sor/
  # lastname or county
  def self.search_user_state_46(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 47 state = VA (Virginia)
  # http://sex-offender.vsp.virginia.gov/sor/policy.html?original_requestUrl=http%3A%2F%2Fsex-offender.vsp.virginia.gov%3A80%2Fsor%2FzipSearch.html&original_request_method=GET&original_request_parameters=
  # Nhan dang hinh
  def self.search_user_state_47(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 48 state = WA (Washington)
  # http://ml.waspc.org/Accept.aspx?ReturnUrl=/index.aspx
  # The page cannot be displayed
  def self.search_user_state_48(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 49 state = WV (West Virginia)
  # http://www.wvstatepolice.com/sexoff/mainsearch_r07.cfm
  # Khong ro nguyen nhan nhung submit accpet thi nhay sang index chu khong phai search form
  def self.search_user_state_49(user,agent)
    self.search_user_in_family_watchdog(user,agent)
  end

  # id = 50 state = WI (Wisconsin)
  # http://offender.doc.state.wi.us/public/search/searchbyname.jsp
  # multi form
  # last_name, first_name
  def self.search_user_state_50(user,agent)
    page = agent.get("http://offender.doc.state.wi.us/public/search/searchbyname.jsp")
    search_form = page.forms.with.action("sor").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.last_name =user.lastname
      search_form.first_name =user.firstname
      accept_page =search_form.submit
      accept_form = accept_page.forms.first
      search_result =accept_form.submit
      if search_result.links.size >21
        result = SorSearchLog.create(:lastname => user.lastname, :firstname => user.firstname, :user_id =>user.id,
                                  :state_name => 'WI', :link => "" , :html_content =>search_result.body)
      end
    end
  end

  # id = 51 state = WY (Wyoming)
  # http://wysors.dci.wyo.gov/
  # Search field: lnm
  # more field: cty, cnt
  def self.search_user_state_51(user,agent)
    page = agent.get("http://wysors.dci.wyo.gov/")
    accept_form = page.forms.with.name("df").first
    unless accept_form == nil
      checkbox =accept_form.checkboxes.with.name("acknowledge").first
      checkbox.checked =true
      page = accept_form.submit
      page = agent.get("http://wysors.dci.wyo.gov/sor/search_regnam.htm")
    end
     search_form =  page.forms.with.name("searchform").first
     if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.lnm =user.lastname
      if user.city?
        search_form.cty =user.city
      end
     # if user.county?
     #   search_form.cnt=user.county
     # end
      search_result = search_form.submit
      if search_result.links.size >26
        result = SorSearchLog.new
        result.lastname = user.lastname
        result.firstname = user.firstname
        result.user_id =user.id
        result.state_name = 'WY'
        result.link =""
        result.html_content =search_result.body
        result.save
      end
    end
  end

  def self.search_user_in_family_watchdog(user,agent)
    page = agent.get("http://www.familywatchdog.us/search.asp")
    search_form = page.forms.with.name("form2").first
    if search_form == nil
      logger.info "The page site is not available at the moment!!!"
    else
      search_form.txtLastName =user.lastname
      search_form.txtFirstName =user.firstname
      state =State.find(user.state_id).name
      search_form.txtState = state
      search_result =search_form.submit
      if search_result.links.size >20
        result = SorSearchLog.create(:lastname => user.lastname, :firstname => user.firstname, :user_id =>user.id,
                                  :state_name => state, :link => "", :html_content =>search_result.body)
      end
    end
  end

  def self.time_diff_in_days(time = Time.now)
    ((Time.now - time).round)/SECONDS_PER_DAY
  end

  def self.find_memberships_to_bill_next_day
    users = []
    mships = Membership.active.find(:all, :conditions => ['billing_method = ? and cost > 0', Membership::CREDIT_CARD_BILLING_METHOD])
    mships.each {|m|
      users << m.user if (m.last_billed.nil? || (time_diff_in_days(m.last_billed) >= PAYMENT_DUE_CYCLE - 1))
    }
    users
  end
end
