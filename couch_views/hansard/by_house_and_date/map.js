function(doc) {
	if(doc.type == 'hansard' || doc.type == 'speech')
		emit([doc.house,doc.date],doc)
}
