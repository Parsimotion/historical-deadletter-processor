_ = require "lodash"
Promise = require "bluebird"
AzureSearch = require "azure-search"
{ Processors: { MaxRetriesProcessor } } = require("notification-processor")
{ encode } = require "url-safe-base64"

module.exports =
  class DeadletterProcessor extends MaxRetriesProcessor

    constructor: (opts) ->
      super opts
      { connection, @app, @job, @sender, @index = "errors" } = opts
      @client = @_buildClient connection

    _onSuccess_: (notification, result) ->
    
    _sanitizeError_: (err) -> err
    
    _onMaxRetryExceeded_: (notification, err) ->
      resource = @sender.resource notification

      id = encode "#{@app}_#{@job}_#{resource}"
      @client.updateOrUploadDocumentsAsync @index, [{
        id: id,
        app: @app,
        job: @job,
        resource: "#{ resource }",
        timestamp: new Date(),
        notification: JSON.stringify(notification),
        user: "#{ @sender.user(notification) }",
        error: JSON.stringify(err),
        type: _.get(err, "message") || "unknown_error"
      }]

    _buildClient: ({ url, key }) ->
      Promise.promisifyAll new AzureSearch({ url, key }), { multiArgs: true }
