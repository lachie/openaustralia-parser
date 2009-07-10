function(doc) {
  if(doc.type == 'constituency') {
    for(i=0; i<doc.postcodes.length; i++) {
      emit(doc.postcodes[i],{
          name: doc.name,
          state: doc.state
      })
    }
  }
}
