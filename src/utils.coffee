
letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
getAddressFromCoord = (coord) ->
  # takes a coord in the format `[2, 4]`
  # and returns an address in  the format `'E3'`
  return letters[coord[1]] + (coord[0] + 1)

addrIndex = {}
getCoordFromAddress = (addr) ->
  if addr not of addrIndex
    addrIndex[addr] = [(parseInt(addr.slice 1) - 1), letters.indexOf addr[0]]
  return addrIndex[addr]

firstCellFromMulti = (multi) ->
  return [
    Math.min(multi[0][0], multi[1][0])
    Math.min(multi[0][1], multi[1][1])
  ]

lastCellFromMulti = (multi) ->
  return [
    Math.max(multi[0][0], multi[1][0])
    Math.max(multi[0][1], multi[1][1])
  ]

module.exports =
  letters: letters
  getAddressFromCoord: getAddressFromCoord
  getCoordFromAddress: getCoordFromAddress
  firstCellFromMulti: firstCellFromMulti
  lastCellFromMulti: lastCellFromMulti
  log: (res, base) -> Math.log(res)/Math.log(base)
