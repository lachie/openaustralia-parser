function(doc) {
  if(doc['hansard-tree']) {
    if(doc['path'])

      if(doc['type'] == 'speech')
        emit(doc['path'],'Speech by '+doc['speaker'])
      else
        emit(doc['path'],(doc['title'] || ''))

    else
      emit([],null)
  }
}
