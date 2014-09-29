Store = require './base-store'
Mori = require 'mori'
utils = require './utils'
selix = require 'selix'

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
  strapping: false
  strapVector: [null, null, null]
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

    if @strapVector[1] != null
      # this only works if the first is the first and the second is the second
      highlight = [utils.firstCellFromMulti(@multi), utils.lastCellFromMulti(@multi)]
      # plus, we gain a free cloning of @multi into something we can modify with

      # heavy math:
      #         left/top or right/bottom  vertical or horizontal  
      highlight[    @strapVector[1]     ][    @strapVector[0]   ] += @strapVector[2]

    else
      highlight = @multi

    for i in [highlight[0][0]..highlight[1][0]]
      for j in [highlight[0][1]..highlight[1][1]]
        cells = Mori.assoc_in cells, [i, j, 'multi'], true

    cells = Mori.assoc_in cells, utils.lastCellFromMulti(store.multi).concat('last-multi'), true

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
  rawClipboard: {}

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
  store.rawClipboard = {} # by cleaning this here we avoid problems of people editing the
                          # copied formulas and getting the updated content when pasting
                          # (and other similarly interesting bugs).

store.registerCallback 'input-clicked', (element) ->
  store.caretPosition = selix.getCaret(element).end

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
  if not store.editingCoord
    # normal cell select
    store.select coord
    store.changed()

    # multi select thing
    store.selectingMulti = true

store.registerCallback 'cell-mouseenter', (coord) ->
  if store.selectingMulti
    store.multi = [store.selectedCoord, coord]
    store.changed()

  else if store.strapping
    ###
    check if coord is at the same vertical or horizontal
    lines of the multi-selection
    example:
      store.multi = [[3,1], [4,2]]
      coord[0] must be within the range 3-4 -> same horizontal line
      coord[1] must be within the range 1-2 -> same vertical line

    the strapping zone will be described by a tuple of [
      direction -> either 0 for 'vertical' or 1 for 'horizontal' (this is
                   because the first element (0) of any coord array describes
                   the number of rows, the second (1) describes the number
                   of columns)
      sense -> either 0 for 'left' or 'top' or 1 for 'right' or 'bottom' (
               this is because in the normalized store.multi, the first cell (0)
               will describe the leftmost and uppermost point, the second cell (1)
               will describe the rightmost and bottommost point, which we will
               modify accordingly)
      magnitude -> an integer describing how many columns/rows ocuppy
                   the strapping zone beggining where the multi-selection
                   ends and extending to where the mouse is.
    ] 
    ###
    if coord[0] in [store.multi[0][0]..store.multi[1][0]]
      ### horizontal
      in this case, we must check if the zone will be to the left of the
      current selection or to the right, and the magnitude of the vector
      example:
        store.multi = [[5,2], [3,3]]
        we get the minimum of (coord[1] - 3), (coord[1] - 2) if they are positive
        and the maximum, if they are negative.

        the result will be the magnitude, the sense will be 0
        if the result is negative, 1 if it is positive.
      ###
      x = coord[1] - store.multi[0][1]
      y = coord[1] - store.multi[1][1]
      if x > 0
        store.strapVector = [1, 1, Math.min x, y]
      else if x < 0
        store.strapVector = [1, 0, Math.max x, y]

    else if coord[1] in [store.multi[0][1]..store.multi[1][1]]
      ### vertical
        the procedure is analogal with the horizontal.
        but instead we use coord[0]
      ###
      x = coord[0] - store.multi[0][0]
      y = coord[0] - store.multi[1][0]
      if x > 0
        store.strapVector = [0, 1, Math.min x, y]
      else if x < 0
        store.strapVector = [0, 0, Math.max x, y]

    store.changed()

store.registerCallback 'cell-mouseup', (coord) ->
  if not store.editingCoord
    store.selectingMulti = false

    if store.strapping
      expandPattern()

      # expand the multi-selected area to the strapped area
      # (using the same heavy math used in store.getCells)
      # then clear the strapping things.
      store.multi = [utils.firstCellFromMulti(store.multi), utils.lastCellFromMulti(store.multi)]
      store.multi[store.strapVector[1]][store.strapVector[0]] += store.strapVector[2]
      store.strapping = false
      store.strapVector = [null, null, null]

      recalc()
      store.changed()

store.registerCallback 'strap-mousedown', (coord) ->
  if not store.editingCoord
    store.strapping = true
    store.changed()

store.registerCallback 'cell-doubleClicked', (coord) ->
  store.select coord
  store.edit coord
  store.changed()

store.registerCallback 'down', (e) ->
  e.preventDefault() # prevent scrolling

  if store.editingCoord
    # blur
    store.edit null
    recalc()

  # go one cell down
  if store.selectedCoord[0] < (Mori.count(store.cells) - 1)
    store.select [store.selectedCoord[0] + 1, store.selectedCoord[1]]
  store.changed()

store.registerCallback 'up', (e) ->
  e.preventDefault() # prevent scrolling

  if store.editingCoord
    # blur
    store.edit null
    recalc()

  # go one cell up
  if store.selectedCoord[0] > 0
    store.select [store.selectedCoord[0] - 1, store.selectedCoord[1]]
  store.changed()

store.registerCallback 'tab', (e) ->
  e.preventDefault()
  if store.editingCoord
    # blur
    store.edit null
    recalc()

  # when at the end of line, jump to the next
  if store.selectedCoord[1] == (Mori.count(Mori.get store.cells, 0) - 1)
    if store.selectedCoord[0] + 1 <= (Mori.count(store.cells) - 1)
      store.select [store.selectedCoord[0] + 1, 0]
      store.changed()
  else
    store.triggerCallback 'right', e

store.registerCallback 'left', (e) ->
  if not store.editingCoord
    if store.selectedCoord[1] > 0
      store.select [store.selectedCoord[0], store.selectedCoord[1] - 1]
      store.changed()
  else
    store.caretPosition = selix.getCaret(e.target).start

store.registerCallback 'right', (e) ->
  if not store.editingCoord
    if store.selectedCoord[1] < (Mori.count(Mori.get(store.cells, 0)) - 1)
      store.select [store.selectedCoord[0], store.selectedCoord[1] + 1]
      store.changed()
  else
    store.caretPosition = selix.getCaret(e.target).end

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

store.registerCallback 'select-down', (e) ->
  if not store.editingCoord
    e.preventDefault()
    edge = store.multi[1]
    if edge[0] < (Mori.count(store.cells) - 1)
      store.multi = [store.selectedCoord, [edge[0] + 1, edge[1]]]
      store.changed()

store.registerCallback 'select-up', (e) ->
  if not store.editingCoord
    e.preventDefault()
    edge = store.multi[1]
    if edge[0] > 0
      store.multi = [store.selectedCoord, [edge[0] - 1, edge[1]]]
      store.changed()

store.registerCallback 'select-left', (e) ->
  if not store.editingCoord
    e.preventDefault()
    edge = store.multi[1]
    if edge[1] > 0
      store.multi = [store.selectedCoord, [edge[0], edge[1] - 1]]
      store.changed()

store.registerCallback 'select-right', (e) ->
  if not store.editingCoord
    e.preventDefault()
    edge = store.multi[1]
    if edge[1] < (Mori.count(Mori.get(store.cells, 0)) - 1)
      store.multi = [store.selectedCoord, [edge[0], edge[1] + 1]]
      store.changed()

store.registerCallback 'select-all-right', (e) ->
  if not store.editingCoord
    e.preventDefault()
    edge = store.multi[1]
    store.multi = [store.selectedCoord, [edge[0], Mori.count(Mori.get(store.cells, 0)) - 1]]
    store.changed()

store.registerCallback 'select-all-down', (e) ->
  if not store.editingCoord
    e.preventDefault()
    edge = store.multi[1]
    store.multi = [store.selectedCoord, [Mori.count(store.cells) - 1, edge[1]]]
    store.changed()

store.registerCallback 'select-all-up', (e) ->
  if not store.editingCoord
    e.preventDefault()
    edge = store.multi[1]
    store.multi = [store.selectedCoord, [0, edge[1]]]
    store.changed()

store.registerCallback 'select-all-left', (e) ->
  if not store.editingCoord
    e.preventDefault()
    edge = store.multi[1]
    store.multi = [store.selectedCoord, [edge[0], 0]]
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
  store.strapping = false
  store.strapVector = [null, null, null]
  store.changed()

store.registerCallback 'sheet-mouseup-out', ->
  store.selectingMulti = false

store.registerCallback 'undo', (e) ->
  store.undo()
  store.changed()

store.registerCallback 'redo', ->
  store.redo()
  store.changed()

store.registerCallback 'before-copypaste', (e) ->
  e.preventDefault() # prevent scrolling

  if window.getSelection and window.getSelection().toString()
    return
  if document.selection and document.selection.createRange()
    return

  clipRows = []

  # store.multi is a two-element array pointing to the cells where the selection
  # started/ended, this is needed to put it in the logical order of the smaller
  # to higher cell (in coordinates)
  multiRearranged = [utils.firstCellFromMulti(store.multi), utils.lastCellFromMulti(store.multi)]

  for i in [multiRearranged[0][0]..multiRearranged[1][0]]
    clipCells = []
    for j in [multiRearranged[0][1]..multiRearranged[1][1]]
      clipCells.push Mori.get_in store.cells, [i, j, 'calc']
    clipRows.push clipCells.join '\t'
  store.clipboard = clipRows.join '\n'

  store.changed()

store.registerCallback 'cutcopy', (e) ->
  # get the selected raw content of the cells and the actually
  # copied text (the calc content that appears at the clipboard)
  # and use this to determine if we're pasting content selected
  # here or elsewhere when pasting at this same sheet.
  clipboard = document.querySelector '.clipboard-container .clipboard'
  if clipboard
    # we will rearrange the copied multi to ensure the right
    # order of the cells when pasting.
    copied = [utils.firstCellFromMulti(store.multi), utils.lastCellFromMulti(store.multi)]

    # then we turn this into a two-dimension array of values
    copiedRows = (Mori.get_in(
        store.cells
        [i, j, 'raw']
    ) for j in [copied[0][1]..copied[1][1]] for i in [copied[0][0]..copied[1][0]])

    # then save it to out internal clipboard
    store.rawClipboard = {}
    store.rawClipboard[selix.getText clipboard] = copiedRows

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

  # a paste event, ctrl+v, putting data at the clipboard
  else
    # when getting a paste, we need to check if the pasted cells
    # were copied from this same sheet, in this case we will paste
    # their raw values, instead of the values in the real user
    # clipboard (which are the calc values).
    # to check this, we see if the contents of the user's
    # real clipboard are the same that were copied in the last
    # captured 'copy' event.

    if what of store.rawClipboard
        # yes, they are.
        # let's replace the pasted content with the corresponding
        # cell raw values that we had previously captured
        pastedRows = store.rawClipboard[what]

    else
        # no, they are not, they were copied from somewhere else,
        # let's just paste normally

        # before, we create a two dimension array from the pasted string
        pastedRows = (cell for cell in row.split('\t') for row in what.split('\n'))

    # pasting
    firstSelected = utils.firstCellFromMulti store.multi
    for i in [0..pastedRows.length-1]
      pastedRow = pastedRows[i]
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

module.exports = store

{recalc} = require './recalc'
expandPattern = require './expand-pattern'
