fixture = require "./fixture.stubs"

sinon = require "sinon"
require "should-sinon"

CleanupProcessor = require "./cleanup.processor"

configure = (operation) -> fixture.createContextReaderProcessor CleanupProcessor, operation

describe "CleanupProcessor", ->

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
    .tap -> stubs.delete.should.be.calledTwice()
