hg = require 'mercury'

{table, tbody, tr, td, div, span, input} = require 'virtual-elements'

Cell = module.exports

Cell.render = (state) ->
  (td
    className: """cell #{if state.selected then 'selected' else ''}
                       #{if state.highlight then 'multi-selected' else ''}"""
    #'ev-mouseup': @handleMouseUp
    #'ev-mouseenter': @handleMouseEnter
  ,
    (div {},
      if state.editing then (span {}
        #'ev-change': @handleChange
        #'ev-click': @handleClickInput
        #'ev-dblclick': @handleDoubleClickInput
        #'ev-select': @handleSelectText
      , state.raw) else (span {}
        #'ev-click': @handleClick
        #'ev-dblclick': @handleDoubleClick
        #'ev-touchstart': @handleRouchStart
        #'ev-touchend': @handleRouchEnd
        #'ev-touchcancel': @handleRouchEnd
        #'ev-mousedown': @handleMouseDown
      , state.calc)
    )
    (div
      className: 'strap'
      'ev-mousedown': @handleMouseDownStrap
    ) if state.showStrap
  )

#handleChange: (e) ->
#  e.preventDefault()
#  dispatcher.handleCellEdited e.target.value

#handleClickInput: (e) ->
#  dispatcher.handleCellInputClicked e

#handleDoubleClickInput: (e) ->
#  dispatcher.handleCellInputDoubleClicked e

#handleSelectText: (e) ->
#  dispatcher.handleSelectText e

#handleClick: (e) ->
#  e.preventDefault()
#  dispatcher.handleCellClicked [@props.rowKey, @props.key] # this is the coord [i, j]

#handleDoubleClick: (e) ->
#  e.preventDefault()
#  dispatcher.handleCellDoubleClicked [@props.rowKey, @props.key]

#handleTouchStart: (e) ->
#  @timer = setTimeout @handleLongTouch, 700

#handleTouchEnd: (e) ->
#  clearTimeout @timer

#handleLongTouch: ->
#  dispatcher.handleCellDoubleClicked [@props.rowKey, @props.key]

#handleMouseDownStrap: (e) ->
#  e.stopPropagation()
#  e.preventDefault()
#  dispatcher.handleMouseDownStrap [@props.rowKey, @props.key]

#handleMouseDown: (e) ->
#  e.preventDefault()
#  dispatcher.handleCellMouseDown [@props.rowKey, @props.key]

#handleMouseUp: (e) ->
#  dispatcher.handleCellMouseUp [@props.rowKey, @props.key]

#handleMouseEnter: (e) ->
#  e.preventDefault()
#  dispatcher.handleCellMouseEnter [@props.rowKey, @props.key]

module.exports = Cell
