const handleWebSignUpRole = require("./handle-web-signup-role");
const archiveEvents = require("./archive-events");

exports.handleWebSignUpRole = handleWebSignUpRole.handleWebSignUpRole;
exports.getUsers = handleWebSignUpRole.getUsers;
exports.updateAccountStatus = handleWebSignUpRole.updateAccountStatus;
exports.archiveEvents = archiveEvents.archiveEvents;
