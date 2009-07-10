function(doc) {
	if(doc.type == 'person')
		emit(doc.name.last, doc)
}
