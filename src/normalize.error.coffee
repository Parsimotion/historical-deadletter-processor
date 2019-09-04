_ = require "lodash"

module.exports = (err, propertiesToOmit = ['detail.request.auth']) ->
  error: JSON.stringify(_.omit(err, propertiesToOmit))
  type: _.get(err, "message") || "unknown_error"