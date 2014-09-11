EventEmitter = require 'wolfy-eventemitter'
if EventEmitter.EventEmitter
  EventEmitter = EventEmitter.EventEmitter

dispatcher = require './dispatcher'

class Store extends EventEmitter
  construct: ->

  # register callback to dispatcher
  registerCallback: (event, fn) ->
    dispatcher.on event, fn

  # emit change event
  changed: ->
    @emit 'CHANGE'

module.exports = Store
