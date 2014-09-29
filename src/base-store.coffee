EventEmitter = require 'wolfy-eventemitter'
if EventEmitter.EventEmitter
  EventEmitter = EventEmitter.EventEmitter

dispatcher = require './dispatcher'

class Store extends EventEmitter
  construct: ->

  # register callback to dispatcher
  registerCallback: (event, fn) ->
    dispatcher.on event, fn

  # trigger callback
  triggerCallback: (event) ->
    dispatcher.emit event, arguments[1], arguments[2]

  # emit change event
  changed: ->
    @emit 'CHANGE'

module.exports = Store
