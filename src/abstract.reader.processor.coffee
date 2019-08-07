_ = require "lodash"
Promise = require "bluebird"
highland = require "highland"
AzureSearch = require "azure-search"
HighlandPagination  = require "highland-pagination"
require "highland-concurrent-flatmap"

SIZE_PAGE = 100

module.exports = 
class AbstractReaderProcessor

    constructor: ({
      connection
      @logger = console
      @concurrency = { callsToApi: 20 }
      @index = "errors"
    }) ->
      @client = @_buildClient connection
      @debug = require("debug") "historical-deadletter:#{ this.constructor.name }"

    run: =>
      @_stream_ new HighlandPagination(@_retrieveNotifications).stream()
      .batch 20
      .flatMap (rows) => @_remove rows
      .reduce(0, (accum) -> accum + 1)
      .toPromise(Promise)
      .tap (i) => @debug "Done process. #{i} processed"

    _stream_: -> throw new Error "subclass responsability"
    _filter_: -> throw new Error "subclass responsability"

    _retrieveNotifications: (page = 0) =>
      queryOptions = {
        filter: @_filter_ page
        skip: page * SIZE_PAGE
        top: SIZE_PAGE
      }

      @debug "Searching errors %o", queryOptions 
      @client.searchAsync @index, queryOptions
      .spread (items) -> { items, nextToken: if items?.length is SIZE_PAGE then page + 1 }


    _buildClient: ({ url, key }) ->
      Promise.promisifyAll new AzureSearch({ url, key }), { multiArgs: true }

    _remove: (rows) =>
      ids = _.map rows, ({ id }) -> { id }  
      @debug "Removing documents #{ _.map(ids, "id") } in #{ @index }"
      highland @client.deleteDocumentsAsync @index, ids
