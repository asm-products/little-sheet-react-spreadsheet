if typeof window isnt 'undefined'
  Mousetrap = require 'mousetrap'

EventEmitter = require 'wolfy-eventemitter'
if EventEmitter.EventEmitter
  EventEmitter = EventEmitter.EventEmitter

class Dispatcher extends EventEmitter
  construct: ->

  replaceCells: (cellsArray) ->
    @emit 'replace-cells', cellsArray

  handleCellDoubleClicked: (coord) ->
    @emit 'cell-doubleClicked', coord # coord should be an array like [rowNumber, colNumber]

  handleCellClicked: (coord) ->
    @emit 'cell-clicked', coord

  handleCellMouseDown: (coord) ->
    @emit 'cell-mousedown', coord

  handleCellMouseUp: (coord) ->
    @emit 'cell-mouseup', coord

  handleCellMouseEnter: (coord) ->
    @emit 'cell-mouseenter', coord

  handleCellEdited: (value) ->
    @emit 'new-cell-value', value

  handleCellInputClicked: (e) ->
    @emit 'input-clicked', e.target

  handleSheetClickedOut: (e) ->
    @emit 'sheet-clicked-out', e

  handleSheetMouseUpOut: (e) ->
    @emit 'sheet-mouseup-out', e

  handleClipboardChanged: (value) ->
    @emit 'clipboardchanged', value

  initKeyboardShortcuts: ->
    keyup =
      'all-down': ['command+down', 'ctrl+down']
      'all-up': ['command+up', 'ctrl+up']
      'all-left': ['command+left', 'ctrl+left']
      'all-right': ['command+right', 'ctrl+right']
      'del': 'del'
      'letter': ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'x', 'w', 'y', 'z', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '=', '.', ',', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'X', 'W', 'Y', 'Z']
      'undo': 'ctrl+z'
      'redo': 'ctrl+y'
      'esc': 'esc'
      'after-copypaste': ['ctrl', 'command'],
      'copy': ['ctrl+c', 'command+c', 'ctrl+x', 'command+x']

    for eventChannel, shortcut of keyup
      (=>
        channel = eventChannel
        Mousetrap.bind shortcut, (e, combo) =>
          @emit channel, e, combo
        , 'keyup'
      )()

    keydown =
      'down': ['down', 'enter']
      'up': 'up'
      'left': 'left'
      'right': 'right'
      'before-copypaste': ['ctrl', 'command']

    for eventChannel, shortcut of keydown
      (=>
        channel = eventChannel
        Mousetrap.bind shortcut, (e, combo) =>
          @emit channel, e, combo
        , 'keydown'
      )()

dispatcher = new Dispatcher
if typeof window isnt 'undefined'
  dispatcher.initKeyboardShortcuts()

module.exports = dispatcher
