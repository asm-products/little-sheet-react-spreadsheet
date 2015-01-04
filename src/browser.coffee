hg = require 'mercury'

module.exports = (cells) ->
  Spreadsheet = require './spreadsheet'
  hg.app document.body, Spreadsheet(cells), Spreadsheet.render
