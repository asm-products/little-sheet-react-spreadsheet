Mori = require 'mori'
utils = require './utils'
store = require './cells-store'

module.exports = ->
  base = [utils.firstCellFromMulti(store.multi), utils.lastCellFromMulti(store.multi)]
  vector = store.strapVector
  magnitude = vector[2]

  if vector[0] == 0
    # expand vertically
    for j in [base[0][1]..base[1][1]] # -> columns
      # get the values
      column = []
      # start at the end if the sense (vector[1]) is 0
      #                 0 if heading ->           1 if heading ->
      for i in [base[  1-vector[1]  ][0]..base[   vector[1]   ][0]]
        column.push Mori.get_in(store.cells, [i, j, 'raw'])

      # identify pattern
      generator = identifyPattern column, vector[0]

      # apply pattern
      #         -1 if left/up, 1 if right/down
      for s in [(magnitude/Math.abs(magnitude))..magnitude]

        # the math here is the same as in the "heavy math" under
        # store.getCells.
        si = base[vector[1]][vector[0]] + s

        store.cells = Mori.assoc_in(
          store.cells
          [si, j, 'raw']
          generator(s)
        )

  else if vector[0] == 1
    # expand horizontally
    for i in [base[0][0]..base[1][0]] # -> rows
      # get the values
      row = []
      # start at the end if the sense (vector[1]) is 0
      #                 0 if heading ->           1 if heading ->
      for j in [base[  1-vector[1]  ][1]..base[   vector[1]   ][1]]
        row.push Mori.get_in(store.cells, [i, j, 'raw'])

      # identify pattern
      generator = identifyPattern row, vector[0]

      # apply pattern
      #         -1 if left/up, 1 if right/down
      for s in [(magnitude/Math.abs(magnitude))..magnitude]

        # the math here is the same as in the "heavy math" under
        # store.getCells.
        sj = base[vector[1]][vector[0]] + s

        store.cells = Mori.assoc_in(
          store.cells
          [i, sj, 'raw']
          generator(s)
        )

  

identifyPattern = (values, dir) ->
  # creates a generator that will accept a delta
  # and return the cell value at that point.

  direction = if dir == 0 then 'vertical' else 'horizontal' # see callback for 'cell-mouseenter'
  baseValues = values

  # sequence of numbers
  rateGeneratorFns =
    arit: (r) -> (a, delta) -> parseFloat(a) + (r*delta)
    geom: (r) -> (a, delta) -> parseFloat(a) * (r*delta)

  if values.length > 1
    rateFns =
      arit: (a, b) -> parseFloat(a) - parseFloat(b)
      geom: (a, b) -> parseFloat(a) / parseFloat(b)
    rateValues = {}
    for rateName, fn of rateFns
      rateValues[rateName] = fn values[1], values[0]

    if values.length > 2
      for n in [2..values.length-1]
        for rateName, rateValue of rateValues
          if rateFns[rateName](values[n], values[n-1]) != rateValue
            delete rateValues[rateName]

    for rateName in ['arit', 'geom', 'expo']
      if rateValues[rateName]
        rateValue = rateValues[rateName]
        rateFn = rateGeneratorFns[rateName](rateValue)
        break

  else if !isNaN(parseInt(values[0]))
    rateFn = rateGeneratorFns.arit(1)

  else if values[0].charCodeAt and values[0].length == 1
    rateFn = (a, delta) -> String.fromCharCode(a.charCodeAt() + delta)

  else
    rateFn = null

  # the generator
  return (delta) ->
    baseValue = baseValues[(Math.abs(delta)-1) % baseValues.length]

    # if none match, repeat the values of the pattern sequentially
    value = baseValue

    # always walk with cell references left, right, up or down
    if 'horizontal' == direction
      value = baseValue.toString().replace /(\$?[A-Za-z])(\$?\d{1,2})/g, (_, letter, number) ->
        if letter[0] != '$'
          letter = String.fromCharCode letter.charCodeAt() + delta
        return letter + number
    else if 'vertical' == direction
      value = baseValue.toString().replace /([\$?A-Za-z])(\$?\d{1,2})/g, (_, letter, number) ->
        if number[0] != '$'
          number = parseInt(number) + delta
        return letter + number

    # number, compute
    if rateFn
      value = rateFn baseValues.slice(-1)[0], Math.abs(delta)

    return value
