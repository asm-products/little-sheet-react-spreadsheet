testUtils = React.addons.TestUtils
expect = chai.expect
should = chai.should()

Spreadsheet = require '../main.coffee'

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
  describe 'text cells', ->
    before ->
      cells = [
        ['','123','','123']
        ['asd','','sad','']
        ['','as','','sd']
        ['das','','123','']
      ]
      React.renderComponent Spreadsheet(cells: cells), utils.testNode()
    after utils.reset

    it 'renders the table', ->
      expect($('table.microspreadsheet')).to.exist

    it 'renders the rows and cells at the right places', ->
      cells = []
      for row in $('.microspreadsheet tr')
        rowArray = []
        for cell in $(row).find('td')
          rowArray.push $(cell).text()
        cells.push rowArray

      expect(cells[0]).to.eql ['', 'A', 'B', 'C', 'D']
      expect(cells[1]).to.eql ['1', '', '123', '', '123']
      expect(cells[4]).to.eql ['4', 'das', '', '123', '']

  describe 'formulas (refs, expressions and sum() with matrixes)', ->
    before ->
      cells = [
        ['=A2','123']
        ['7','=B1+A2']
        ['=SUM(A1,A2)','=sUm(A1:B2)']
      ]
      React.renderComponent Spreadsheet(cells: cells), utils.testNode()
    after utils.reset

    it 'renders the table', ->
      expect($('table.microspreadsheet')).to.exist

    it 'renders the rows and cells with the right values', ->
      cells = []
      for row in $('.microspreadsheet tr')
        rowArray = []
        for cell in $(row).find('td')
          rowArray.push $(cell).text()
        cells.push rowArray

      expect(cells[1]).to.eql ['1', '7', '123']
      expect(cells[2]).to.eql ['2', '7', '130']
      expect(cells[3]).to.eql ['3', '14', '267']

  describe 'dbclick, edit, blur', ->
    sheet = null
    secondCell = null
    input = null

    before ->
      cells = [
        ['44','123']
        ['7','']
        ['=SUM(A1,A2)','=sUm(A1:B2)']
      ]
      sheet = React.renderComponent Spreadsheet(cells: cells), utils.testNode()

    after utils.reset

    it 'finds the second cell and starts editing', ->
      secondCell = testUtils.scryRenderedDOMComponentsWithClass(sheet, 'cell')[1]
      span = testUtils.findRenderedDOMComponentWithTag(secondCell, 'span')
      testUtils.Simulate.doubleClick(span)

      $('.microspreadsheet .cell input')[0].should.have.property 'value'
      expect($('.microspreadsheet .cell input').val()).to.eql '123'

    it 'changes its value', ->
      input = testUtils.findRenderedDOMComponentWithTag(secondCell, 'input')
        
      testUtils.Simulate.change(input, {target: {value: '16'}})
      expect($('.microspreadsheet .cell input').val()).to.eql '16'

    it 'stops editing and the table recalculates', ->
      testUtils.Simulate.blur(input)

      expect($('.microspreadsheet .cell input').length).to.eql 0
      expect($('.microspreadsheet .cell').eq(1).text()).to.eql '16'
      expect($('.microspreadsheet .cell').eq(4).text()).to.eql '51'
      expect($('.microspreadsheet .cell').eq(5).text()).to.eql '67'
