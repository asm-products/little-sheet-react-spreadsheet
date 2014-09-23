React = require 'react'
Spreadsheet = require './Spreadsheet.coffee'

module.exports = (opts, target) ->
  React.renderComponent Spreadsheet(opts), target
