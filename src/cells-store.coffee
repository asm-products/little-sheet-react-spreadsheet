FORMULA = require 'formulajs'
Store = require './base-store'
Mori = require 'mori'
utils = require './utils'

class RawStore extends Store
  # data
  cells: Mori.js_to_clj [
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
  selectedCoord: [0, 0]
  multi: [[0, 0], [0, 0]]
  selectingMulti: false
  editingCoord: null
  caretPosition: null

  select: (coord) ->
    @selectedCoord = coord
    @multi = [coord, coord]
  edit: (coord) ->
    @editingCoord = coord
    @selectingMulti = false
    @caretPosition = null

  getCells: ->
    cells = Mori.assoc_in @cells, @selectedCoord.concat('selected'), true
    if @editingCoord
      cells = Mori.assoc_in cells, @editingCoord.concat('editing'), true
    for i in [@multi[0][0]..@multi[1][0]]
      for j in [@multi[0][1]..@multi[1][1]]
        cells = Mori.assoc_in cells, [i, j, 'multi'], true
    return cells

  undoStates: Mori.list()
  redoStates: Mori.list()
  canUndo: false
  canRedo: false
  redo: ->
    if store.canRedo
      store.undoStates = Mori.conj store.undoStates, Mori.first store.redoStates
      store.cells = Mori.first store.redoStates
      store.redoStates = Mori.drop 1, store.redoStates
      store.canRedo = not Mori.is_empty store.redoStates
      store.canUndo = true
  undo: ->
    if store.canUndo
      store.redoStates = Mori.conj store.redoStates, Mori.first this.undoStates
      store.undoStates = Mori.drop 1, store.undoStates
      store.cells = Mori.first store.undoStates
      store.canUndo = not Mori.is_empty store.undoStates
      store.canRedo = true

  clipboard: false

store = new RawStore

store.registerCallback 'replace-cells', (cellsArray) ->
  newCells = Mori.js_to_clj(
    (
      (
        {raw: rawValue, calc: ''}
      ) for rawValue in row
    ) for row in cellsArray
  )

  store.cells = newCells
  store.edit null
  store.select [0, 0]
  recalc()
  store.changed()

store.registerCallback 'new-cell-value', (value) ->
  store.cells = Mori.assoc_in(
    store.cells
    store.editingCoord.concat 'raw'
    value
  )
  store.caretPosition = null
  store.changed()

store.registerCallback 'input-clicked', (element) ->
  store.caretPosition = utils.getCaretPosition element

store.registerCallback 'cell-clicked', (coord) ->
  if store.editingCoord
    valueBeingEdited = Mori.get_in(
      store.cells
      store.editingCoord.concat 'raw'
    )

    if valueBeingEdited[0] == '='
      # clicked on a reference
      addr = utils.getAddressFromCoord coord # address is in the format 'A1'
      store.cells = Mori.update_in(
        store.cells
        store.editingCoord.concat 'raw'
        (val) ->
          caretPosition = if store.caretPosition is null then val.length else store.caretPosition
          if caretPosition == 0
            return val

          left = val.substr 0, caretPosition
          right = val.substr caretPosition

          # clean near expression values
          left = left.replace /([+-/:;.*(=])[^+-/:;.*(=]*$/, '$1'
          right = right.replace /^[^+-/:;.*)]*([+-/:;.*)]|$)/, '$1'

          # set caret position to just after the addr
          store.caretPosition = (left + addr).length

          return left + addr + right
      )
    else
      # just blur
      store.select coord
      store.edit null
      recalc()

    store.changed()

store.registerCallback 'cell-mousedown', (coord) ->
  # normal cell select
  if not store.editingCoord
    store.select coord
    store.changed()

  # multi select thing
  if not store.editingCoord
    store.selectingMulti = true

store.registerCallback 'cell-mouseenter', (coord) ->
  if store.selectingMulti
    store.multi = [store.selectedCoord, coord]
    store.changed()

store.registerCallback 'cell-mouseup', (coord) ->
  if not store.editingCoord
    store.selectingMulti = false

store.registerCallback 'cell-doubleClicked', (coord) ->
  store.select coord
  store.edit coord
  store.changed()

store.registerCallback 'down', ->
  if store.editingCoord
    # blur
    store.edit null
    recalc()

  # go one cell down
  if store.selectedCoord[0] < (Mori.count(store.cells) - 1)
    store.select [store.selectedCoord[0] + 1, store.selectedCoord[1]]
  store.changed()

store.registerCallback 'up', ->
  if store.editingCoord
    # blur
    store.edit null
    recalc()

  # go one cell up
  if store.selectedCoord[0] > 0
    store.select [store.selectedCoord[0] - 1, store.selectedCoord[1]]
  store.changed()

store.registerCallback 'left', (e) ->
  if not store.editingCoord
    if store.selectedCoord[1] > 0
      store.select [store.selectedCoord[0], store.selectedCoord[1] - 1]
      store.changed()
  else
    store.caretPosition = utils.getCaretPosition e.target

store.registerCallback 'right', (e) ->
  if not store.editingCoord
    if store.selectedCoord[1] < (Mori.count(Mori.get(store.cells, 0)) - 1)
      store.select [store.selectedCoord[0], store.selectedCoord[1] + 1]
      store.changed()
  else
    store.caretPosition = utils.getCaretPosition e.target

store.registerCallback 'all-right', ->
  if not store.editingCoord
    store.select [store.selectedCoord[0], Mori.count(Mori.get(store.cells, 0)) - 1]
    store.changed()

store.registerCallback 'all-down', ->
  if not store.editingCoord
    store.select [Mori.count(store.cells) - 1, store.selectedCoord[1]]
    store.changed()

store.registerCallback 'all-up', ->
  if not store.editingCoord
    store.select [0, store.selectedCoord[1]]
    store.changed()

store.registerCallback 'all-left', ->
  if not store.editingCoord
    store.select [store.selectedCoord[0], 0]
    store.changed()

store.registerCallback 'del', ->
  if not store.editingCoord
    # delete the raw content and recalculate
    store.cells = Mori.assoc_in(
      store.cells
      store.selectedCoord.concat 'raw'
      ''
    )
    for i in [store.multi[0][0]..store.multi[1][0]]
      for j in [store.multi[0][1]..store.multi[1][1]]
        store.cells = Mori.assoc_in(
          store.cells
          [i, j, 'raw']
          ''
        )
    recalc()
    store.changed()

store.registerCallback 'letter', (e) ->
  if not store.editingCoord
    # does nothing when pressed with a meta key (except shift)
    if e.ctrlKey or e.metaKey or e.altKey
      return

    # assign the letter to the cell and start editing it
    store.cells = Mori.assoc_in(
      store.cells
      store.selectedCoord.concat 'raw'
      String.fromCharCode(e.keyCode or e.charCode)
    )
    e.preventDefault()
    e.stopPropagation()
    store.edit store.selectedCoord
    store.changed()

store.registerCallback 'esc', ->
  if store.editingCoord
    # stop editing, don't recalc and return to the previous version (undo)
    store.edit null
    store.undo()
    store.changed()

store.registerCallback 'sheet-clicked-out', ->
  store.selectingMulti = false
  store.multi = [store.selectedCoord, store.selectedCoord]
  store.changed()

store.registerCallback 'sheet-mouseup-out', ->
  store.selectingMulti = false

store.registerCallback 'undo', (e) ->
  store.undo()
  store.changed()

store.registerCallback 'redo', ->
  store.redo()
  store.changed()

store.registerCallback 'before-copypaste', ->
  if window.getSelection and window.getSelection().toString()
    return
  if document.selection and document.selection.createRange()
    return

  clipRows = []
  for i in [store.multi[0][0]..store.multi[1][0]]
    clipCells = []
    for j in [store.multi[0][1]..store.multi[1][1]]
      clipCells.push Mori.get_in store.cells, [i, j, 'calc']
    clipRows.push clipCells.join '\t'
  store.clipboard = clipRows.join '\n'

  store.changed()

store.registerCallback 'clipboardchanged', (what) ->
  # a cut event, ctrl+x, leaving the clipboard empty
  if what is ''
    for i in [store.multi[0][0]..store.multi[1][0]]
      for j in [store.multi[0][1]..store.multi[1][1]]
        store.cells = Mori.assoc_in(
          store.cells
          [i, j, 'raw']
          ''
        )

  # a paste event, ctrl+v, putting ne data the the clipboard
  else
    firstSelected = utils.firstCellFromMulti store.multi
    pastedRows = what.split('\n')
    for i in [0..pastedRows.length-1]
      pastedRow = pastedRows[i].split('\t')
      qi = i + firstSelected[0]
      if qi >= Mori.count store.cells
        # this condition checks for the end of the rows,
        # so we don't end adding any data below the existent
        # rows.
        continue

      for j in [0..pastedRow.length-1]
        pastedCell = pastedRow[j]
        qj = j + firstSelected[1]
        if qj >= Mori.count Mori.get store.cells, 0
          # this condition checks for the end of the cols,
          continue

        store.cells = Mori.assoc_in(
          store.cells
          [qi, qj, 'raw']
          pastedCell
        )

  recalc()
  store.changed()

store.registerCallback 'after-copypaste', ->
  store.clipboard = null
  store.changed()

recalc = (->
  calculated = {}

  getCalcResultAt = (addr) ->
    if addr of calculated
      return calculated[addr]
    else
      coord = utils.getCoordFromAddress(addr)
      raw = Mori.get_in(
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
    if /^[A-Z]\d{1,2}$/.exec expr
      return getCalcResultAt expr

    # list of cells
    cells = expr.split(',')
    if cells.length > 1
      return [getArgValue cell for cell in cells]

    # matrix
    if /^[A-Z]\d{1,2}:[A-Z]\d{1,2}$/.exec expr
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
      return eval expr.replace /(\b[A-Z]\d{1,2}\b)/g, (addr) ->
        getCalcResultAt(addr) or 0
    catch e
      return '#VALUE'

  flush = -> calculated = {}

  return ->
    flush()

    for i in [0..(Mori.count(store.cells)-1)]
      for j in [0..(Mori.count(Mori.get(store.cells, 0))-1)]
        addr = utils.getAddressFromCoord([i, j])
        raw = Mori.get_in(store.cells, [i, j, 'raw'])
        calcRes = if raw[0] == '=' then getCalcResult(raw) else raw
        calculated[addr] = calcRes if typeof calcRes == 'number'
        store.cells = Mori.assoc_in(store.cells, [i, j, 'calc'], calcRes)

    # after the recalc is done, save state
    store.redoStates = Mori.list()
    store.undoStates = Mori.conj store.undoStates, store.cells
    store.canUndo = true
    store.canRedo = false

  )()

module.exports = store
