
var Tabs = {
	current: 1,
	open: function(id){
		$('tabBody'+this.current).hide()
		$('tabBody'+id).show()

		$('tab'+this.current).removeClassName('open')
		$('tab'+id).addClassName('open')

		this.current = id
	}
	
}

