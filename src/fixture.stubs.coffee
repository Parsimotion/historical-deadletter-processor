_ = require "lodash"
sinon = require "sinon"
Promise = require "bluebird"
sinon.usingPromise Promise

module.exports =
  createContextReaderProcessor: (clazz, opts = {}) ->
    _.defaults opts, {
      connection: {
        url: "urlConnection"
        key: "keyConnection"
      }
    }

    processor = new clazz opts

    stubs = {
      "search": sinon.stub(processor.client, "search").yields null, [
        { id: 1, resource: 123, notification: JSON.stringify { ResourceId: 123 } }
        { id: 2, resource: 234, notification: JSON.stringify { ResourceId: 234 } }
      ]
      "delete": sinon.stub(processor.client, "deleteDocumentsAsync").resolves()
    }

    { processor, stubs }
