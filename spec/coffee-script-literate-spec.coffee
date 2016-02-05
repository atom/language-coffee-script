describe "CoffeeScript (Literate) grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-coffee-script")

    runs ->
      grammar = atom.grammars.grammarForScopeName("source.litcoffee")

  it "parses the grammar", ->
    expect(grammar).toBeTruthy()
    expect(grammar.scopeName).toBe "source.litcoffee"

  it "recognizes a code block after a list", ->
    tokens = grammar.tokenizeLines '''
      1. Example
      2. List

          1 + 2
    '''
    expect(tokens[3][1]).toEqual value: "1", scopes: ["source.litcoffee", "markup.raw.block.markdown", "constant.numeric.coffee"]
