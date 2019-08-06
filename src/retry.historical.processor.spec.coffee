fixture = require "./fixture.stubs"

Promise = require "bluebird"
sinon = require "sinon"
sinon.usingPromise Promise
require "should-sinon"

RetryHistoricalProcessor = require "./retry.historical.processor"

configure = (operation) -> 
  fixture.createContextReaderProcessor RetryHistoricalProcessor, operation, { app: "test", job: "test" }

describe "RetryHistoricalProcessor", ->

  it "if messages are retrying and they are sucessful then it should remove them", ->
    { processor, stubs } = configure sinon.stub().yieldsTo("done")
    processor.run({})
    .tap -> stubs.search.should.be.calledOnce()
    .tap -> stubs.delete.should.be.calledTwice()

  it "if messages are retrying and they are failed then it shouldn't remove them", ->
    stub = sinon.stub() 
    stub.onCall(0).yieldsTo "done"
    stub.onCall(1).yieldsTo "done", new Error

    { processor, stubs } = configure stub
    processor.run({})
    .tap -> stubs.search.should.be.calledOnce()
    .tap -> stubs.delete.should.be.calledOnce()
