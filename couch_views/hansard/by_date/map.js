function(doc) {
	if(doc['type']=='hansard')
		emit(doc['date'],doc)
}
