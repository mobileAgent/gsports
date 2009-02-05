
function channelsUpdateRowCol(target) {
	if(target.value < 2){
		$('ThumbCount').update('Cols')
		$('ThumbSpan').update('Per Col')
	}else{
		$('ThumbCount').update('Rows')
		$('ThumbSpan').update('Per Row')
	}
	return false;
}