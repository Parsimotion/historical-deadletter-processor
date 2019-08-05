_ = require "lodash"
highland = require "highland"
moment = require "moment"

module.exports =
  class ReaderHistoricalProcessor extends AbstractReaderProcessor

    constructor: (opts) ->
        super opts
        {
          @processor
          @app
          @job
          @daysRetrying = 1
          @conditions = @_buildDefaultConditions()
        } = opts

    _stream_: (stream) ->
      stream
      .map (row) -> _.update row, "notification", JSON.parse
      .concurrentFlatMap @concurrency.callsToApi, (row) =>
        @_doProcess row
        .errors => @debug "Still fails #{row.resource}"
      .tap (row) => @debug "Process successful #{row.resource}"

    _filter_: (page = 0) =>
      @conditions.join(" and ")

    _buildDefaultConditions: ->
      nDaysAgo = "#{ moment().subtract(@daysRetrying, 'days').utc().format("YYYY-MM-DDTHH:mm:ss") }z"

      [
        "app eq '#{ @app }'"
        "job eq '#{ @job }'"
        "timestamp gt #{ nDaysAgo }"
      ]

    _doProcess: (row) =>
      highland (push, next) =>
        __done = (err) ->
          push err, row
          push null, highland.nil

        @processor { done: __done, log: @logger }, row
