/* update the GUI when a new account type is selected during registration */
function updateSelectedAccount(o) {
	var target = o.parentNode.parentNode.parentNode.firstChild;
	while (target) {
        if (target.className == "SelectedAccount") target.className = "UnSelectedAccount";
        target = target.nextSibling;
    }
    o.parentNode.parentNode.className = "SelectedAccount";
} //updateSelectedAccount

/* select the appropriate account type radio button when the account type's block is selected */
function selectThisAcocunt(o) {
    var target = o.parentNode.parentNode.firstChild;
    while (target) {
        if (target.className == "AccountRadio") {
            var target2 = target.firstChild;
            while (target2) {
                if (target2.nodeName.toLowerCase() == "input") {
                    target2.checked = true;
                    updateSelectedAccount(target2);
                }
                target2 = target2.nextSibling;
            }
        }
        target = target.nextSibling;
    }
    return false;
}