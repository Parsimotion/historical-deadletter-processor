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
      { @nonRetryable = [] } = opts

    _onSuccess_: (notification, result) ->

    _shouldRetry_: (notification, err) =>
      super(notification, err) and err?.detail?.response?.statusCode not in @nonRetryable

    _sanitizeError_: (err) -> err
    
    _onMaxRetryExceeded_: (notification, err) ->
      @repository.save @mapper.map(notification, err)
