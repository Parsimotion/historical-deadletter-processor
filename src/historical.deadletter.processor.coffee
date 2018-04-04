_ = require "lodash"
Promise = require "bluebird"
highland = require "highland"
{ parseAccountString, createClient, Query } = require "azure-table-node"
HighlandPagination  = require "highland-pagination"
moment = require "moment"

module.exports =
  class HistoricalDeadletterProcessor

    constructor: (
        @processor,
        { connection, @tableName, @partitionKey },
        @concurrency = { callsToApi: 20, callsToAzure: 50 },
        @logger = console
        @daysRetrying = 1
      ) ->
        connection = parseAccountString connection if _.isString connection
        @client = Promise.promisifyAll createClient(connection), multiArgs: true

    run: =>
      new HighlandPagination @_retrieveMessages
        .stream()
        .map (row) -> _.update row, "notification", JSON.parse
        .map (row) =>
          { RowKey } = row
          @_doProcess row
          .tap => @logger.info "Process successful #{RowKey}"
          .map(-> row)
          .errors => @logger.warn "Still fails #{RowKey}"
        .parallel @concurrency.callsToApi
        .map (row) => @_remove row
        .parallel @concurrency.callsToAzure
        .collect()
        .toPromise(Promise)

    _retrieveMessages: (continuation) =>
      query = Query.create()
        .where "PartitionKey", "==", "#{@partitionKey}"
        .and "Timestamp", ">", moment().subtract(@daysRetrying, 'days').toDate()

      @client.queryEntitiesAsync(@tableName, {
        query
        limitTo: 20
        continuation
      })
      .spread (items, nextToken) => { items, nextToken }

    _doProcess: (row) =>
      highland (push, next) =>
        __done = (err) ->
          push err, null
          push null, highland.nil

        @processor { done: __done, log: @logger }, row

    _remove: ({ PartitionKey, RowKey, __etag }) =>
      highland @client.deleteEntityAsync @tableName, { PartitionKey, RowKey, __etag }
