_ = require "lodash"
require "should-sinon"
normalize = require "./normalize.error"
require "should"
error = {
      message:"Forbidden"
      detail: 
        response: { statusCode:403, body:""}
        request:
          url:"https://i.blogs.es/e37210/nicolas-cage-cuidara-de-tus-hijos/450_1000.jpg"
          auth: { user:"123123123123", password:"test", pass:"test" }
          method:"GET"
          timeout:120000
          qs:{ authenticationType:"mercadolibre" }
    }

verifyOut = (out, expectedError, expectedRequest) =>
  out.error.should.be.deepEqual JSON.stringify(_.omit expectedError, 'detail.request')
  out.request.should.be.deepEqual JSON.stringify(expectedRequest)

describe 'normalize', ->
  
  describe 'without sending properties to omit', ->

    it.only 'should only omit detail.requst.auth property', ->
      verifyOut normalize(error), error, _.omit(_.get(error, 'detail.request'), 'auth')

    it.only 'should return the same error if there is no detail.requst.auth path in it', ->
      errorWithoutRequest = _.omit error, ['detail.request']
      verifyOut(normalize(errorWithoutRequest), errorWithoutRequest, {})
  
  describe 'sending properties to omit by parameter', ->

    it.only 'should not omit anything if the properties list is empty', ->
      verifyOut normalize(error, []), error, _.get(error, 'detail.request')
    
    it.only 'should omit the specified properties ', ->
      verifyOut normalize(error, ['qs', 'auth']), error, _.omit(_.get(error, 'detail.request'), ['qs', 'auth'])