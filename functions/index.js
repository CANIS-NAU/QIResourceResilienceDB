const api = require("./api");
const archiveEvents = require("./archive-events");
const { initializeApp } = require("firebase-admin/app");

initializeApp();

exports.rrdbApi = api.api;
exports.rrdbArchiveEvents = archiveEvents.archiveEvents;
