_ = require "lodash"
Promise = require "bluebird"
highland = require "highland"
Search = require "search-sdk"
HighlandPagination  = require "highland-pagination"
require "highland-concurrent-flatmap"

module.exports = 
class AbstractReaderProcessor

    constructor: ({
      connection
      @logger = console
      @sizePage = 100
    }) ->
      @search = @_buildClient connection
      @index = connection.index
      @debug = require("debug") "historical-deadletter:#{ this.constructor.name }"

    run: =>
      @search.reverseStream(@_queryOptions_(), @sizePage)
      .then ({ stream }) =>
        stream
          .through (s) => @_action_ s
          .batch 20
          .concurrentFlatMap 10, (rows) => @_remove(rows).map -> rows
          .reduce(0, (accum, rows) -> accum + rows.length)
          .toPromise(Promise)
          .tap (i) => @debug "Done process. #{i} processed successfully"

    _action_: -> throw new Error "_action_ subclass responsibility"
    _filter_: -> throw new Error "_filter_ subclass responsibility"

    _queryOptions_: () =>
      {
        filter: @_filter_()
      }

    _buildClient: (connection) ->
      new Search(_.merge { index: "incidents" }, connection)

    _remove: (rows) =>
      ids = _.map rows, ({ id }) -> { id }  
      @debug "Removing documents #{ _.map(ids, "id") } in #{ @index }"
      highland @search.remove ids...
