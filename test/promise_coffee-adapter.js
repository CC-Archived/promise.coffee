var Deferred = require('../promise').Deferred;

exports.deferred = function () {
	return new Deferred();
};