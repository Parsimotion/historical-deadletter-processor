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
          @conditions = @_buildConditions(opts)
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
      @conditions.map((condition) => "(#{condition})").join(" and ")

    _buildConditions: (opts) ->
      conditions = _.get(opts, 'conditions')
      if(_.get(opts, 'conditions')) then return conditions
      extraConditions = _.get(opts, 'extraConditions')
      nDaysAgo = "#{ moment().subtract(@daysRetrying, 'days').utc().format("YYYY-MM-DDTHH:mm:ss") }z"
      defaultConditions = [
        "app eq '#{ @app }'"
        "job eq '#{ @job }'"
        "timestamp gt #{ nDaysAgo }"
      ]
      if(_.isNil(extraConditions)) then return defaultConditions
      _.concat(defaultConditions, extraConditions)

    _queryOptions_: () =>
      _.merge super(), { select: @select }

    _doProcess: (row) =>
      highland (push, next) =>
        __done = (err) ->
          push err, row
          push null, highland.nil

        @processor { done: __done, log: @logger, job: row.job }, row
