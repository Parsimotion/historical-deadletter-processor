fixture = require "./fixture.stubs"

moment = require "moment"
sinon = require "sinon"
require "should-sinon"

CleanupProcessor = require "./cleanup.processor"

configure = -> fixture.createContextReaderProcessor CleanupProcessor, { days: 10 }

describe "CleanupProcessor", ->

  { clock } = {}

  beforeEach ->
    clock = sinon.useFakeTimers {
      now: new Date("2019-07-20T03:00:00z")
      toFake: ["Date"]
    }

  afterEach ->
    clock.restore()

  it "should create a filter", ->
    { processor } = configure sinon.stub()
    day = moment()
    filter = processor._filter_ 0
    filter.should.be.eql """
      timestamp lt 2019-07-10T03:00:00z
    """

  it "if there are messages older it should remove them them", ->
    { processor, stubs } = configure()
    processor.run {}
    .tap -> stubs.search.should.be.calledTwice()
    .tap -> stubs.delete.should.be.calledOnce()