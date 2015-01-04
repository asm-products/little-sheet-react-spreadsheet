hg = require 'mercury'
{div, textarea} = require 'virtual-elements'

clipboardChanged = (state, what) ->
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

Clipboard = ->
  hg.state
    value: ''
    raw: ''

    channels:
      change: clipboardChanged

Clipboard.render = (state) ->
  (div className: 'clipboard-container',
    (textarea
      className: 'mousetrap clipboard'
      ref: 'clipboard'
      value: state.value
      'ev-input': hg.sendValue state.channels.change
      hooks:
        hook: (elem) ->
          elem.focus()
          elem.setSelectionRange 0, elem.value.length
    ) if state.value
  )

module.exports = Clipboard
