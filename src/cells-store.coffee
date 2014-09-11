FORMULA = require 'formulajs'
Store = require './base-store'
mori = require 'mori'
utils = require './utils'

class RawStore extends Store
  # data
  cells: mori.js_to_clj [
    [
      {raw: '', calc: ''}
      {raw: '', calc: ''}
      {raw: '', calc: ''}
    ]
    [
      {raw: '', calc: ''}
      {raw: '', calc: ''}
      {raw: '', calc: ''}
    ]
    [
      {raw: '', calc: ''}
      {raw: '', calc: ''}
      {raw: '', calc: ''}
    ]
  ]
  editingCoord: null
  selectedCoord: [0, 0]
  getCells: ->
    cells = mori.assoc_in @cells, @selectedCoord.concat('selected'), true
    if @editingCoord
      cells = mori.assoc_in cells, @editingCoord.concat('editing'), true
    return cells
  undoStates: mori.list()
  redoStates: mori.list()
  canUndo: false
  canRedo: false
  redo: ->
    if store.canRedo
      store.undoStates = mori.conj store.undoStates, mori.first store.redoStates
      store.cells = mori.first store.redoStates
      store.redoStates = mori.drop 1, store.redoStates
      store.canRedo = not mori.is_empty store.redoStates
      store.canUndo = true
  undo: ->
    if store.canUndo
      store.redoStates = mori.conj store.redoStates, mori.first this.undoStates
      store.undoStates = mori.drop 1, store.undoStates
      store.cells = mori.first store.undoStates
      store.canUndo = not mori.is_empty store.undoStates
      store.canRedo = true

store = new RawStore

store.registerCallback 'replace-cells', (cellsArray) ->
  newCells = mori.js_to_clj(
    (
      (
        {raw: rawValue, calc: ''}
      ) for rawValue in row
    ) for row in cellsArray
  )

  store.cells = newCells
  store.editingCoord = null
  store.selectedCoord = [0, 0]
  recalc()
  store.changed()

store.registerCallback 'new-cell-value', (value) ->
  store.cells = mori.assoc_in(
    store.cells
    store.editingCoord.concat 'raw'
    value
  )
  store.changed()

store.registerCallback 'cell-clicked', (coord) ->
  if not store.editingCoord
    store.selectedCoord = coord
    store.changed()

  else if store.editingCoord
    valueBeingEdited = mori.get_in(
      store.cells
      store.editingCoord.concat 'raw'
    )

    if valueBeingEdited[0] == '='
      # clicked on a reference
      addr = utils.getAddressFromCoord coord # address is in the format 'A1'
      store.cells = mori.update_in(
        store.cells
        store.editingCoord.concat 'raw'
        (val) -> val + addr
      )
    else
      # just blur
      store.selectedCoord = coord
      store.editingCoord = null
      recalc()

    store.changed()

store.registerCallback 'cell-doubleClicked', (coord) ->
  store.selectedCoord = coord
  store.editingCoord = coord
  store.changed()

store.registerCallback 'down', ->
  if store.editingCoord
    # blur
    store.editingCoord = null
    recalc()

  # go one cell down
  if store.selectedCoord[0] < (mori.count(store.cells) - 1)
    store.selectedCoord = [store.selectedCoord[0] + 1, store.selectedCoord[1]]
  store.changed()

store.registerCallback 'up', ->
  if store.editingCoord
    # blur
    store.editingCoord = null
    recalc()

  # go one cell up
  if store.selectedCoord[0] > 0
    store.selectedCoord = [store.selectedCoord[0] - 1, store.selectedCoord[1]]
  store.changed()

store.registerCallback 'left', ->
  if not store.editingCoord
    if store.selectedCoord[1] > 0
      store.selectedCoord = [store.selectedCoord[0], store.selectedCoord[1] - 1]
      store.changed()

store.registerCallback 'right', ->
  if not store.editingCoord
    if store.selectedCoord[1] < (mori.count(mori.get(store.cells, 0)) - 1)
      store.selectedCoord = [store.selectedCoord[0], store.selectedCoord[1] + 1]
      store.changed()

store.registerCallback 'all-right', ->
  if not store.editingCoord
    store.selectedCoord = [store.selectedCoord[0], mori.count(mori.get(store.cells, 0)) - 1]
    store.changed()

store.registerCallback 'all-down', ->
  if not store.editingCoord
    store.selectedCoord = [mori.count(store.cells) - 1, store.selectedCoord[1]]
    store.changed()

store.registerCallback 'all-up', ->
  if not store.editingCoord
    store.selectedCoord = [0, store.selectedCoord[1]]
    store.changed()

store.registerCallback 'all-left', ->
  if not store.editingCoord
    store.selectedCoord = [store.selectedCoord[0], 0]
    store.changed()

store.registerCallback 'del', ->
  if not store.editingCoord
    # delete the raw content and recalculate
    store.cells = mori.assoc_in(
      store.cells
      store.selectedCoord.concat 'raw'
      ''
    )
    recalc()
    store.changed()

store.registerCallback 'letter', (e) ->
  if not store.editingCoord
    # assign the letter to the cell and start editing it
    store.cells = mori.assoc_in(
      store.cells
      store.selectedCoord.concat 'raw'
      String.fromCharCode(e.keyCode or e.charCode)
    )
    store.editingCoord = store.selectedCoord
    store.changed()

store.registerCallback 'esc', ->
  if store.editingCoord
    # stop editing, don't recalc and return to the previous version (undo)
    store.editingCoord = null
    store.undo()
    store.changed()

store.registerCallback 'undo', ->
  store.undo()
  store.changed()

store.registerCallback 'redo', ->
  store.redo()
  store.changed()

recalc = (->
  calculated = {}

  getCalcResultAt = (addr) ->
    if addr of calculated
      return calculated[addr]
    else
      coord = utils.getCoordFromAddress(addr)
      raw = mori.get_in(
        store.cells
        coord.concat 'raw'
      )
      return getCalcResult raw

  getCalcResult = (raw) ->
    if raw[0] == '='
      return calc raw
    else
      return parseStr raw

  calc = (formula) ->
    if formula[formula.length-1] == ')'
      # formula
      parts = formula.slice(1, -1).split('(')
      methodName = parts[0].toUpperCase()
      args = (getArgValue(arg) or 0 for arg in parts[1].replace(/;/g, ',').split(','))
      return FORMULA[methodName].apply this, args
    else
      # reference (meaning an identity function with a single arg)
      return getArgValue formula.slice(1)

  parseStr = (raw) ->
    return 0 if not raw.length

    f = parseFloat raw
    if not isNaN(f) and isFinite(raw)
      return f
    else
      return raw

  getArgValue = (expr) ->
    expr = expr.trim()

    # cell
    if /^\w\d{1,2}$/.exec expr
      return getCalcResultAt expr

    # list of cells
    cells = expr.split(',')
    if cells.length > 1
      return [getArgValue cell for cell in cells]

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
          addr = utils.getAddressFromCoord [i, j]
          rowArray.push getCalcResultAt addr
        matrix.push rowArray

      return matrix

    # arithmetic (or number)
    try
      return eval expr.replace /(\w\d{1,2})/g, (addr) =>
        getCalcResultAt(addr) or 0
    catch e
      return '#VALUE'

  flush = -> calculated = {}

  return ->
    flush()

    for i in [0..(mori.count(store.cells)-1)]
      for j in [0..(mori.count(mori.get(store.cells, 0))-1)]
        addr = utils.getAddressFromCoord([i, j])
        raw = mori.get_in(store.cells, [i, j, 'raw'])
        calcRes = if raw[0] == '=' then getCalcResult(raw) else raw
        calculated[addr] = calcRes if typeof calcRes == 'number'
        store.cells = mori.assoc_in(store.cells, [i, j, 'calc'], calcRes)

    # after the recalc is done, save state
    store.redoStates = mori.list()
    store.undoStates = mori.conj store.undoStates, store.cells
    store.canUndo = true
    store.canRedo = false

  )()

module.exports = store
