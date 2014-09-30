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
  componentDidUpdate: (prevProps) ->
    if @refs.input
      node = @refs.input.getDOMNode()
      caret = if @props.caretPosition is null then node.value.length else @props.caretPosition
      if not @wasEditing
        node.focus()
        node.setSelectionRange caret, caret
        @wasEditing = true
      else if node != document.activeElement
        node.focus()
        node.setSelectionRange caret, caret
      else if @props.caretPosition isnt null and
              @props.caretPosition != prevProps.caretPosition
        node.setSelectionRange caret, caret
    if not @refs.input
      @wasEditing = false

  render: ->
    (td
      className: "cell #{
        if mori.get(@props.cell, 'selected') then 'selected' else ''
      } #{
        if mori.get(@props.cell, 'multi') then 'multi-selected' else ''
      }"
      onMouseUp: @handleMouseUp
      onMouseEnter: @handleMouseEnter
    ,
      (div {},
        if mori.get @props.cell, 'editing' then (input
          ref: 'input'
          className: 'mousetrap'
          onChange: @handleChange
          onClick: @handleClickInput
          onDoubleClick: @handleDoubleClickInput
          onSelect: @handleSelectText
          value: mori.get @props.cell, 'raw'
        ) else (span
          onClick: @handleClick
          onDoubleClick: @handleDoubleClick
          onTouchStart: @handleRouchStart
          onTouchEnd: @handleRouchEnd
          onTouchCancel: @handleRouchEnd
          onMouseDown: @handleMouseDown
        ,
          mori.get @props.cell, 'calc'
        )
      )
      (div
        className: 'strap'
        onMouseDown: @handleMouseDownStrap
      ) if mori.get @props.cell, 'last-multi'
    )

  handleChange: (e) ->
    e.preventDefault()
    dispatcher.handleCellEdited e.target.value

  handleClickInput: (e) ->
    dispatcher.handleCellInputClicked e

  handleDoubleClickInput: (e) ->
    dispatcher.handleCellInputDoubleClicked e

  handleSelectText: (e) ->
    dispatcher.handleSelectText e

  handleClick: (e) ->
    e.preventDefault()
    dispatcher.handleCellClicked [@props.rowKey, @props.key] # this is the coord [i, j]

  handleDoubleClick: (e) ->
    e.preventDefault()
    dispatcher.handleCellDoubleClicked [@props.rowKey, @props.key]

  handleTouchStart: (e) ->
    @timer = setTimeout @handleLongTouch, 700

  handleTouchEnd: (e) ->
    clearTimeout @timer

  handleLongTouch: ->
    dispatcher.handleCellDoubleClicked [@props.rowKey, @props.key]

  handleMouseDownStrap: (e) ->
    e.stopPropagation()
    e.preventDefault()
    dispatcher.handleMouseDownStrap [@props.rowKey, @props.key]

  handleMouseDown: (e) ->
    e.preventDefault()
    dispatcher.handleCellMouseDown [@props.rowKey, @props.key]

  handleMouseUp: (e) ->
    dispatcher.handleCellMouseUp [@props.rowKey, @props.key]

  handleMouseEnter: (e) ->
    e.preventDefault()
    dispatcher.handleCellMouseEnter [@props.rowKey, @props.key]

module.exports = Cell
