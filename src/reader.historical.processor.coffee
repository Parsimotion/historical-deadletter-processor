_ = require "lodash"
Promise = require "bluebird"
highland = require "highland"
AzureSearch = require "azure-search"
HighlandPagination  = require "highland-pagination"
moment = require "moment"
debug = require("debug")("historical-deadletter:reader")

require "highland-concurrent-flatmap"

SIZE_PAGE = 100

module.exports =
  class ReaderHistoricalProcessor

    constructor: ({
        @processor
        connection
        @app
        @job
        @concurrency = { callsToApi: 20, callsToAzure: 50 },
        @daysRetrying = 1
        @index = "errors"
        @extraFilters = []
        @logger = console
      }) ->
        @client = @_buildClient connection

    run: =>
      new HighlandPagination @_retrieveFailedNotifications
        .stream()
        .map (row) -> _.update row, "notification", JSON.parse
        .concurrentFlatMap @concurrency.callsToApi, (row) =>
          @_doProcess row
          .map -> row
          .errors => debug "Still fails #{row.resource}"
        .tap (row) => debug "Process successful #{row.resource}"
        .concurrentFlatMap @concurrency.callsToAzure, (row) => @_remove row
        .reduce(0, (accum) -> accum + 1)
        .toPromise(Promise)
        .tap => debug "Done process"

    _retrieveFailedNotifications: (page = 0) =>
      nDaysAgo = "#{ moment().subtract(@daysRetrying, 'days').utc().format("YYYY-MM-DDTHH:mm:ss") }z"
      
      query = _.concat([
        "app eq '#{ @app }'"
        "job eq '#{ @job }'"
        "timestamp gt #{ nDaysAgo }"
      ], @extraFilters).join(" and ")

      queryOptions =
        filter: query
        skip: page * SIZE_PAGE
        top: SIZE_PAGE

      debug "Searching errors %o", queryOptions 
      @client.searchAsync @index, queryOptions
      .spread (items) -> { items, nextToken: if items?.length is SIZE_PAGE then page + 1 }

    _doProcess: (row) =>
      highland (push, next) =>
        __done = (err) ->
          push err, null
          push null, highland.nil

        @processor { done: __done, log: @logger }, row

    _remove: ({ id }) =>
      highland @client.deleteDocumentsAsync @index, [ { id } ]

    _buildClient: ({ url, key }) ->
      Promise.promisifyAll new AzureSearch({ url, key }), { multiArgs: true }
