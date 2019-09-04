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

describe 'normalize', ->
  
  describe 'without sending properties to omit', ->

    it 'should only omit detail.requst.auth property', ->
      normalize(error).error.should.be.deepEqual JSON.stringify( _.omit error, ['detail.request.auth'] )

    it 'should return the same error if there is no detail.requst.auth path in it', ->
      errorWithoutRequest = _.omit error, ['detail.request']
      normalize(errorWithoutRequest).error.should.be.deepEqual JSON.stringify( errorWithoutRequest )
  
  describe 'sending properties to omit by parameter', ->

    it 'should not omit anything if the properties list is empty', ->
      normalize(error, []).error.should.be.deepEqual JSON.stringify error
    
    it 'should omit the specified properties ', ->
      normalize(error, ['detail']).error.should.be.deepEqual JSON.stringify( _.omit error, ['detail'] )