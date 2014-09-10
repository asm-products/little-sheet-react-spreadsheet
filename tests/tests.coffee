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
      expect($('table.microspreadsheet')).to.exist
      done()

    it 'renders the rows and cells at the right places', (done) ->
      cells = []
      for row in $('.microspreadsheet tr')
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
      expect($('table.microspreadsheet')).to.exist
      done()

    it 'renders the rows and cells with the right values', (done) ->
      cells = []
      for row in $('.microspreadsheet tr')
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

      expect($('.microspreadsheet .cell input')[0]).to.exist
      expect($('.microspreadsheet .cell input').val()).to.eql '123'
      done()

    it 'changes its value', (done) ->
      input = testUtils.findRenderedDOMComponentWithTag(secondCell, 'input')
        
      testUtils.Simulate.change(input, {target: {value: '16'}})
      expect($('.microspreadsheet .cell input').val()).to.eql '16'
      done()

    it 'click at other cell and the table recalculates', (done) ->
      $('.microspreadsheet .cell span').eq(3).click()

      expect($('.microspreadsheet .cell input').length).to.eql 0
      expect($('.microspreadsheet .cell').eq(1).text()).to.eql '16'
      expect($('.microspreadsheet .cell').eq(4).text()).to.eql '51'
      expect($('.microspreadsheet .cell').eq(5).text()).to.eql '67'
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
      for row in $('.microspreadsheet tr')
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
      for row in $('.microspreadsheet tr')
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
      expect($('.microspreadsheet .cell input').val()).to.eql '='
      done()

    it 'clicks on another cell and add its addr to the input', (done) ->
      fourthCell = testUtils.scryRenderedDOMComponentsWithClass(sheet, 'cell')[3]
      span = testUtils.findRenderedDOMComponentWithTag(fourthCell, 'span')
      testUtils.Simulate.click(span)
      expect($('.microspreadsheet .cell input').val()).to.eql '=B2'
      done()

    it 'recalculates when enter is pressed', (done) ->
      Mousetrap.trigger('enter')

      expect($('.microspreadsheet .cell input').length).to.eql 0
      expect($('.microspreadsheet .cell').eq(1).text()).to.eql '9'
      expect($('.microspreadsheet .cell').eq(3).text()).to.eql '9'
      done()
