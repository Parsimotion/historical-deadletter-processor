fixture = require "./fixture.stubs"

moment = require "moment"
sinon = require "sinon"
require "should-sinon"

CleanupProcessor = require "./cleanup.processor"

configure = (operation) -> fixture.createContextReaderProcessor CleanupProcessor, operation, { days: 10 }

describe "CleanupProcessor", ->

  { clock } = {}

  beforeEach ->
    clock = sinon.useFakeTimers {
      now: new Date("2019-07-20T03:00:00z")
    }

  afterEach ->
    clock.restore()

  it "should remove old errors ", ->
    { processor } = configure sinon.stub()
    day = moment()
    filter = processor._filter_ 0
    filter.should.be.eql """
      timestamp lt 2019-07-10T03:00:00z
    """

  it "if messages are retrying and they are sucessful then it should remove them", ->
    { processor, stubs } = configure sinon.stub().yieldsTo("done")
    processor.run {}
    .tap -> stubs.search.should.be.calledOnce()
    .tap -> stubs.delete.should.be.calledTwice()

  it "if messages are retrying and they are failed then it shouldn't remove them", ->
    stub = sinon.stub() 
    stub.onCall(0).yieldsTo "done"
    stub.onCall(1).yieldsTo "done", new Error

    { processor, stubs } = configure stub
    processor.run {}
    .tap -> stubs.search.should.be.calledOnce()
    .tap -> stubs.delete.should.be.calledTwice()
