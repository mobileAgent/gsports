function profile_minimize(o) {
	if (o.isMinimized == true) {
		o.innerHTML = "minimize -";
		o.isMinimized = false;
	} else {
		o.innerHTML = "maximize +";
		o.isMinimized = true;
	}
	var target = o.parentNode.parentNode;
	while (target) {
		if (target.className && (target.className.indexOf("contentBoxHeader") < 0)) {
			if (o.isMinimized == true) {
				target.oldDisplay = target.style.display;
				target.style.display = "none";
			} else {
				target.style.display = target.oldDisplay;
			}
		}
		target = target.nextSibling;
	}
}
