React = require 'react'
Spreadsheet = require './Spreadsheet'

module.exports = (opts, target) ->
  React.renderComponent Spreadsheet(opts), target
