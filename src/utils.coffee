
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

`
function doGetCaretPosition (oField) {

  // Initialize
  var iCaretPos = 0;

  // IE Support
  if (document.selection) {

    // Set focus on the element
    oField.focus ();

    // To get cursor position, get empty selection range
    var oSel = document.selection.createRange ();

    // Move selection start to 0 position
    oSel.moveStart ('character', -oField.value.length);

    // The caret position is selection length
    iCaretPos = oSel.text.length;
  }

  // Firefox support
  else if (oField.selectionStart || oField.selectionStart == '0')
    iCaretPos = oField.selectionStart;

  // Return results
  return (iCaretPos);
}
`

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
  getCaretPosition: doGetCaretPosition
  firstCellFromMulti: firstCellFromMulti
  lastCellFromMulti: lastCellFromMulti
