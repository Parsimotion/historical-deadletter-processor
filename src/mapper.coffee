_ = require "lodash"
{ encode } = require "url-safe-base64"
normalizeError = require "./normalize.error"

module.exports = 
  class Mapper
  
    constructor: ({ @sender, @app, @job, @propertiesToOmit, @clientId }) ->
    
    map: (notification, err) ->
      resource = @sender.resource notification
      id = encode "#{@app}_#{@job}_#{resource}"

      _.merge {
        id
        @app
        @job
        resource: "#{ resource }"
        notification: JSON.stringify(notification)
        user: "#{ @sender.user(notification) }"
        @clientId
      }, normalizeError(err, @propertiesToOmit)