function(doc) {
	if(doc.type == 'person' 
      || doc.type == 'person-position' 
      || doc.type == 'person-period'
      || doc.type == 'constituency') {
		emit(doc._id,doc._rev)
	}
}
