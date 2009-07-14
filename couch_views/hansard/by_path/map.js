function(doc) {
  if(doc['hansard-tree']) {
    var key = [doc['date'], doc['house']];

    if(doc['path']) {
      for(elt in doc['path'])
        key.push(doc['path'][elt]);

      if(doc['type'] == 'speech') {
        if(doc['unknown-speaker']) {
          emit(key, 'Speech by unknown speaker');

        } else {
          var spkr = doc['speaker_name']
          var name = ''+spkr['first']+' '+spkr['last'];
          emit(key, 'Speech by '+name);

        }
      } else
        emit(key, (doc['title'] || ''));

    } else {
      emit(key,null)
    }
  }
}
