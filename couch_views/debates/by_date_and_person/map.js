function(doc) {
  if(doc.type == 'speech') {
    emit([doc.speaker, doc.date],doc._id)
  }
}
