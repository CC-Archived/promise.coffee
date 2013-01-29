var Deferred = require('../promise').Deferred;

exports.pending = function () {
	var deferred = new Deferred();
	return {
		promise: deferred.promise,
		fulfill: deferred.resolve,
		reject: deferred.reject
	};
};