function(newDoc, oldDoc, userCtx) {
	if (userCtx.name != 'oa') {
		throw {forbidden: "Documents must only be edited by the OA importer."};
	}
	//if (oldDoc && oldDoc.author && oldDoc.author != userCtx.name) {
	//	throw {unauthorized:"You are not the author of this document."};
	//}
}
