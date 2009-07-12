function(doc) {
  if(doc['hansard-tree']) {
    if(doc['path'])
      emit(doc['path'],doc['title'])

    else
      emit([],null)
  }
}
