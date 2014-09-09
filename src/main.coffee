FORMULA = require 'formulajs'
React = require 'react'
mori = require 'mori'

if typeof window isnt 'undefined'
  Mousetrap = require 'mousetrap'

EventEmitter = require 'wolfy-eventemitter'

class Dispatcher extends EventEmitter.EventEmitter
  construct: ->

dispatcher = new Dispatcher

{table, tbody, tr, td, div, span, input} = React.DOM

Spreadsheet = React.createClass
  displayName: 'ReactMicroSpreadsheet'
  getInitialState: ->
    selected: []
    cells: mori.js_to_clj @props.cells
    shownValues: mori.js_to_clj @props.cells

  componentWillMount: ->
    @calcCellsCoords()
    @recalc()

  componentWillReceiveProps: (nextProps) ->
    cells = mori.js_to_clj nextProps.cells
    unless mori.equals cells, mori.js_to_clj(@props.cells)
      @state.cells = cells
      @calcCellsCoords()
      @recalc()

  recalc: ->
    shownValues = []
    for row in @cellsCoords
      rowArray = []
      for cell in row.cells
        shownValue = if cell.value.length then @getShownValue cell.value else ''
        rowArray.push shownValue
      shownValues.push rowArray
    @setState shownValues: shownValues

  getShownValue: (value) ->
    if value[0] == '='
      return @calc value
    else
      return @parseStr value

  calc: (formula) ->
    if formula[formula.length-1] == ')'
      # formula
      parts = formula.slice(1, -1).split('(')
      methodName = parts[0].toUpperCase()
      args = (@getArgValue arg for arg in parts[1].replace(/;/g, ',').split(','))
      return FORMULA[methodName].apply @, args
    else
      # reference (meaning an identity function with a single arg)
      return @getArgValue formula.slice(1)

  getArgValue: (expr) ->
    expr = expr.trim()

    # cell
    if /^\w\d{1,2}$/.exec expr
      return @getShownValue @cellsIndex[expr]

    # list of cells
    cells = expr.split(',')
    if cells.length > 1
      return [@getArgValue cell for cell in cells]

    # matrix
    if /^\w\d{1,2}:\w\d{1,2}$/.exec expr
      refs = expr.split(':')
      colStart = refs[0][0].toUpperCase().charCodeAt(0) - 65 # A turns into 0
      colEnd   = refs[1][0].toUpperCase().charCodeAt(0) - 65
      rowStart = refs[0].slice(1) - 1 # 1 turns into 0
      rowEnd   = refs[1].slice(1) - 1

      matrix = []
      for i in [rowStart..rowEnd]
        rowArray = []
        for j in [colStart..colEnd]
          rowArray.push @getShownValue mori.get_in(@state.cells, [i, j])
        matrix.push rowArray

      return matrix

    # arithmetic (or number)
    try
      return eval expr.replace /(\w\d{1,2})/g, (coord) =>
        @getShownValue @cellsIndex[coord]
    catch e
      return '#VALUE'

  parseStr: (str) ->
    return 0 if not str.length

    f = parseFloat str
    if not isNaN(f) and isFinite(str)
      return f
    else
      return str

  letters: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  calcCellsCoords: ->
    @cellsCoords = []
    @cellsIndex = {}

    number = 1
    for row in mori.clj_to_js @state.cells
      rowArray = []

      letter = 0
      for cellValue in row
        coord = @letters[letter] + number
        rowArray.push {coord: coord, key: @letters[letter], value: cellValue}
        @cellsIndex[coord] = cellValue

        letter++

      @cellsCoords.push {key: "#{number}", cells: rowArray}
      number++

  cellsCoords: null
  cellsIndex: null

  componentDidMount: ->
    Mousetrap.bind ['down', 'enter'], (e) =>
      if @state.selected.length
        e.preventDefault()
        if @state.selected[0] < (mori.count(@state.cells) - 1)
          @setState
            selected: [@state.selected[0] + 1, @state.selected[1]]
    Mousetrap.bind 'up', (e) =>
      if @state.selected.length
        e.preventDefault()
        if @state.selected[0] > 0
          @setState
            selected: [@state.selected[0] - 1, @state.selected[1]]
    Mousetrap.bind 'left', (e) =>
      if @state.selected.length
        e.preventDefault()
        if @state.selected[1] > 0
          @setState
            selected: [@state.selected[0], @state.selected[1] - 1]
    Mousetrap.bind 'right', (e) =>
      if @state.selected.length
        e.preventDefault()
        if @state.selected[1] < (mori.count(mori.nth(@state.cells, 0)) - 1)
          @setState
            selected: [@state.selected[0], @state.selected[1] + 1]
    Mousetrap.bind 'ctrl+down', (e) =>
      if @state.selected.length
        e.preventDefault()
        @setState selected: [mori.count(@state.cells) - 1, @state.selected[1]]
    Mousetrap.bind 'ctrl+up', (e) =>
      if @state.selected.length
        e.preventDefault()
        @setState selected: [0, @state.selected[1]]
    Mousetrap.bind 'ctrl+left', (e) =>
      if @state.selected.length
        e.preventDefault()
        @setState selected: [@state.selected[0], 0]
    Mousetrap.bind 'ctrl+right', (e) =>
      if @state.selected.length
        e.preventDefault()
        @setState selected: [@state.selected[0], mori.count(mori.nth(@state.cells, 0)) - 1]
    Mousetrap.bind 'del', (e) =>
      if @state.selected.length
        e.preventDefault()
        @handleCellChange @state.selected[0], @state.selected[1], {target: {value: ''}}

  handleCellClick: (rowN, colN, e) ->
    e.preventDefault() if e
    dispatcher.emit 'cell-clicked', @cellsCoords[rowN].cells[colN].coord
    @setState selected: [rowN, colN]

  handleCellChange: (rowN, colN, e) ->
    @setState
      cells: mori.update_in @state.cells, [rowN, colN], mori.constantly e.target.value
    , ->
      @calcCellsCoords()
      @recalc()
      @props.onChange mori.clj_to_js(@state.cells) if @props.onChange

  render: ->
    (table className: 'microspreadsheet',
      (tbody {},
        (tr {},
          (td className: 'label')
          (td
            className: 'label',
            key: cell.key
          , cell.key) for cell in @cellsCoords[0].cells
        )
        (tr key: row.key,
          (td {className: 'label'}, row.key)
          (Cell
            value: cell.value
            show: @state.shownValues[i][j]
            selected: (i == @state.selected[0] and j == @state.selected[1])
            key: cell.key
            onClick: @handleCellClick.bind @, i, j
            onChange: @handleCellChange.bind @, i, j
          ) for cell, j in row.cells
        ) for row, i in @cellsCoords
      )
    )

Cell = React.createClass
  displayName: 'ReactMicroSpreadsheetCell'
  getInitialState: ->
    editing: false
    value: @props.value

  componentWillReceiveProps: (nextProps) ->
    if nextProps.value != @props.value
      @setState value: nextProps.value

  shouldComponentUpdate: (nextProps, nextState) ->
    if nextState.editing != @state.editing then true
    else if nextProps.show != @props.show then true
    else if nextProps.selected != @props.selected then true
    else false

  componentDidUpdate: (prevProps) ->
    if @state.editing and not @props.selected
      @stopEditing()

  componentDidMount: ->
    dispatcher.on 'cell-clicked', @handleCoordClicked

  handleCoordClicked: (coord) ->
    if @state.editing and @state.value[0] == '='
      @setState value: @state.value + coord

  handleChange: (e) ->
    @state.value = e.target.value
    @forceUpdate()

  startEditing: (e) ->
    e.preventDefault() if e
    @props.onClick e
    @setState
      editing: true

  stopEditing: ->
    @setState editing: false
    @props.onChange({target: {value: @state.value}})

  handleKeyPress: (e) ->
    if e.key == 'Enter'
      @stopEditing()

  render: ->
    (td
      className: 'cell ' + if @props.selected then 'selected' else ''
    ,
      (div {},
        (input
          ref: 'input'
          className: 'mousetrap'
          onBlur: @stopEditing
          onChange: @handleChange
          onKeyPress: @handleKeyPress
          value: @state.value
          autoFocus: true
        ) if @state.editing
        (span
          onClick: @props.onClick
          onDoubleClick: @startEditing
        , @props.show) unless @state.editing
      )
    )

module.exports = Spreadsheet
