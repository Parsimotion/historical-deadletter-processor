_ = require "lodash"
sinon = require "sinon"
Promise = require "bluebird"
sinon.usingPromise Promise

module.exports =
  createContextReaderProcessor: (clazz, operation, opts = {}) ->
    _.defaults opts, {
      processor: operation
      connection: {
        url: "urlConnection"
        key: "keyConnection"
      }
    }

    processor = new clazz opts

    stubs = {
      "search": sinon.stub(processor.client, "search").yields null, [
        { notification: JSON.stringify { ResourceId: 123 } }
        { notification: JSON.stringify { ResourceId: 234 } }
      ]
      "delete": sinon.stub(processor.client, "deleteDocumentsAsync").resolves()
    }

    { processor, stubs }
