function(doc) {
	if(doc.type == 'hansard' || doc.type == 'speech')
		emit(doc._id,doc._rev)
}
