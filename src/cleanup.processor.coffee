_ = require "lodash"
Promise = require "bluebird"
highland = require "highland"
AzureSearch = require "azure-search"
HighlandPagination  = require "highland-pagination"
moment = require "moment"
debug = require("debug")("historical-deadletter:cleanup")

require "highland-concurrent-flatmap"

SIZE_PAGE = 100

module.exports =
  class CleanupProcessor

    constructor: ({
        connection
        @days = 30
        @logger = console
      }) ->
        @client = @_buildClient connection

    run: =>
      new HighlandPagination @_retrieveOldNotifications
        .stream()
        .concurrentFlatMap @concurrency.callsToAzure, (row) => @_remove row
        .reduce(0, (accum) -> accum + 1)
        .toPromise(Promise)
        .tap => debug "Done process"

    _retrieveOldNotifications: (page = 0) =>
      nDaysAgo = "#{ moment().subtract(@days, 'days').startOf('day').utc().format("YYYY-MM-DDTHH:mm:ss") }z"
      queryOptions =
        filter: "timestamp lt #{ nDaysAgo }"
        skip: page * SIZE_PAGE
        top: SIZE_PAGE

      debug "Searching errors %o", queryOptions 
      @client.searchAsync @index, queryOptions
      .spread (items) -> { items, nextToken: if items?.length is SIZE_PAGE then page + 1 }

    _remove: ({ id }) =>
      debug "Deleting document #{ id }"
      highland @client.deleteDocumentsAsync @index, [ { id } ]

    _buildClient: ({ url, key }) ->
      Promise.promisifyAll new AzureSearch({ url, key }), { multiArgs: true }
