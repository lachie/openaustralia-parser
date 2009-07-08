function(doc) {
	if(doc['type'] == 'major-heading' || doc['type'] == 'minor-heading')
		emit(doc['date'],doc)
}
