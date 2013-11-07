var Deferred = require('../promise').Deferred;

exports.deferred = function () { return new Deferred(); };
exports.resolved = Deferred.resolve;
exports.rejected = Deferred.reject;