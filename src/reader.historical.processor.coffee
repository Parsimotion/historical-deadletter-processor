_ = require "lodash"
normalizeError = require "./normalize.error"
Promise = require "bluebird"
highland = require "highland"
HighlandPagination  = require "highland-pagination"
moment = require "moment"
debug = require("debug")("historical-deadletter:reader")
Repository = require "./repository"

require "highland-concurrent-flatmap"

SIZE_PAGE = 100

module.exports =
  class ReaderHistoricalProcessor

    constructor: (opts) ->
        { 
          @processor, 
          @app, 
          @job, 
          @daysRetrying = 1, 
          @concurrency = { callsToApi: 20, callsToAzure: 50 } 
          @conditions
          @logger = debug
        } = opts
        @repository = new Repository opts 

    run: =>
      new HighlandPagination @_retrieveFailedNotifications
        .stream()
        .map (message) -> _.update message, "notification", JSON.parse
        .concurrentFlatMap @concurrency.callsToApi, (message) =>
          @_doProcess message
          .map -> message
          .errors (err) =>
            debug "Still fails #{ message.app }-#{ message.job }-#{ message.resource }"
            @repository.save _.merge(message, { notification: JSON.stringify(message.notification) }, normalizeError(err))
        .tap (row) => debug "Process successful #{ row.app }-#{ row.job }-#{ row.resource }"
        .batch 20
        .concurrentFlatMap @concurrency.callsToAzure, (it) => highland @repository.remove _.map(it, "id")
        .reduce 0, (accum) -> accum + 1
        .toPromise Promise
        .tap => debug "Done process"

    _retrieveFailedNotifications: (page) =>
      @repository.search @_conditions(), { page, size: SIZE_PAGE }
      .spread (items) -> { items, nextToken: if items?.length is SIZE_PAGE then page + 1 }

    _conditions: ->
      return @conditions if @conditions?

      nDaysAgo = "#{ moment().subtract(@daysRetrying, 'days').utc().format("YYYY-MM-DDTHH:mm:ss") }z"

      [
        "app eq '#{ @app }'"
        "job eq '#{ @job }'"
        "timestamp gt #{ nDaysAgo }"
      ]

    _doProcess: (row) =>
      highland (push, next) =>
        __done = (err) ->
          push err, null
          push null, highland.nil

        @processor { done: __done, log: @logger }, row

