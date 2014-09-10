FORMULA = require 'formulajs'
Store = require './base-store.coffee'
mori = require 'mori'
utils = require './utils.coffee'

class RawStore extends Store
  # data
  cells: mori.js_to_clj [
    [
      {raw: '', calc: '', editing: false, selected: false}
      {raw: '', calc: '', editing: false, selected: false}
      {raw: '', calc: '', editing: false, selected: false}
    ]
    [
      {raw: '', calc: '', editing: false, selected: false}
      {raw: '', calc: '', editing: false, selected: false}
      {raw: '', calc: '', editing: false, selected: false}
    ]
    [
      {raw: '', calc: '', editing: false, selected: false}
      {raw: '', calc: '', editing: false, selected: false}
      {raw: '', calc: '', editing: false, selected: false}
    ]
  ]
  editingCoord: null
  selectedCoord: null

store = new RawStore

store.registerCallback 'replace-cells', (cellsArray) ->
  newCells = mori.js_to_clj(
    (
      (
        {raw: rawValue, calc: '', editing: false, selected: false}
      ) for rawValue in row
    ) for row in cellsArray
  )

  store.cells = newCells
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
    selectCell(coord)
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
      selectCell(coord)
      editCell null
      recalc()

    store.changed()

store.registerCallback 'cell-doubleClicked', (coord) ->
  selectCell(coord)
  editCell(coord)
  store.changed()

selectCell = (newCoord) ->
  if store.selectedCoord
    store.cells = mori.assoc_in(
      store.cells
      store.selectedCoord.concat 'selected'
      false
    )
  store.selectedCoord = newCoord
  if newCoord
    store.cells = mori.assoc_in(
      store.cells
      newCoord.concat 'selected'
      true
    )

editCell = (newCoord) ->
  if store.editingCoord
    store.cells = mori.assoc_in(
      store.cells
      store.editingCoord.concat 'editing'
      false
    )
  store.editingCoord = newCoord
  if newCoord
    store.cells = mori.assoc_in(
      store.cells
      newCoord.concat 'editing'
      true
    )

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
  )()

module.exports = store
