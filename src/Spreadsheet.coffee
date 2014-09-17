React = require 'react'
mori = require 'mori'

{table, tbody, tr, td, div, span, input} = React.DOM
Cell = require './Cell'

utils = require './utils'
dispatcher = require './dispatcher'
cellStore = require './cells-store'

Spreadsheet = React.createClass
  displayName: 'ReactMicroSpreadsheet'
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
    (table
      className: 'microspreadsheet'
    ,
      (tbody {},
        (tr {},
          (td className: 'label')
          (td
            className: 'label'
            key: c
          ,
            utils.letters[c]
          ) for c in [0..(mori.count(mori.get(@state.cells, 0))-1)]
        )
        (tr key: i,
          (td {className: 'label'}, i + 1)
          (Cell
            rowKey: i
            key: j
            cell: mori.get_in @state.cells, [i, j]
            caretPosition: @state.caretPosition
          ) for j in [0..(mori.count(mori.get(@state.cells, 0))-1)]
        ) for i in [0..(mori.count(@state.cells)-1)]
      )
    )

  handleClickOut: (e) ->
    if e.target != @getDOMNode()
      dispatcher.handleSheetClickedOut e

  handleMouseUpOut: (e) ->
    if e.target != @getDOMNode()
      dispatcher.handleSheetMouseUpOut e

module.exports = Spreadsheet
