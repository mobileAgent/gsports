

gs.inplace = {}


gs.inplace.edit = function(editor_id) {
  inplace = $(editor_id);
  status = inplace.readAttribute('status');

  switch(status){
    case 'v':
      inplace.writeAttribute('status', 'x');
      inplace.select('.target')[0].hide();
      inplace.select('.editor')[0].show();
      break;
    case 'x':
      inplace.writeAttribute('status', 'v');
      inplace.select('.target')[0].show();
      inplace.select('.editor')[0].hide();
      break;
   }
}


gs.inplace.close = function(editor_id) {
  inplace = $(editor_id);
  status = inplace.readAttribute('status');

      inplace.writeAttribute('status', 'v');
      inplace.select('.target')[0].show();
      inplace.select('.editor')[0].hide();
      
}


gs.inplace.submit = function(editor_id){
    
  inplace = $(editor_id);
  submit = inplace.select('input[type=submit]')[0]
  url = inplace.readAttribute('inplace_url');
  form = $(editor_id+'_form')

  submit.value = 'Saving'
  submit.disabled = true

  new Ajax.Request(url, {
    method: 'post',
    parameters:   form.serialize(true),
    onSuccess: function(transport) {
      attr_name = inplace.readAttribute('attr_name');
      flashnow(attr_name+' updated.')

      input = $(editor_id+'_input')
      value = '/'
      switch(input.type){
        case 'select-one':
          value = input.options[input.selectedIndex].text
          break;
        default:
          //$(editor_id+'_target').update( $(editor_id+'_input').value )
          //inplace.select('.target')[0].update( $(editor_id+'_input').value )
          value = $(editor_id+'_input').value
      }
      inplace.select('.target')[0].update( value )

      gs.inplace.close(editor_id)
      
      submit.value = 'Save'
      submit.disabled = false
    },
    onFailure: function(transport) {
      var response = transport.responseText || "no response text";
      flasherror('Error submitting field: '+response);

      submit.value = 'Save'
      submit.disabled = false
    }

  });

}


