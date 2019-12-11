_ = require "lodash"
highland = require "highland"
moment = require "moment"
AbstractReaderProcessor = require "./abstract.reader.processor"

module.exports =
  class RetryHistoricalProcessor extends AbstractReaderProcessor

    constructor: (opts) ->
        super opts
        {
          @processor
          @app
          @job
          @daysRetrying = 1
          @concurrency = { callsToApi: 20 }
          @conditions = @_buildDefaultConditions()
          @select = "id,notification,resource,job"
        } = opts

    _action_: (stream) ->
      stream
      .map (row) -> _.update row, "notification", JSON.parse
      .concurrentFlatMap @concurrency.callsToApi, (row) =>
        @_doProcess row
        .errors => @debug "Still fails #{row.resource} in #{@app}/#{@job}"
      .tap (row) => @debug "Process successful #{row.resource} in #{@app}/#{@job}"

    _filter_: (page = 0) =>
      @conditions.join(" and ")

    _buildDefaultConditions: ->
      nDaysAgo = "#{ moment().subtract(@daysRetrying, 'days').utc().format("YYYY-MM-DDTHH:mm:ss") }z"

      [
        "app eq '#{ @app }'"
        "job eq '#{ @job }'"
        "timestamp gt #{ nDaysAgo }"
      ]

    _queryOptions_: (page) =>
      _.merge super(page), { select: @select }

    _doProcess: (row) =>
      highland (push, next) =>
        __done = (err) ->
          push err, row
          push null, highland.nil

        @processor row, { done: __done, log: @logger, job: row.job }
