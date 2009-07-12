function(doc) {
  if(doc.current_constituencies)  {
    for(i=0; i<doc.current_constituencies.length; i++) {
      var cc = doc.current_constituencies[i];
      emit(cc.constituency, doc);
    }
  }
}
