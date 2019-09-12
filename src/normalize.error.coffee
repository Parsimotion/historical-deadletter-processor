_ = require "lodash"

module.exports = (err, propertiesToOmit = 'auth') ->
  error: JSON.stringify(_.omit err, 'detail.request')
  request: JSON.stringify(_.omit _.get(err, 'detail.request'), propertiesToOmit)
  type: _.get(err, "type") || "unknown_error"