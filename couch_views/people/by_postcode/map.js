function(doc) {
  if(doc.type == 'person' && doc.current_constituencies) {
    for(i=0; i<doc.current_constituencies.length; i++) {
      var cc = doc.current_constituencies[i];
      emit([cc.constituency,0], doc);
    }
  } else if(doc.type == 'constituency') {
    for(i=0; i<doc.postcodes.length; i++) {
      emit([doc._id,1],{
          postcode: doc.postcodes[i],
          name: doc.name,
          state: doc.state
      })
    }
  }
}
