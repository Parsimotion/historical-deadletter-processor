_ = require "lodash"
Promise = require "bluebird"
highland = require "highland"
AzureSearch = require "azure-search"
HighlandPagination  = require "highland-pagination"
require "highland-concurrent-flatmap"

module.exports = 
class AbstractReaderProcessor

    constructor: ({
      connection
      @logger = console
      @index = "errors"
      @sizePage = 100
    }) ->
      @client = @_buildClient connection
      @debug = require("debug") "historical-deadletter:#{ this.constructor.name }"

    run: =>
      new HighlandPagination(@_retrieveNotifications).stream()
      .through (s) => @_action_ s
      .batch 20
      .concurrentFlatMap 10, (rows) => @_remove rows
      .reduce(0, (accum) -> accum + 1)
      .toPromise(Promise)
      .tap (i) => @debug "Done process. #{i} processed"

    _action_: -> throw new Error "_action_ subclass responsibility"
    _filter_: -> throw new Error "_filter_ subclass responsibility"

    _retrieveNotifications: (page = 0) =>
      queryOptions = @_queryOptions_ page

      @debug "Searching errors %o", queryOptions 
      @client.searchAsync @index, queryOptions
      .spread (items) => { items, nextToken: if items?.length is @sizePage then page + 1 }

    _queryOptions_: (page) => 
      {
        filter: @_filter_ page
        skip: page * @sizePage
        top: @sizePage
      }

    _buildClient: ({ url, key }) ->
      Promise.promisifyAll new AzureSearch({ url, key }), { multiArgs: true }

    _remove: (rows) =>
      ids = _.map rows, ({ id }) -> { id }  
      @debug "Removing documents #{ _.map(ids, "id") } in #{ @index }"
      highland @client.deleteDocumentsAsync @index, ids
