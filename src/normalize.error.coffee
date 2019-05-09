_ = require "lodash"

module.exports = (err) ->
  error: JSON.stringify(err)
  type: _.get(err, "message") || "unknown_error"