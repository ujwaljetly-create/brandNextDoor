const existing = require('./index');
const orders = require('./orders');
module.exports = { ...existing, ...orders };
