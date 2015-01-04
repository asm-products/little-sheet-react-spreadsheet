module.exports =
  letters: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  getAddressFromCoord: (coord) ->
    # takes a coord in the format `[2, 4]`
    # and returns an address in  the format `'E3'`
    return @letters[coord[1]] + (coord[0] + 1)
  getCoordFromAddress: (->
    addrIndex = {}

    return (addr) ->
      if addr not of addrIndex
        addrIndex[addr] = [(parseInt(addr.slice 1) - 1), letters.indexOf addr[0]]
      return addrIndex[addr]
  )()
  firstCellFromMulti: (multi) ->
    return [
      Math.min(multi[0][0], multi[1][0])
      Math.min(multi[0][1], multi[1][1])
    ]
  lastCellFromMulti: (multi) ->
    return [
      Math.max(multi[0][0], multi[1][0])
      Math.max(multi[0][1], multi[1][1])
    ]
  equalCoords: (coord1, coord2) ->
    return false if not coord1 or not coord2
    return coord1[0] == coord2[0] and coord1[1] == coord2[1]
  isInMulti: (cell, multi) ->
    if (multi[0][0] >= cell[0] and cell[0] >= multi[1][0] or
        multi[1][0] >= cell[0] and cell[0] >= multi[0][0]) and

       (multi[0][1] >= cell[1] and cell[1] >= multi[1][1] or
        multi[1][1] >= cell[1] and cell[1] >= multi[0][1])
      return true
    return false
  log: (res, base) -> Math.log(res)/Math.log(base)
