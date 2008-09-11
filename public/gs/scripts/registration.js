/* update the GUI when a new account type is selected during registration */
function clearAllAccounts() {
   var target =  $$(".SelectedAccount")
   for (var i=0; i<target.length; i++) {
     target[i].className = 'UnSelectedAccount'
   }
}

/* element is supposed to be the radio button */
function updateSelectedAccount(el) {
   clearAllAccounts();
   el.parentNode.parentNode.className = "SelectedAccount";
}
/* rid is the id of the radio button */
function selectThisAccount(rid) {
    updateSelectedAccount($(rid))
    $(rid).checked = true
    return false;
}