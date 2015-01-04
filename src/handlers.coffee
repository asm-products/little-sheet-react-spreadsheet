  replaceCells: (cellsArray) ->
    @emit 'replace-cells', cellsArray

  handleCellDoubleClicked: (coord) ->
    @emit 'cell-doubleclicked', coord # coord should be an array like [rowNumber, colNumber]

  handleCellClicked: (coord) ->
    @emit 'cell-clicked', coord

  handleCellMouseDown: (coord) ->
    @emit 'cell-mousedown', coord

  handleMouseDownStrap: (coord) ->
    @emit 'strap-mousedown', coord

  handleCellMouseUp: (coord) ->
    @emit 'cell-mouseup', coord

  handleCellMouseEnter: (coord) ->
    @emit 'cell-mouseenter', coord

  handleCellEdited: (value) ->
    @emit 'new-cell-value', value

  handleCellInputClicked: (e) ->
    @emit 'input-clicked', e.target

  handleCellInputDoubleClicked: (e) ->
    @emit 'input-doubleclicked', e.target

  handleSelectText: (e) ->
    @emit 'input-selecttext', e.target

  handleSheetClickedOut: (e) ->
    @emit 'sheet-clicked-out', e

  handleSheetMouseUpOut: (e) ->
    @emit 'sheet-mouseup-out', e

  initKeyboardShortcuts: ->
    keyup =
      'all-down': ['command+down', 'ctrl+down']
      'all-up': ['command+up', 'ctrl+up']
      'all-left': ['command+left', 'ctrl+left']
      'all-right': ['command+right', 'ctrl+right']
      'left-keyup': 'left'
      'right-keyup': 'right'
      'del': 'del'
      'undo': 'ctrl+z'
      'redo': 'ctrl+y'
      'esc': 'esc'
      'after-copypaste': ['ctrl', 'command'],

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
      'tab': 'tab'
      'select-down': 'shift+down'
      'select-up': 'shift+up'
      'select-left': 'shift+left'
      'select-right': 'shift+right'
      'select-all-down': ['ctrl+shift+down', 'command+shift+down']
      'select-all-up': ['ctrl+shift+up', 'command+shift+up']
      'select-all-left': ['ctrl+shift+left', 'command+shift+left']
      'select-all-right': ['ctrl+shift+right', 'command+shift+right']
      'before-copypaste': ['ctrl', 'command']
      'cutcopy': ['ctrl+c', 'command+c', 'ctrl+x', 'command+x']

    for eventChannel, shortcut of keydown
      (=>
        channel = eventChannel
        Mousetrap.bind shortcut, (e, combo) =>
          @emit channel, e, combo
        , 'keydown'
      )()

    keypress =
      'letter': ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'x', 'w', 'y', 'z', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '=', '.', ',', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'X', 'W', 'Y', 'Z']

    for eventChannel, shortcut of keypress
      (=>
        channel = eventChannel
        Mousetrap.bind shortcut, (e, combo) =>
          @emit channel, e, combo
        , 'keypress'
      )()

dispatcher = new Dispatcher
if typeof window isnt 'undefined'
  dispatcher.initKeyboardShortcuts()

module.exports = dispatcher

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

  # make refs addable by clicking at other cells (when applicable)
  store.refEdit = true

  store.changed()
  store.rawClipboard = {} # by cleaning this here we avoid problems of people editing the
                          # copied formulas and getting the updated content when pasting
                          # (and other similarly interesting bugs).

store.registerCallback 'input-clicked', (element) ->
  caret = selix.getCaret(element)
  store.caretPosition = caret.end if caret.end == caret.start

  # when we click on an input we lose the volatileEdit mode
  store.volatileEdit = false

  # make refs addable by clicking at other cells (when applicable)
  store.refEdit = true

store.registerCallback 'input-selecttext', (element) ->
  if selix.getText element
    # make refs addable by clicking at other cells (when applicable)
    store.refEdit = true

store.registerCallback 'input-doubleclicked', (element) ->
  # make refs addable by clicking at other cells (when applicable)
  store.refEdit = true

store.registerCallback 'left-keyup', (e) ->
  if store.editingCoord and e.target.tagName == 'INPUT'
    # take note of the caret position
    store.caretPosition = selix.getCaret(e.target).start

store.registerCallback 'right-keyup', (e) ->
  if store.editingCoord and e.target.tagName == 'INPUT'
    # take note of the caret position
    store.caretPosition = selix.getCaret(e.target).end

store.registerCallback 'cell-clicked', (coord) ->
  if store.editingCoord
    valueBeingEdited = Mori.get_in(
      store.cells
      store.editingCoord.concat 'raw'
    )

    if valueBeingEdited[0] == '=' and store.refEdit or store.volatileEdit
      # clicked on a reference
      addr = utils.getAddressFromCoord coord # address is in the format 'A1'
      store.cells = Mori.update_in(
        store.cells
        store.editingCoord.concat 'raw'
        (val) ->
          caretPosition = if store.caretPosition is null then val.length else store.caretPosition

          left = val.substr 0, caretPosition
          right = val.substr caretPosition

          # check if the caret is in a suitable position for insertion of refs
          leftMatch = /[+-\/:;.*(=^><!]([A-Za-z]?\d{0,2})$/.exec(left)
          rightMatch = /^([A-Za-z]?\d{0,2})([+-\/:;.*)=^><!]|$)/.exec(right)
          if not leftMatch or not rightMatch
            return val

          # the parts of cell matched at each side of the caret should form a
          # perfect cell, otherwise they are not a cell and we can move on
          if (leftMatch[1] or rightMatch[1]) and
             (not /[A-Za-z]\d{1,2}/.exec leftMatch[1] + rightMatch[1])
            return val

          # clean near expression values
          left = left.replace /([+-/:;.*(=^><!])[^+-/:;.*(=^><!]*$/, '$1'
          right = right.replace /^[^+-/:;.*^><!)]*([+-/:;.*)^><!]|$)/, '$1'

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

    if store.strapping and store.strapVector[1] != null
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

store.registerCallback 'cell-doubleclicked', (coord) ->
  store.select coord
  store.edit coord

  # if the cell is empty, enter volatileEdit mode
  if not Mori.get_in store.cells, coord.concat 'raw'
    store.volatileEdit = true

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
  if store.volatileEdit
    store.edit null
    recalc()

  if not store.editingCoord
    if store.selectedCoord[1] > 0
      store.select [store.selectedCoord[0], store.selectedCoord[1] - 1]
    store.changed()

store.registerCallback 'right', (e) ->
  if store.volatileEdit
    store.edit null
    recalc()

  if not store.editingCoord
    if store.selectedCoord[1] < (Mori.count(Mori.get(store.cells, 0)) - 1)
      store.select [store.selectedCoord[0], store.selectedCoord[1] + 1]
    store.changed()


store.registerCallback 'all-right', ->
  if store.volatileEdit
    store.edit null
    recalc()

  if not store.editingCoord
    store.select [store.selectedCoord[0], Mori.count(Mori.get(store.cells, 0)) - 1]
  store.changed()

store.registerCallback 'all-down', ->
  if store.volatileEdit
    store.edit null
    recalc()

  if not store.editingCoord
    store.select [Mori.count(store.cells) - 1, store.selectedCoord[1]]
  store.changed()

store.registerCallback 'all-up', ->
  if store.volatileEdit
    store.edit null
    recalc()

  if not store.editingCoord
    store.select [0, store.selectedCoord[1]]
  store.changed()

store.registerCallback 'all-left', ->
  if store.volatileEdit
    store.edit null
    recalc()

  if not store.editingCoord
    store.select [store.selectedCoord[0], 0]
  store.changed()

store.registerCallback 'select-down', (e) ->
  if store.volatileEdit
    store.edit null
    recalc()

  if not store.editingCoord
    e.preventDefault()
    edge = store.multi[1]
    if edge[0] < (Mori.count(store.cells) - 1)
      store.multi = [store.selectedCoord, [edge[0] + 1, edge[1]]]
    store.changed()

store.registerCallback 'select-up', (e) ->
  if store.volatileEdit
    store.edit null
    recalc()

  if not store.editingCoord
    e.preventDefault()
    edge = store.multi[1]
    if edge[0] > 0
      store.multi = [store.selectedCoord, [edge[0] - 1, edge[1]]]
    store.changed()

store.registerCallback 'select-left', (e) ->
  if store.volatileEdit
    store.edit null
    recalc()

  if not store.editingCoord
    e.preventDefault()
    edge = store.multi[1]
    if edge[1] > 0
      store.multi = [store.selectedCoord, [edge[0], edge[1] - 1]]
    store.changed()

store.registerCallback 'select-right', (e) ->
  if store.volatileEdit
    store.edit null
    recalc()

  if not store.editingCoord
    e.preventDefault()
    edge = store.multi[1]
    if edge[1] < (Mori.count(Mori.get(store.cells, 0)) - 1)
      store.multi = [store.selectedCoord, [edge[0], edge[1] + 1]]
    store.changed()

store.registerCallback 'select-all-right', (e) ->
  if store.volatileEdit
    store.edit null
    recalc()

  if not store.editingCoord
    e.preventDefault()
    edge = store.multi[1]
    store.multi = [store.selectedCoord, [edge[0], Mori.count(Mori.get(store.cells, 0)) - 1]]
  store.changed()

store.registerCallback 'select-all-down', (e) ->
  if store.volatileEdit
    store.edit null
    recalc()

  if not store.editingCoord
    e.preventDefault()
    edge = store.multi[1]
    store.multi = [store.selectedCoord, [Mori.count(store.cells) - 1, edge[1]]]
  store.changed()

store.registerCallback 'select-all-up', (e) ->
  if store.volatileEdit
    store.edit null
    recalc()

  if not store.editingCoord
    e.preventDefault()
    edge = store.multi[1]
    store.multi = [store.selectedCoord, [0, edge[1]]]
  store.changed()

store.registerCallback 'select-all-left', (e) ->
  if store.volatileEdit
    store.edit null
    recalc()

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

    # because this editing mode always deletes the cell contents
    # we always enter the volatileEdit mode
    store.volatileEdit = true

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

store.registerCallback 'after-copypaste', ->
  store.clipboard = null
  store.changed()

module.exports = store

{recalc} = require './recalc'
expandPattern = require './expand-pattern'
