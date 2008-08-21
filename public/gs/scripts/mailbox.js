/* select the appropriate account type radio button when the account type's block is selected */
function selectThisMessage(o) {
    var target = o.parentNode.parentNode;
    if (target.className == "mailItem") {
        target.className = "mailItemSelected";
    } else {
        target.className = "mailItem";
    }
    return false;
}