Mori = require 'mori'
utils = require './utils'
store = require './cells-store'

calculated = {}
flush = -> calculated = {}

module.exports.getUtils = ->
  getCalcResultAt: -> getCalcResultAt.apply @, arguments
  getMatrixValues: -> getMatrixValues.apply @, arguments

module.exports.recalc = ->
  flush()

  for i in [0..(Mori.count(store.cells)-1)]
    for j in [0..(Mori.count(Mori.get(store.cells, 0))-1)]
      addr = utils.getAddressFromCoord([i, j])
      raw = Mori.get_in(store.cells, [i, j, 'raw'])
      calcRes = if raw[0] == '=' and raw.slice 1 then getCalcResult raw else raw
      calculated[addr.toUpperCase()] = calcRes if typeof calcRes == 'number'
      store.cells = Mori.assoc_in(store.cells, [i, j, 'calc'], calcRes)

  # after the recalc is done, save state
  store.redoStates = Mori.list()
  store.undoStates = Mori.conj store.undoStates, store.cells
  store.canUndo = true
  store.canRedo = false

getCalcResultAt = (addr) ->
  addr = addr.toUpperCase()
  if addr of calculated
    return calculated[addr]
  else
    coord = utils.getCoordFromAddress(addr)
    raw = Mori.get_in(
      store.cells
      coord.concat 'raw'
      ''
    )
    return getCalcResult raw

getCalcResult = (raw) ->
  if raw[0] == '='
    return parser.parse raw.slice 1
  else
    return parseStr raw

parseStr = (raw) ->
  return 0 if not raw.length

  f = parseFloat raw
  if not isNaN(f) and isFinite(raw)
    return f
  else
    return raw

getMatrixValues = (start, end) ->
  colStart = start[0].toUpperCase().charCodeAt(0) - 65 # A turns into 0
  colEnd   = end[0].toUpperCase().charCodeAt(0) - 65
  rowStart = start.slice(1) - 1 # 1 turns into 0
  rowEnd   = end.slice(1) - 1

  matrix = []
  for i in [rowStart..rowEnd]
    rowArray = []
    for j in [colStart..colEnd]
      addr = utils.getAddressFromCoord [i, j]
      rowArray.push getCalcResultAt addr
    matrix.push rowArray

  return matrix

parser = require './formula-parser'
