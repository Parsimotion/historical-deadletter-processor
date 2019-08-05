_ = require "lodash"
Promise = require "bluebird"
highland = require "highland"
AzureSearch = require "azure-search"
HighlandPagination  = require "highland-pagination"
moment = require "moment"
debug = require("debug")("historical-deadletter:cleanup")

require "highland-concurrent-flatmap"

moment = require "moment"
AbstractReaderProcessor = require "./abstract.reader.processor"

module.exports =
  class CleanupProcessor extends AbstractReaderProcessor

    constructor: (opts) ->
      super opts
      { @days = 30 } = opts

    _stream_: (stream) -> stream

    _filter_: (page = 0) =>
      nDaysAgo = "#{ moment().subtract(@days, 'days').startOf('day').utc().format("YYYY-MM-DDTHH:mm:ss") }z"
      "timestamp lt #{ nDaysAgo }"
        
