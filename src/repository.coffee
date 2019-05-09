_ = require "lodash"
Promise = require "bluebird"
debug = require("debug") "historical-deadletter:reader"
async = require "async"
AzureSearch = require "azure-search"

module.exports =
  class Repository

    constructor: (opts) ->
      { connection, @app, @job, @sender, @index = "errors", @nonRetryable } = opts
      @client = @_buildClient connection
      @cargo = Promise.promisifyAll @_buildCargo() 

    save: (doc) ->
      debug "Saving doc with id %s", doc.id
      @cargo.pushAsync _.merge doc, { timestamp: new Date() }

    search: (conditions, { page = 0, size = 100 }) ->
      queryOptions =
        filter: conditions.join(" and ")
        skip: page * size
        top: size
      
      debug "Searching errors %j", queryOptions
      @client.searchAsync @index, queryOptions

    remove: (id) ->
      debug "Removing id %s", id
      @client.deleteDocumentsAsync @index, [ { id } ]

    _buildClient: ({ url, key }) ->
      Promise.promisifyAll new AzureSearch({ url, key }), { multiArgs: true }

    _buildCargo: ->
      async.cargo (tasks, callback) =>
        documents = _.uniqBy tasks, 'id'
        @client.updateOrUploadDocumentsAsync @index, documents
        .thenReturn()
        .asCallback(callback)
