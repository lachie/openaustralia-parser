function(doc) {
  if(doc.type == 'person-period') {
    var current = (doc.exit_date.toString()=='9999/12/31');
    emit([doc.person,doc.entry_date,doc.exit_date,current],null);
  }
}
