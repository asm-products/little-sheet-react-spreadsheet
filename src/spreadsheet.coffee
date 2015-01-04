hg = require 'mercury'
WeakmapEvent = require '../lib/weakmap-event.js'

utils = require './utils'
Clipboard = require './clipboard'
CellStore = require './store'

Spreadsheet = (rawCells) ->
  cells = CellStore rawCells

  hg.state
    cells: cells
    editing: null
    clipboard: Clipboard()
    channels:
      changedClipboard: (state, data) ->
      edited: (state, data) ->
        state.cells.setRaw state.cells, data.coord, data.editing

#clickedOut = WeakmapEvent()
#clickedOut.listen (value, state) -> dispatcher.handleSheetClickedOut()
#mouseUpOut = WeakmapEvent()
#mouseUpOut.listen (value, state) -> dispatcher.handleSheetMouseUpOut()

Cell = require './cell'
{table, tbody, tr, td, div, span, input, textarea} = require 'virtual-elements'

Spreadsheet.render = (state) ->
  (div
    className: 'spreadsheet'
    'in-hook':
      hook: (elem) ->
        document.body.addEventListener 'mousedown', (e) ->
          for i in [4..e.path.length-1]
            node = e.path[i]
            if node == elem
              return
          clickedOut.broadcast state, e
    'out-hook':
      hook: (elem) ->
        document.body.addEventListener 'mouseup', (e) ->
          for i in [4..e.path.length-1]
            node = e.path[i]
            if node == elem
              return
            mouseUpOut.broadcast state, e
  ,
    (Clipboard.render state.clipboard)
    (div {},
      (input
        name: 'editing'
        value: state.editing
        'ev-change': hg.sendValue state.channels.edited
      )
    )
    (table {},
      (tbody {},
        (tr {},
          (td className: 'label')
          (td
            className: 'label'
            key: c
          ,
            utils.letters[c]
          ) for c in [0..state.cells.raw.shape[0]]
        )
        (tr key: i,
          (td {className: 'label'}, i + 1)
          (
            hg.partial Cell.render, state.cells.customHandlers.getCell [i, j]
          ) for j in [0..state.cells.raw.shape[1]]
        ) for i in [0..state.cells.raw.shape[0]]
      )
    )
  )

module.exports = Spreadsheet
