_ = require "lodash"
Promise = require "bluebird"
highland = require "highland"
azureTable = require "azure-table-node"
HighlandPagination  = require "highland-pagination"

module.exports =
  class HistoricalDeadletterProcessor

    constructor: (
        @processor,
        { connection, @tableName, @partitionKey },
        @concurrency = { callsToApi: 20, callsToProcessor: 50 }
        , @logger = console
      ) -> @client = Promise.promisifyAll azureTable.createClient(connection), multiArgs: true

    run: =>
      new HighlandPagination @_retrieveMessages
        .stream()
        .map (row) -> _.update row, "notification", JSON.parse
        .map (row) =>
          { RowKey } = row
          @_doProcess row
          .tap -> @logger.info "Process successful #{RowKey}"
          .map(-> row)
          .errors => @logger.warn "Still fails #{RowKey}"
        .parallel @concurrency.callsToApi
        .map (row) => @_remove row
        .parallel @concurrency.callsToProcessor
        .collect()
        .toPromise(Promise)

    _retrieveMessages: (continuation) =>
      @client.queryEntitiesAsync(@tableName, {
        query: "PartitionKey eq '#{@partitionKey}'"
        limitTo: 20
        continuation
      })
      .spread (items, nextToken) => { items, nextToken }

    _doProcess: ({ notification }) =>
      @logger.info "Processing", { notification }
      highland @processor notification

    _remove: ({ PartitionKey, RowKey, __etag }) =>
      highland @client.deleteEntityAsync @tableName, { PartitionKey, RowKey, __etag }
