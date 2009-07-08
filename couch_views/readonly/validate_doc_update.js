function(newDoc, oldDoc, userCtx) {
	if (userCtx.name != 'lachie') {
		throw {forbidden: "Documents must only be edited by lachie."};
	}
	if (oldDoc && oldDoc.author && oldDoc.author != userCtx.name) {
		throw {unauthorized:"You are not the author of this document."};
	}
}
