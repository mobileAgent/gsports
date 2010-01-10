// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


  // modeled after: # For rjs pages to tickle the flash on the current page
  function flashnow(msg) {
    $('flash_notice').select('span')[0].replace("<span>"+msg+"</span>")
    $('flash_notice').show()
  }
