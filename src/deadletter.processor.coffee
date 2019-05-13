_ = require "lodash"
Repository = require "./repository"
MapperToSearch = require "./mapper"
{ Processors: { MaxRetriesProcessor } } = require("notification-processor")

module.exports =
  class DeadletterProcessor extends MaxRetriesProcessor

    constructor: (opts) ->
      super opts
      @mapper = new MapperToSearch opts
      @repository = new Repository opts

    _onSuccess_: (notification, result) ->

    _shouldRetry_: (notification, err) =>
      statusCode = err?.detail?.response?.statusCode
      super(notification, err) or statusCode >= 500

    _sanitizeError_: (err) -> err
    
    _onMaxRetryExceeded_: (notification, err) ->
      @repository.save @mapper.map(notification, err)
