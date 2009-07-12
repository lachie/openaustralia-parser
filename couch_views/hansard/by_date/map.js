function(doc) {
	if(doc['type']=='hansard')
		emit([doc['date'],doc.house],doc._id)
}
