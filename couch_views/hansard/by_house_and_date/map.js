function(doc) {
	if(doc.type == 'hansard' || doc.type == 'speech' || doc.type == 'minor-heading' || doc.type == 'major-heading')
		emit([doc.house,doc.date],doc._rev)
}
