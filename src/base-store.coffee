EventEmitter = require 'wolfy-eventemitter'

dispatcher = require './dispatcher.coffee'

class Store extends EventEmitter.EventEmitter
  construct: ->

  # register callback to dispatcher
  registerCallback: (event, fn) ->
    dispatcher.on event, fn

  # emit change event
  changed: ->
    @emit 'CHANGE'

module.exports = Store
