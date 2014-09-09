React = require 'react'
mori = require 'mori'

{table, tbody, tr, td, div, span, input} = React.DOM

dispatcher = require './dispatcher.coffee'

Cell = React.createClass
  displayName: 'ReactMicroSpreadsheetCell'

  shouldComponentUpdate: (nextProps) ->
    if mori.equals @props.cell, nextProps.cell
      return false
    else
      return true

  componentDidUpdate: ->
    if @refs.input
      node = @refs.input.getDOMNode()
      node.focus()
      node.setSelectionRange node.value.length, node.value.length

  render: ->
    (td
      className:
        'cell ' +
        if mori.get('selected', @props.cell) then 'selected' else ''
    ,
      (div {},
        (input
          ref: 'input'
          className: 'mousetrap'
          onChange: @handleChange
          value: mori.get @props.cell, 'raw'
        ) if mori.get 'editing', @props.cell
        (span
          onClick: @handleClick
          onDoubleClick: @handleDoubleClick
        ,
          mori.get @props.cell, 'calc'
        ) unless mori.get 'editing', @props.cell
      )
    )

  handleChange: (e) ->
    e.preventDefault()
    dispatcher.handleCellEdited e.target.value

  handleClick: (e) ->
    e.preventDefault()
    dispatcher.handleCellClicked [@props.rowKey, @props.key] # this is the coord [i, j]

  handleDoubleClick: (e) ->
    e.preventDefault()
    dispatcher.handleCellDoubleClicked [@props.rowKey, @props.key]

module.exports = Cell
