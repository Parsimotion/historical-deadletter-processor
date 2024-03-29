moment = require "moment"
fixture = require "./fixture.stubs"

Promise = require "bluebird"
sinon = require "sinon"
sinon.usingPromise Promise
require "should-sinon"

RetryHistoricalProcessor = require "./retry.historical.processor"

configure = (operation) -> 
  fixture.createContextReaderProcessor RetryHistoricalProcessor, { app: "test", job: "test", processor: operation }

describe "RetryHistoricalProcessor", ->

  { clock } = {}

  beforeEach ->
    clock = sinon.useFakeTimers {
      now: new Date("2019-07-17T03:00:00z")
      toFake: ["Date"]
    }

  afterEach ->
    clock.restore()

  it "should remove old errors ", ->
    { processor } = configure sinon.stub()
    day = moment()
    filter = processor._filter_ 0
    filter.should.be.eql """
      (app eq 'test') and (job eq 'test') and (timestamp gt 2019-07-16T03:00:00z)
    """

  it "if messages are retrying and they are sucessful then it should remove them", ->
    { processor, stubs } = configure sinon.stub().yieldsTo("done")
    processor.run {}
    .tap -> stubs.search.should.be.calledTwice()
    .tap -> stubs.delete.should.be.calledOnce()

  it "if messages are retrying and they are failed then it shouldn't remove them", ->
    operation = sinon.stub() 
    operation.onCall(0).yieldsTo "done"
    operation.onCall(1).yieldsTo "done", new Error

    { processor, stubs } = configure operation
    processor.run {}
    .tap -> stubs.search.should.be.calledTwice()
    .tap -> stubs.delete.should.be.calledOnce()
