hg = require 'mercury'
ObservGrid = require 'observ-grid'
flatten = require 'flatten'
utils = require './utils'

Store = (rawValues=[[]]) ->
  h = rawValues.length or 4
  v = rawValues[0].length or 4
  raw = ObservGrid flatten(rawValues), [h, v]
  calc = ObservGrid flatten(rawValues), [h, v]

  state = hg.state
    raw: raw
    calc: calc

    selectedCoord: hg.value [0, 0]
    multi: hg.value [[0, 0], [0, 0]]
    editingCoord: hg.value null

    strapping: hg.value false
    strapVector: hg.value [null, null, null]

    volatileEdit: hg.value false # volatileEdit is a mode of edition in which it is easy to stop editing,
                                 # by pressing left or right, for example.
                                 # useful when we are quickly adding a lot of records to a sheet
    customHandlers: hg.varhash()

  state.customHandlers.put 'select', hg.value Store.select.bind null, state
  state.customHandlers.put 'edit', hg.value Store.edit.bind null, state
  state.customHandlers.put 'getCell', hg.value Store.getCell.bind null, state

  return state

Store.select = (state, coord) ->
  state.selectedCoord.set coord
  state.multi.set [coord, coord]

Store.edit = (state, coord) ->
  state.editingCoord.set coord
  state.selectedCoord.set null
  state.multi.set [null, null]

Store.getCell = (state, coord) ->
  multi = state.multi()
  strapVector = state.strapVector()

  # get the highlighted area, considering eventual strap movements
  if strapVector[1] != null
    # this only works if the first is the first and the second is the second
    highlight = [utils.firstCellFromMulti(multi), utils.lastCellFromMulti(multi)]
    # plus, we gain a free cloning of multi into something we can modify with

    # heavy math:
    #         left/top or right/bottom    vertical or horizontal  
    highlight[     strapVector[1]     ][     strapVector[0]     ] += strapVector[2]
  else
    highlight = multi

  inHighlightedArea = utils.isInMulti coord, highlight

  raw: state.raw.get.apply null, coord
  calc: state.calc.get.apply null, coord
  editing: utils.equalCoords coord, state.editingCoord()
  selected: utils.equalCoords coord, state.selectedCoord()
  highlight: inHighlightedArea
  showStrap: inHighlightedArea and utils.equalCoords utils.lastCellFromMulti(highlight), coord

module.exports = Store
