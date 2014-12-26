React = require 'react'
mori = require 'mori'

{table, tbody, tr, td, div, span, input, textarea} = React.DOM
Cell = require './Cell'

utils = require './utils'
dispatcher = require './dispatcher'
cellStore = require './cells-store'

Spreadsheet = React.createClass
  displayName: 'ReactSpreadsheet'
  getInitialState: ->
    cells: cellStore.getCells()

  componentDidMount: ->
    cellStore.on 'CHANGE', @updateCells

    # set cells values
    if @props.cells and @props.cells.length
      dispatcher.replaceCells @props.cells

    # listener for blur
    document.body.addEventListener 'mousedown', @handleClickOut
    document.body.addEventListener 'mouseup', @handleMouseUpOut

  updateCells: ->
    newCells = cellStore.getCells()
    @setState
      cells: newCells
      caretPosition: cellStore.caretPosition
      clipboard: cellStore.clipboard

    array = []
    for r in mori.clj_to_js(newCells)
      row = []
      for c in r
        row.push c.raw
      array.push row

    @props.onChange (c.raw for c in r for r in mori.clj_to_js newCells) if @props.onChange

  componentWillReceiveProps: (nextProps) ->
    if nextProps.cells and nextProps.cells.length
      dispatcher.replaceCells nextProps.cells

  componentWillUnmount: ->
    cellStore.off 'CHANGE', @updateCells
    document.body.removeEventListener 'mousedown', @handleClickOut
    document.body.removeEventListener 'mouseup', @handleMouseUpOut

  render: ->
    (div
      className: 'spreadsheet'
    ,
      (Clipboard
        value: @state.clipboard
      )
      (Cells
        cells: @state.cells
        caretPosition: @state.caretPosition
      )
    )

  handleClickOut: (e) ->
    for i in [4..e.path.length-1]
      node = e.path[i]
      if node == @getDOMNode()
        return
    dispatcher.handleSheetClickedOut e

  handleMouseUpOut: (e) ->
    for i in [4..e.path.length-1]
      node = e.path[i]
      if node == @getDOMNode()
        return
    dispatcher.handleSheetMouseUpOut e

Clipboard = React.createClass
  shouldComponentUpdate: (nextProps) ->
    if nextProps.value != @props.value
      return true
    return false

  componentDidUpdate: (prevProps) ->
    if @refs.clipboard
      node = @refs.clipboard.getDOMNode()
      node.focus()
      node.setSelectionRange 0, node.value.length

  render: ->
    (div className: 'clipboard-container',
      (textarea
        className: 'mousetrap clipboard'
        ref: 'clipboard'
        value: @props.value
        onChange: @handleChange
      ) if typeof @props.value is 'string'
    )

  handleChange: (e) -> dispatcher.handleClipboardChanged e.target.value

Cells = React.createClass
  shouldComponentUpdate: (nextProps) ->
    unless mori.equals nextProps.cells, @props.cells or
           mori.equals nextProps.caretPosition, @props.caretPosition
      return true
    else
      return false

  render: ->
    (table {},
      (tbody {},
        (tr {},
          (td className: 'label')
          (td
            className: 'label'
            key: c
          ,
            utils.letters[c]
          ) for c in [0..(mori.count(mori.get(@props.cells, 0))-1)]
        )
        (tr key: i,
          (td {className: 'label'}, i + 1)
          (Cell
            rowKey: i
            key: j
            cell: mori.get_in @props.cells, [i, j]
            caretPosition: @props.caretPosition
          ) for j in [0..(mori.count(mori.get(@props.cells, 0))-1)]
        ) for i in [0..(mori.count(@props.cells)-1)]
      )
    )


module.exports = Spreadsheet
