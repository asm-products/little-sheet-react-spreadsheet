Mousetrap = require 'mousetrap'
React = require 'react/addons'
testUtils = React.addons.TestUtils
expect = chai.expect

Spreadsheet = require '../src/Spreadsheet.coffee'

utils =
  reset: ->
    React.unmountComponentAtNode($('div#test-node')[0])
    $('div#test-node').remove()

  testNode: ->
    testNode = $('<div>').attr('id', 'test-node')
    $('body').append(testNode)
    testNode.empty()
    return testNode[0]

describe 'basic', ->
  this.timeout 50000
  describe 'text cells', ->
    before (done) ->
      cells = [
        ['','123','','123']
        ['asd','','sad','']
        ['','as','','sd']
        ['das','','123','']
      ]
      React.renderComponent Spreadsheet(cells: cells), utils.testNode(), done
    after utils.reset

    it 'renders the table', (done) ->
      expect($('table.spreadsheet')).to.exist
      done()

    it 'renders the rows and cells at the right places', (done) ->
      cells = []
      for row in $('.spreadsheet tr')
        rowArray = []
        for cell in $(row).find('td')
          rowArray.push $(cell).text()
        cells.push rowArray

      expect(cells[0]).to.eql ['', 'A', 'B', 'C', 'D']
      expect(cells[1]).to.eql ['1', '', '123', '', '123']
      expect(cells[4]).to.eql ['4', 'das', '', '123', '']
      done()

  describe 'formulas (refs, expressions and sum() with matrixes)', (done) ->
    before (done) ->
      cells = [
        ['=A2','123']
        ['7','=B1+A2']
        ['=2+B3','=1+2']
        ['=SUM(A1,A2)','=sUm(A1:B2)']
      ]
      React.renderComponent Spreadsheet(cells: cells), utils.testNode(), done

    it 'renders the table', (done) ->
      expect($('table.spreadsheet')).to.exist
      done()

    it 'renders the rows and cells with the right values', (done) ->
      cells = []
      for row in $('.spreadsheet tr')
        rowArray = []
        for cell in $(row).find('td')
          rowArray.push $(cell).text()
        cells.push rowArray

      expect(cells[1]).to.eql ['1', '7', '123']
      expect(cells[2]).to.eql ['2', '7', '130']
      expect(cells[3]).to.eql ['3', '5', '3']
      expect(cells[4]).to.eql ['4', '14', '267']
      done()

  describe 'dbclick, edit, click outside', ->
    sheet = null
    secondCell = null
    input = null

    before (done) ->
      cells = [
        ['44','123']
        ['7','']
        ['=SUM(A1,A2)','=sUm(A1:B2)']
      ]
      sheet = React.renderComponent Spreadsheet(cells: cells), utils.testNode(), done

    after utils.reset

    it 'finds the second cell and starts editing', (done) ->
      secondCell = testUtils.scryRenderedDOMComponentsWithClass(sheet, 'cell')[1]
      span = testUtils.findRenderedDOMComponentWithTag(secondCell, 'span')
      testUtils.Simulate.doubleClick(span)

      expect($('.spreadsheet .cell input')[0]).to.exist
      expect($('.spreadsheet .cell input').val()).to.eql '123'
      done()

    it 'changes its value', (done) ->
      input = testUtils.findRenderedDOMComponentWithTag(secondCell, 'input')
        
      testUtils.Simulate.change(input, {target: {value: '16'}})
      expect($('.spreadsheet .cell input').val()).to.eql '16'
      done()

    it 'click at other cell and the table recalculates', (done) ->
      $('.spreadsheet .cell span').eq(3).click()

      expect($('.spreadsheet .cell input').length).to.eql 0
      expect($('.spreadsheet .cell').eq(1).text()).to.eql '16'
      expect($('.spreadsheet .cell').eq(4).text()).to.eql '51'
      expect($('.spreadsheet .cell').eq(5).text()).to.eql '67'
      done()

  describe 'change it from outside', ->
    sheet = null
    before (done) ->
      cells = [
        ['=A2','123']
        ['7','=B1+A2']
        ['=2+B3','=1+2']
        ['=SUM(A1,A2)','=sUm(A1:B2)']
      ]
      sheet = React.renderComponent Spreadsheet(cells: cells), utils.testNode(), done
    after utils.reset

    it 'renders the rows and cells with the right values', (done) ->
      cells = []
      for row in $('.spreadsheet tr')
        rowArray = []
        for cell in $(row).find('td')
          rowArray.push $(cell).text()
        cells.push rowArray

      expect(cells[1]).to.eql ['1', '7', '123']
      expect(cells[2]).to.eql ['2', '7', '130']
      expect(cells[3]).to.eql ['3', '5', '3']
      expect(cells[4]).to.eql ['4', '14', '267']
      done()

    it 'changes when the `cells` prop changes', (done) ->
      cells = [
        ['x3', '=A1']
        ['', '']
        ['', '']
        ['', '']
        ['', '']
        ['b', 'c']
      ]
      sheet.setProps cells: cells
      cells = []
      for row in $('.spreadsheet tr')
        rowArray = []
        for cell in $(row).find('td')
          rowArray.push $(cell).text()
        cells.push rowArray

      expect(cells[1]).to.eql ['1', 'x3', 'x3']
      expect(cells[2]).to.eql ['2', '', '']
      expect(cells[3]).to.eql ['3', '', '']
      expect(cells[4]).to.eql ['4', '', '']
      expect(cells[5]).to.eql ['5', '', '']
      expect(cells[6]).to.eql ['6', 'b', 'c']
      done()
      
  describe 'click to add reference', ->
    sheet = null
    secondCell = null
    input = null

    before (done) ->
      cells = [
        ['5','2']
        ['7','9']
      ]
      sheet = React.renderComponent Spreadsheet(cells: cells), utils.testNode(), done
    after utils.reset

    it 'finds the second cell and starts editing', (done) ->
      secondCell = testUtils.scryRenderedDOMComponentsWithClass(sheet, 'cell')[1]
      span = testUtils.findRenderedDOMComponentWithTag(secondCell, 'span')
      testUtils.Simulate.doubleClick(span)
      done()

    it 'adds a "="', (done) ->
      input = testUtils.findRenderedDOMComponentWithTag(secondCell, 'input')
      testUtils.Simulate.change(input, {target: {value: '='}})
      expect($('.spreadsheet .cell input').val()).to.eql '='
      done()

    it 'clicks at other cell and add its addr to the input', (done) ->
      fourthCell = testUtils.scryRenderedDOMComponentsWithClass(sheet, 'cell')[3]
      span = testUtils.findRenderedDOMComponentWithTag(fourthCell, 'span')
      testUtils.Simulate.click(span)
      expect($('.spreadsheet .cell input').val()).to.eql '=B2'
      done()

    it 'clicks at another cell and replace the previous one', (done) ->
      thirdCell = testUtils.scryRenderedDOMComponentsWithClass(sheet, 'cell')[2]
      span = testUtils.findRenderedDOMComponentWithTag(thirdCell, 'span')
      testUtils.Simulate.click(span)
      expect($('.spreadsheet .cell input').val()).to.eql '=A2'
      done()

    it 'recalculates when enter is pressed', (done) ->
      KeyEvent.simulate(0, 13)

      expect($('.spreadsheet .cell input').length).to.eql 0
      expect($('.spreadsheet .cell').eq(1).text()).to.eql '7'
      expect($('.spreadsheet .cell').eq(2).text()).to.eql '7'
      expect($('.spreadsheet .cell').eq(3).text()).to.eql '9'
      done()

  describe 'movement and keyboard shortcuts', ->
    before (done) ->
      cells = [
        ['5','2']
        ['7','9']
      ]
      React.renderComponent Spreadsheet(cells: cells), utils.testNode(), done
    after utils.reset

    it 'starts at the first cell', (done) ->
      expect($('.spreadsheet .cell').eq(0).hasClass('selected')).to.eql true
      done()

    it 'goes right', (done) ->
      KeyEvent.simulate(0, 39)
      expect($('.spreadsheet .cell').eq(1).hasClass('selected')).to.eql true
      done()

    it 'deletes the content inside', (done) ->
      KeyEvent.simulate(0, 46)
      expect($('.spreadsheet .cell span').eq(1).text()).to.eql ''
      done()

    it 'does not go up', (done) ->
      KeyEvent.simulate(0, 38)
      expect($('.spreadsheet .cell').eq(1).hasClass('selected')).to.eql true
      done()
      
    it 'goes down', (done) ->
      KeyEvent.simulate(0, 40)
      expect($('.spreadsheet .cell').eq(3).hasClass('selected')).to.eql true
      done()

    it 'starts editing with a keypress (also replacing the text field with the corresponding char)', (done) ->
      KeyEvent.simulate(80, 80)

      expect($('.spreadsheet .cell').eq(3).hasClass('selected')).to.eql true
      expect($('.spreadsheet .cell input')).to.have.length 1
      expect($('.spreadsheet .cell input').val()).to.eql 'P'
      done()

    it 'cancels the edit', (done) ->
      KeyEvent.simulate(0, 27)
      expect($('.spreadsheet .cell').eq(3).text()).to.eql '9'
      done()

  describe 'undo, redo', ->
    before (done) ->
      cells = [
        ['a', 'b']
        ['c', 'd']
      ]
      React.renderComponent Spreadsheet(cells: cells), utils.testNode(), done
    after utils.reset

    it 'starts editing with a keypress (also replacing the text field with the corresponding char)', (done) ->
      KeyEvent.simulate(81, 81)

      expect($('.spreadsheet .cell input').val()).to.eql 'Q'
      done()

    it 'saves the edit', (done) ->
      KeyEvent.simulate(0, 13)

      expect($('.spreadsheet .cell span').length).to.eql 4
      expect($('.spreadsheet .cell span').eq(0).text()).to.eql 'Q'
      done()

    it 'undoes the edit', (done) ->
      KeyEvent.simulate(90, 90, ['ctrl'])
    
      expect($('.spreadsheet .cell span').eq(0).text()).to.eql 'a'
      done()

    it 'redoes the edit', (done) ->
      KeyEvent.simulate(89, 89, ['ctrl'])

      expect($('.spreadsheet .cell span').eq(0).text()).to.eql 'Q'
      done()

  describe 'multi select', ->
    sheet = null
    before (done) ->
      cells = [
        ['', 'b']
        ['a', '']
        ['', '']
        ['', '']
      ]
      sheet = React.renderComponent Spreadsheet(cells: cells), utils.testNode(), done
    after utils.reset

    it 'starts selecting', (done) ->
      first = testUtils.findRenderedDOMComponentWithTag(testUtils.scryRenderedDOMComponentsWithClass(sheet, 'cell')[0], 'span')
      testUtils.Simulate.mouseDown(first)

      expect($('.spreadsheet .cell').eq(0).hasClass('multi-selected')).to.eql false
      expect($('.spreadsheet .cell').eq(1).hasClass('multi-selected')).to.eql false
      expect($('.spreadsheet .cell').eq(2).hasClass('multi-selected')).to.eql false
      expect($('.spreadsheet .cell').eq(3).hasClass('multi-selected')).to.eql false
      done()

    it 'moves transversally', (done) ->
      first = testUtils.findRenderedDOMComponentWithTag(testUtils.scryRenderedDOMComponentsWithClass(sheet, 'cell')[0], 'span')
      third = testUtils.findRenderedDOMComponentWithTag(testUtils.scryRenderedDOMComponentsWithClass(sheet, 'cell')[2], 'span')

      testUtils.SimulateNative.mouseOut(first, {relatedTarget: $('.spreadsheet .cell').eq(2)[0]})
      testUtils.SimulateNative.mouseOver(third, {relatedTarget: $('.spreadsheet .cell').eq(0)[0]})

      expect($('.spreadsheet .cell').eq(0).hasClass('multi-selected')).to.eql true
      expect($('.spreadsheet .cell').eq(1).hasClass('multi-selected')).to.eql true
      expect($('.spreadsheet .cell').eq(2).hasClass('multi-selected')).to.eql true
      expect($('.spreadsheet .cell').eq(3).hasClass('multi-selected')).to.eql false
      done()

    it 'moves back and the selection adjusts', (done) ->
      third = testUtils.findRenderedDOMComponentWithTag(testUtils.scryRenderedDOMComponentsWithClass(sheet, 'cell')[2], 'span')
      second = testUtils.findRenderedDOMComponentWithTag(testUtils.scryRenderedDOMComponentsWithClass(sheet, 'cell')[1], 'span')

      testUtils.SimulateNative.mouseOut(third, {relatedTarget: $('.spreadsheet .cell').eq(1)[0]})
      testUtils.SimulateNative.mouseOver(second, {relatedTarget: $('.spreadsheet .cell').eq(2)[0]})

      expect($('.spreadsheet .cell').eq(0).hasClass('multi-selected')).to.eql true
      expect($('.spreadsheet .cell').eq(1).hasClass('multi-selected')).to.eql true
      expect($('.spreadsheet .cell').eq(2).hasClass('multi-selected')).to.eql false
      done()

    it 'stops selecting and the selection continues', (done) ->
      second = testUtils.findRenderedDOMComponentWithTag(testUtils.scryRenderedDOMComponentsWithClass(sheet, 'cell')[1], 'span')
      testUtils.Simulate.mouseUp(second)

      expect($('.spreadsheet .cell').eq(0).hasClass('multi-selected')).to.eql true
      expect($('.spreadsheet .cell').eq(1).hasClass('multi-selected')).to.eql true
      expect($('.spreadsheet .cell').eq(2).hasClass('multi-selected')).to.eql false
      done()

    it 'deletes everything under the selection', (done) ->
      KeyEvent.simulate(0, 46)

      expect($('.spreadsheet .cell').eq(0).text()).to.eql ''
      expect($('.spreadsheet .cell').eq(1).text()).to.eql ''
      expect($('.spreadsheet .cell').eq(2).text()).to.eql 'a'
      done()
