_ = require "lodash"
Promise = require "bluebird"
AzureSearch = require "azure-search"
async = require "async"
{ Processors: { MaxRetriesProcessor } } = require("notification-processor")
{ encode } = require "url-safe-base64"

module.exports =
  class DeadletterProcessor extends MaxRetriesProcessor

    constructor: (opts) ->
      super opts
      { connection, @app, @job, @sender, @index = "errors", @nonRetryableConditions = [] } = opts
      @client = @_buildClient connection
      @cargo = Promise.promisifyAll @_buildCargo() 

    _onSuccess_: (notification, result) ->
    
    _sanitizeError_: (err) -> err

    _shouldRetry_: (notification, err) =>
      super(notification, err) and not _.any @nonRetryableConditions, (f) -> f err
    
    _onMaxRetryExceeded_: (notification, err) ->
      resource = @sender.resource notification

      @cargo.pushAsync {
        id: encode "#{@app}_#{@job}_#{resource}"
        app: @app
        job: @job
        resource: "#{ resource }"
        timestamp: new Date()
        notification: JSON.stringify(notification)
        user: "#{ @sender.user(notification) }"
        error: JSON.stringify(err)
        type: _.get(err, "message") || "unknown_error"
      }

    _buildClient: ({ url, key }) ->
      Promise.promisifyAll new AzureSearch({ url, key }), { multiArgs: true }

    _buildCargo: ->
      async.cargo (tasks, callback) =>
        documents = _.uniqBy tasks, 'id'

        @client.updateOrUploadDocumentsAsync @index, documents
        .thenReturn()
        .asCallback(callback)
