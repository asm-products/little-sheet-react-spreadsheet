React = require 'react'
mori = require 'mori'

{table, tbody, tr, td, div, span, input} = React.DOM

dispatcher = require './dispatcher'

Cell = React.createClass
  displayName: 'ReactMicroSpreadsheetCell'

  shouldComponentUpdate: (nextProps) ->
    if mori.equals(@props.cell, nextProps.cell)
      return false
    else
      return true

  wasEditing: false
  componentDidUpdate: ->
    if @refs.input and not @wasEditing
      node = @refs.input.getDOMNode()
      node.focus()
      node.setSelectionRange node.value.length, node.value.length
      @wasEditing = true
    if not @refs.input
      @wasEditing = false

  render: ->
    (td
      className:
        'cell ' +
        if mori.get(@props.cell, 'selected') then 'selected' else ''
    ,
      (div {},
        if mori.get @props.cell, 'editing' then (input
          ref: 'input'
          className: 'mousetrap'
          onChange: @handleChange
          value: mori.get @props.cell, 'raw'
        ) else (span
          onClick: @handleClick
          onDoubleClick: @handleDoubleClick
        ,
          mori.get @props.cell, 'calc'
        )
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
