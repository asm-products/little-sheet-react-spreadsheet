React = require 'react'
mori = require 'mori'

{table, tbody, tr, td, div, span, input} = React.DOM

dispatcher = require './dispatcher'

Cell = React.createClass
  displayName: 'ReactSpreadsheetCell'

  shouldComponentUpdate: (nextProps) ->
    if mori.equals(@props.cell, nextProps.cell)
      return false
    else
      return true

  wasEditing: false
  componentDidUpdate: (prevProps) ->
    if @refs.input

  render: ->
    if mori.get @props.cell, 'editing'
      shownValue = mori.get @props.cell, 'raw'
    else
      shownValue = mori.get @props.cell 'calc'

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
        (span
          onClick: @handleClick
          onDoubleClick: @handleDoubleClick
          onTouchStart: @handleRouchStart
          onTouchEnd: @handleRouchEnd
          onTouchCancel: @handleRouchEnd
          onMouseDown: @handleMouseDown
        , shownValue)
      )
      (div
        className: 'strap'
        onMouseDown: @handleMouseDownStrap
      ) if mori.get @props.cell, 'last-multi'
    )

  handleClickInput: (e) ->
    dispatcher.handleCellInputClicked e

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
