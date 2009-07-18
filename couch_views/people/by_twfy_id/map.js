function(doc) {
  if(doc.type == 'person')
    emit(doc.twfy_id,null)
}
