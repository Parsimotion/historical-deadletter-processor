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

    items = [
      { id: 1, resource: 123, notification: JSON.stringify { ResourceId: 123 } }
      { id: 2, resource: 234, notification: JSON.stringify { ResourceId: 234 } }
    ]
    stubs = {
      "search": sinon.stub(processor.search, "find").resolves { count: 2, items: items }
      "delete": sinon.stub(processor.search, "remove").resolves()
    }

    { processor, stubs }
