React = require 'react'
mori = require 'mori'

{div, input} = React.DOM

InputField = React.createClass
  componentDidMount: ->
    @refs.input.getDOMNode().focus()

  componentDidUpdate: ->
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

  componentWillUnmount: ->
    @wasEditing = false

  render: ->
    (input
      ref: 'input'
      className: 'mousetrap'
      onChange: @handleChange
      onClick: @handleClickInput
      onDoubleClick: @handleDoubleClickInput
      onSelect: @handleSelectText
      value: mori.get @props.cell, 'raw'
    )

module.exports = InputField
