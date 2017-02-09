fs = require 'fs'
path = require 'path'

describe "CoffeeScript grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-coffee-script")

    runs ->
      grammar = atom.grammars.grammarForScopeName("source.coffee")

  it "parses the grammar", ->
    expect(grammar).toBeTruthy()
    expect(grammar.scopeName).toBe "source.coffee"

  it "tokenizes classes", ->
    {tokens} = grammar.tokenizeLine("class Foo")

    expect(tokens[0]).toEqual value: "class", scopes: ["source.coffee", "meta.class.coffee", "storage.type.class.coffee"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee", "meta.class.coffee"]
    expect(tokens[2]).toEqual value: "Foo", scopes: ["source.coffee", "meta.class.coffee", "entity.name.type.class.coffee"]

    {tokens} = grammar.tokenizeLine("subclass Foo")
    expect(tokens[0]).toEqual value: "subclass Foo", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("[class Foo]")
    expect(tokens[0]).toEqual value: "[", scopes: ["source.coffee", "meta.brace.square.coffee"]
    expect(tokens[1]).toEqual value: "class", scopes: ["source.coffee", "meta.class.coffee", "storage.type.class.coffee"]
    expect(tokens[2]).toEqual value: " ", scopes: ["source.coffee", "meta.class.coffee"]
    expect(tokens[3]).toEqual value: "Foo", scopes: ["source.coffee", "meta.class.coffee", "entity.name.type.class.coffee"]
    expect(tokens[4]).toEqual value: "]", scopes: ["source.coffee", "meta.brace.square.coffee"]

    {tokens} = grammar.tokenizeLine("bar(class Foo)")
    expect(tokens[0]).toEqual value: "bar", scopes: ["source.coffee", "entity.name.function.coffee"]
    expect(tokens[1]).toEqual value: "(", scopes: ["source.coffee", "meta.brace.round.coffee"]
    expect(tokens[2]).toEqual value: "class", scopes: ["source.coffee", "meta.class.coffee", "storage.type.class.coffee"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.coffee", "meta.class.coffee"]
    expect(tokens[4]).toEqual value: "Foo", scopes: ["source.coffee", "meta.class.coffee", "entity.name.type.class.coffee"]
    expect(tokens[5]).toEqual value: ")", scopes: ["source.coffee", "meta.brace.round.coffee"]

  it "tokenizes named subclasses", ->
    {tokens} = grammar.tokenizeLine("class Foo extends Bar")

    expect(tokens[0]).toEqual value: "class", scopes: ["source.coffee", "meta.class.coffee", "storage.type.class.coffee"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee", "meta.class.coffee"]
    expect(tokens[2]).toEqual value: "Foo", scopes: ["source.coffee", "meta.class.coffee", "entity.name.type.class.coffee"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.coffee", "meta.class.coffee"]
    expect(tokens[4]).toEqual value: "extends", scopes: ["source.coffee", "meta.class.coffee", "keyword.control.inheritance.coffee"]
    expect(tokens[5]).toEqual value: " ", scopes: ["source.coffee", "meta.class.coffee"]
    expect(tokens[6]).toEqual value: "Bar", scopes: ["source.coffee", "meta.class.coffee", "entity.other.inherited-class.coffee"]

  it "tokenizes anonymous subclasses", ->
    {tokens} = grammar.tokenizeLine("class extends Foo")

    expect(tokens[0]).toEqual value: "class", scopes: ["source.coffee", "meta.class.coffee", "storage.type.class.coffee"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee", "meta.class.coffee"]
    expect(tokens[2]).toEqual value: "extends", scopes: ["source.coffee", "meta.class.coffee", "keyword.control.inheritance.coffee"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.coffee", "meta.class.coffee"]
    expect(tokens[4]).toEqual value: "Foo", scopes: ["source.coffee", "meta.class.coffee", "entity.other.inherited-class.coffee"]

  it "tokenizes instantiated anonymous classes", ->
    {tokens} = grammar.tokenizeLine("new class")

    expect(tokens[0]).toEqual value: "new", scopes: ["source.coffee", "meta.class.instance.constructor", "keyword.operator.new.coffee"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee", "meta.class.instance.constructor"]
    expect(tokens[2]).toEqual value: "class", scopes: ["source.coffee", "meta.class.instance.constructor", "storage.type.class.coffee"]

  it "tokenizes instantiated named classes", ->
    {tokens} = grammar.tokenizeLine("new class Foo")

    expect(tokens[0]).toEqual value: "new", scopes: ["source.coffee", "meta.class.instance.constructor", "keyword.operator.new.coffee"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee", "meta.class.instance.constructor"]
    expect(tokens[2]).toEqual value: "class", scopes: ["source.coffee", "meta.class.instance.constructor", "storage.type.class.coffee"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.coffee", "meta.class.instance.constructor"]
    expect(tokens[4]).toEqual value: "Foo", scopes: ["source.coffee", "meta.class.instance.constructor", "entity.name.type.instance.coffee"]

    {tokens} = grammar.tokenizeLine("new Foo")

    expect(tokens[0]).toEqual value: "new", scopes: ["source.coffee", "meta.class.instance.constructor", "keyword.operator.new.coffee"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee", "meta.class.instance.constructor"]
    expect(tokens[2]).toEqual value: "Foo", scopes: ["source.coffee", "meta.class.instance.constructor", "entity.name.type.instance.coffee"]

  it "tokenizes comments", ->
    {tokens} = grammar.tokenizeLine("# I am a comment")

    expect(tokens[0]).toEqual value: "#", scopes: ["source.coffee", "comment.line.number-sign.coffee", "punctuation.definition.comment.coffee"]
    expect(tokens[1]).toEqual value: " I am a comment", scopes: ["source.coffee", "comment.line.number-sign.coffee"]

    {tokens} = grammar.tokenizeLine("\#{Comment}")

    expect(tokens[0]).toEqual value: "#", scopes: ["source.coffee", "comment.line.number-sign.coffee", "punctuation.definition.comment.coffee"]
    expect(tokens[1]).toEqual value: "{Comment}", scopes: ["source.coffee", "comment.line.number-sign.coffee"]

  it "tokenizes annotations in block comments", ->
    lines = grammar.tokenizeLines """
      ###
        @foo - food
      @bar - bart
      """

    expect(lines[1][0]).toEqual value: '  ', scopes: ["source.coffee", "comment.block.coffee"]
    expect(lines[1][1]).toEqual value: '@foo', scopes: ["source.coffee", "comment.block.coffee", "storage.type.annotation.coffee"]
    expect(lines[2][0]).toEqual value: '@bar', scopes: ["source.coffee", "comment.block.coffee", "storage.type.annotation.coffee"]

  it "tokenizes this as a special variable", ->
    {tokens} = grammar.tokenizeLine("this")

    expect(tokens[0]).toEqual value: "this", scopes: ["source.coffee", "variable.language.this.coffee"]

  it "tokenizes variable assignments", ->
    {tokens} = grammar.tokenizeLine("something = b")
    expect(tokens[0]).toEqual value: "something", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "=", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a and= b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "and=", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a or= b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "or=", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a -= b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "-=", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a += b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "+=", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a /= b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "/=", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a &= b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "&=", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a %= b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "%=", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a *= b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "*=", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a ?= b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "?=", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a == b")
    expect(tokens[0]).toEqual value: "a ", scopes: ["source.coffee"]
    expect(tokens[1]).toEqual value: "==", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[2]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("false == b")
    expect(tokens[0]).toEqual value: "false", scopes: ["source.coffee", "constant.language.boolean.false.coffee"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee"]
    expect(tokens[2]).toEqual value: "==", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("true == b")
    expect(tokens[0]).toEqual value: "true", scopes: ["source.coffee", "constant.language.boolean.true.coffee"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee"]
    expect(tokens[2]).toEqual value: "==", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("null == b")
    expect(tokens[0]).toEqual value: "null", scopes: ["source.coffee", "constant.language.null.coffee"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee"]
    expect(tokens[2]).toEqual value: "==", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("this == b")
    expect(tokens[0]).toEqual value: "this", scopes: ["source.coffee", "variable.language.this.coffee"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee"]
    expect(tokens[2]).toEqual value: "==", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

  it "tokenizes compound operators properly", ->
    compoundOperators = ["and=", "or=", "==", "!=", "<=", ">=", "<<=", ">>=", ">>>=", "<>", "*=", "%=", "+=", "-=", "&=", "^="]

    for compoundOperator in compoundOperators
      {tokens} = grammar.tokenizeLine(compoundOperator)
      expect(tokens[0]).toEqual value: compoundOperator, scopes: ["source.coffee", "keyword.operator.coffee"]

  it "tokenizes operators properly", ->
    operators = ["!", "%", "^", "*", "/", "~", "?", ":", "-", "--", "+", "++", "<", ">", "&", "&&", "..", "...", "|", "||", "instanceof", "new", "delete", "typeof", "and", "or", "is", "isnt", "not", "super"]

    for operator in operators
      {tokens} = grammar.tokenizeLine(operator)
      expect(tokens[0]).toEqual value: operator, scopes: ["source.coffee", "keyword.operator.coffee"]

  it "does not tokenize non-operators as operators", ->
    notOperators = ["(/=", "-->", "=>"]

    for notOperator in notOperators
      {tokens} = grammar.tokenizeLine(notOperator)
      expect(tokens[0]).not.toEqual value: notOperator, scopes: ["source.coffee", "keyword.operator.coffee"]

  it "does not confuse prototype properties with constants and keywords", ->
    {tokens} = grammar.tokenizeLine("Foo::true")
    expect(tokens[0]).toEqual value: "Foo", scopes: ["source.coffee"]
    expect(tokens[1]).toEqual value: ":", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[2]).toEqual value: ":", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: "true", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("Foo::on")
    expect(tokens[0]).toEqual value: "Foo", scopes: ["source.coffee"]
    expect(tokens[1]).toEqual value: ":", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[2]).toEqual value: ":", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: "on", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("Foo::yes")
    expect(tokens[0]).toEqual value: "Foo", scopes: ["source.coffee"]
    expect(tokens[1]).toEqual value: ":", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[2]).toEqual value: ":", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: "yes", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("Foo::false")
    expect(tokens[0]).toEqual value: "Foo", scopes: ["source.coffee"]
    expect(tokens[1]).toEqual value: ":", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[2]).toEqual value: ":", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: "false", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("Foo::off")
    expect(tokens[0]).toEqual value: "Foo", scopes: ["source.coffee"]
    expect(tokens[1]).toEqual value: ":", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[2]).toEqual value: ":", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: "off", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("Foo::no")
    expect(tokens[0]).toEqual value: "Foo", scopes: ["source.coffee"]
    expect(tokens[1]).toEqual value: ":", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[2]).toEqual value: ":", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: "no", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("Foo::null")
    expect(tokens[0]).toEqual value: "Foo", scopes: ["source.coffee"]
    expect(tokens[1]).toEqual value: ":", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[2]).toEqual value: ":", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: "null", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("Foo::extends")
    expect(tokens[0]).toEqual value: "Foo", scopes: ["source.coffee"]
    expect(tokens[1]).toEqual value: ":", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[2]).toEqual value: ":", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[3]).toEqual value: "extends", scopes: ["source.coffee"]

  it "verifies that regular expressions have explicit count modifiers", ->
    source = fs.readFileSync(path.resolve(__dirname, '..', 'grammars', 'coffeescript.cson'), 'utf8')
    expect(source.search /{,/).toEqual -1

    source = fs.readFileSync(path.resolve(__dirname, '..', 'grammars', 'coffeescript (literate).cson'), 'utf8')
    expect(source.search /{,/).toEqual -1

  it "tokenizes embedded JavaScript", ->
    {tokens} = grammar.tokenizeLine("`;`")
    expect(tokens[0]).toEqual value: "`", scopes: ["source.coffee", "string.quoted.script.coffee", "punctuation.definition.string.begin.coffee"]
    expect(tokens[1]).toEqual value: ";", scopes: ["source.coffee", "string.quoted.script.coffee", "constant.character.escape.coffee"]
    expect(tokens[2]).toEqual value: "`", scopes: ["source.coffee", "string.quoted.script.coffee", "punctuation.definition.string.end.coffee"]

    lines = grammar.tokenizeLines """
      `var a = 1;`
      a = 2
      """
    expect(lines[0][0]).toEqual value: '`', scopes: ["source.coffee", "string.quoted.script.coffee", "punctuation.definition.string.begin.coffee"]
    expect(lines[0][1]).toEqual value: 'v', scopes: ["source.coffee", "string.quoted.script.coffee", "constant.character.escape.coffee"]
    expect(lines[1][0]).toEqual value: 'a', scopes: ["source.coffee", "variable.assignment.coffee"]

  it "tokenizes functions", ->
    {tokens} = grammar.tokenizeLine("foo = -> 1")
    expect(tokens[0]).toEqual value: "foo", scopes: ["source.coffee", "meta.function.coffee", "entity.name.function.coffee"]

    {tokens} = grammar.tokenizeLine("foo bar")
    expect(tokens[0]).toEqual value: "foo", scopes: ["source.coffee", "entity.name.function.coffee"]

    {tokens} = grammar.tokenizeLine("eat food for food in foods")
    expect(tokens[0]).toEqual value: "eat", scopes: ["source.coffee", "entity.name.function.coffee"]
    expect(tokens[1]).toEqual value: " food ", scopes: ["source.coffee"]
    expect(tokens[2]).toEqual value: "for", scopes: ["source.coffee", "keyword.control.coffee"]
    expect(tokens[3]).toEqual value: " food ", scopes: ["source.coffee"]
    expect(tokens[4]).toEqual value: "in", scopes: ["source.coffee", "keyword.control.coffee"]
    expect(tokens[5]).toEqual value: " foods", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("foo @bar")
    expect(tokens[0]).toEqual value: "foo", scopes: ["source.coffee", "entity.name.function.coffee"]
    expect(tokens[2]).toEqual value: "@bar", scopes: ["source.coffee", "variable.other.readwrite.instance.coffee"]

    {tokens} = grammar.tokenizeLine("foo baz, @bar")
    expect(tokens[0]).toEqual value: "foo", scopes: ["source.coffee", "entity.name.function.coffee"]
    expect(tokens[1]).toEqual value: " baz", scopes: ["source.coffee"]
    expect(tokens[2]).toEqual value: ",", scopes: ["source.coffee", "meta.delimiter.object.comma.coffee"]
    expect(tokens[4]).toEqual value: "@bar", scopes: ["source.coffee", "variable.other.readwrite.instance.coffee"]

  it "does not tokenize booleans as functions", ->
    {tokens} = grammar.tokenizeLine("false unless true")
    expect(tokens[0]).toEqual value: "false", scopes: ["source.coffee", "constant.language.boolean.false.coffee"]
    expect(tokens[2]).toEqual value: "unless", scopes: ["source.coffee", "keyword.control.coffee"]
    expect(tokens[4]).toEqual value: "true", scopes: ["source.coffee", "constant.language.boolean.true.coffee"]

    {tokens} = grammar.tokenizeLine("true if false")
    expect(tokens[0]).toEqual value: "true", scopes: ["source.coffee", "constant.language.boolean.true.coffee"]
    expect(tokens[2]).toEqual value: "if", scopes: ["source.coffee", "keyword.control.coffee"]
    expect(tokens[4]).toEqual value: "false", scopes: ["source.coffee", "constant.language.boolean.false.coffee"]

  it "tokenizes destructuring assignments", ->
    {tokens} = grammar.tokenizeLine("{something} = hi")
    expect(tokens[0]).toEqual value: "{", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.begin.bracket.curly.coffee"]
    expect(tokens[1]).toEqual value: "something", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "variable.assignment.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "}", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.end.bracket.curly.coffee"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.coffee"]
    expect(tokens[4]).toEqual value: "=", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[5]).toEqual value: " hi", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("[x, y] = browserWindow.getPosition()")
    expect(tokens[0]).toEqual value: "[", scopes: ["source.coffee", "meta.variable.assignment.destructured.array.coffee", "punctuation.definition.destructuring.begin.bracket.square.coffee"]
    expect(tokens[1]).toEqual value: "x", scopes: ["source.coffee", "meta.variable.assignment.destructured.array.coffee", "variable.assignment.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: ",", scopes: ["source.coffee", "meta.variable.assignment.destructured.array.coffee", "meta.delimiter.object.comma.coffee"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.coffee", "meta.variable.assignment.destructured.array.coffee"]
    expect(tokens[4]).toEqual value: "y", scopes: ["source.coffee", "meta.variable.assignment.destructured.array.coffee", "variable.assignment.coffee", "variable.assignment.coffee"]
    expect(tokens[5]).toEqual value: "]", scopes: ["source.coffee", "meta.variable.assignment.destructured.array.coffee", "punctuation.definition.destructuring.end.bracket.square.coffee"]
    expect(tokens[6]).toEqual value: " ", scopes: ["source.coffee"]
    expect(tokens[7]).toEqual value: "=", scopes: ["source.coffee", "keyword.operator.coffee"]
    expect(tokens[8]).toEqual value: " browserWindow", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("{'} ='}") # Make sure this *isn't* tokenized as a destructuring assignment
    expect(tokens[0]).not.toEqual value: "{", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.begin.bracket.curly.coffee"]
    expect(tokens[0]).toEqual value: "{", scopes: ["source.coffee", "meta.brace.curly.coffee"]

  it "tokenizes nested destructuring assignments", ->
    {tokens} = grammar.tokenizeLine("{poet: {name, address: [street, city]}} = futurists")
    expect(tokens[0]).toEqual value: "{", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.begin.bracket.curly.coffee"]
    expect(tokens[4]).toEqual value: "{", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.begin.bracket.curly.coffee"]
    expect(tokens[11]).toEqual value: "[", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "meta.variable.assignment.destructured.object.coffee", "meta.variable.assignment.destructured.array.coffee", "punctuation.definition.destructuring.begin.bracket.square.coffee"]
    expect(tokens[16]).toEqual value: "]", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "meta.variable.assignment.destructured.object.coffee", "meta.variable.assignment.destructured.array.coffee", "punctuation.definition.destructuring.end.bracket.square.coffee"]
    expect(tokens[17]).toEqual value: "}", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.end.bracket.curly.coffee"]
    expect(tokens[18]).toEqual value: "}", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.end.bracket.curly.coffee"]
    expect(tokens[19]).toEqual value: " ", scopes: ["source.coffee"]
    expect(tokens[20]).toEqual value: "=", scopes: ["source.coffee", "keyword.operator.coffee"]

  it "tokenizes multiple nested destructuring assignments", ->
    {tokens} = grammar.tokenizeLine("{start: {row: startRow}, end: {row: endRow}} = range")
    expect(tokens[0]).toEqual value: "{", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.begin.bracket.curly.coffee"]
    expect(tokens[4]).toEqual value: "{", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.begin.bracket.curly.coffee"]
    expect(tokens[9]).toEqual value: "}", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.end.bracket.curly.coffee"]
    expect(tokens[15]).toEqual value: "{", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.begin.bracket.curly.coffee"]
    expect(tokens[20]).toEqual value: "}", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.end.bracket.curly.coffee"]
    expect(tokens[21]).toEqual value: "}", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.end.bracket.curly.coffee"]
    expect(tokens[22]).toEqual value: " ", scopes: ["source.coffee"]
    expect(tokens[23]).toEqual value: "=", scopes: ["source.coffee", "keyword.operator.coffee"]

  it "doesn't tokenize nested brackets as destructuring assignments", ->
    {tokens} = grammar.tokenizeLine("[Point(0, 1), [Point(0, 0), Point(0, 1)]]")
    expect(tokens[0]).not.toEqual value: "[", scopes: ["source.coffee", "meta.variable.assignment.destructured.array.coffee", "punctuation.definition.destructuring.begin.bracket.square.coffee"]
    expect(tokens[0]).toEqual value: "[", scopes: ["source.coffee", "meta.brace.square.coffee"]

  it "tokenizes inline constant followed by unless statement correctly", ->
    {tokens} = grammar.tokenizeLine("return 0 unless true")
    expect(tokens[0]).toEqual value: "return", scopes: ["source.coffee", "keyword.control.coffee"]
    expect(tokens[2]).toEqual value: "0", scopes: ["source.coffee", "constant.numeric.coffee"]
    expect(tokens[4]).toEqual value: "unless", scopes: ["source.coffee", "keyword.control.coffee"]
    expect(tokens[6]).toEqual value: "true", scopes: ["source.coffee", "constant.language.boolean.true.coffee"]

  describe "regular expressions", ->
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage("language-javascript") # Provides the regexp subgrammar

    it "tokenizes regular expressions", ->
      {tokens} = grammar.tokenizeLine("/test/")
      expect(tokens[0]).toEqual value: "/", scopes: ["source.coffee", "string.regexp.coffee", "punctuation.definition.string.begin.coffee"]
      expect(tokens[1]).toEqual value: "test", scopes: ["source.coffee", "string.regexp.coffee"]
      expect(tokens[2]).toEqual value: "/", scopes: ["source.coffee", "string.regexp.coffee", "punctuation.definition.string.end.coffee"]

      {tokens} = grammar.tokenizeLine("/{'}/")
      expect(tokens[0]).toEqual value: "/", scopes: ["source.coffee", "string.regexp.coffee", "punctuation.definition.string.begin.coffee"]
      expect(tokens[2]).toEqual value: "/", scopes: ["source.coffee", "string.regexp.coffee", "punctuation.definition.string.end.coffee"]

      {tokens} = grammar.tokenizeLine("foo + /test/")
      expect(tokens[0]).toEqual value: "foo ", scopes: ["source.coffee"]
      expect(tokens[1]).toEqual value: "+", scopes: ["source.coffee", "keyword.operator.coffee"]
      expect(tokens[2]).toEqual value: " ", scopes: ["source.coffee"]
      expect(tokens[3]).toEqual value: "/", scopes: ["source.coffee", "string.regexp.coffee", "punctuation.definition.string.begin.coffee"]
      expect(tokens[4]).toEqual value: "test", scopes: ["source.coffee", "string.regexp.coffee"]
      expect(tokens[5]).toEqual value: "/", scopes: ["source.coffee", "string.regexp.coffee", "punctuation.definition.string.end.coffee"]

    it "tokenizes regular expressions containing spaces", ->
      {tokens} = grammar.tokenizeLine("/ te st /")
      expect(tokens[0]).toEqual value: "/", scopes: ["source.coffee", "string.regexp.coffee", "punctuation.definition.string.begin.coffee"]
      expect(tokens[1]).toEqual value: " te st ", scopes: ["source.coffee", "string.regexp.coffee"]
      expect(tokens[2]).toEqual value: "/", scopes: ["source.coffee", "string.regexp.coffee", "punctuation.definition.string.end.coffee"]

    it "tokenizes regular expressions containing escaped forward slashes", ->
      {tokens} = grammar.tokenizeLine("/test\\//")
      expect(tokens[0]).toEqual value: "/", scopes: ["source.coffee", "string.regexp.coffee", "punctuation.definition.string.begin.coffee"]
      expect(tokens[1]).toEqual value: "test", scopes: ["source.coffee", "string.regexp.coffee"]
      expect(tokens[2]).toEqual value: "\\/", scopes: ["source.coffee", "string.regexp.coffee", "constant.character.escape.backslash.regexp"]
      expect(tokens[3]).toEqual value: "/", scopes: ["source.coffee", "string.regexp.coffee", "punctuation.definition.string.end.coffee"]

    it "tokenizes regular expressions inside arrays", ->
      {tokens} = grammar.tokenizeLine("[/test/]")
      expect(tokens[0]).toEqual value: "[", scopes: ["source.coffee", "meta.brace.square.coffee"]
      expect(tokens[1]).toEqual value: "/", scopes: ["source.coffee", "string.regexp.coffee", "punctuation.definition.string.begin.coffee"]
      expect(tokens[2]).toEqual value: "test", scopes: ["source.coffee", "string.regexp.coffee"]
      expect(tokens[3]).toEqual value: "/", scopes: ["source.coffee", "string.regexp.coffee", "punctuation.definition.string.end.coffee"]
      expect(tokens[4]).toEqual value: "]", scopes: ["source.coffee", "meta.brace.square.coffee"]

      {tokens} = grammar.tokenizeLine("[1, /test/]")
      expect(tokens[0]).toEqual value: "[", scopes: ["source.coffee", "meta.brace.square.coffee"]
      expect(tokens[1]).toEqual value: "1", scopes: ["source.coffee", "constant.numeric.coffee"]
      expect(tokens[2]).toEqual value: ",", scopes: ["source.coffee", "meta.delimiter.object.comma.coffee"]
      expect(tokens[3]).toEqual value: " ", scopes: ["source.coffee"]
      expect(tokens[4]).toEqual value: "/", scopes: ["source.coffee", "string.regexp.coffee", "punctuation.definition.string.begin.coffee"]
      expect(tokens[5]).toEqual value: "test", scopes: ["source.coffee", "string.regexp.coffee"]
      expect(tokens[6]).toEqual value: "/", scopes: ["source.coffee", "string.regexp.coffee", "punctuation.definition.string.end.coffee"]
      expect(tokens[7]).toEqual value: "]", scopes: ["source.coffee", "meta.brace.square.coffee"]

    it "does not tokenize multiple division as regex", ->
      # https://github.com/atom/language-coffee-script/issues/112
      {tokens} = grammar.tokenizeLine("a / b + c / d")
      expect(tokens[1]).toEqual value: "/", scopes: ["source.coffee", "keyword.operator.coffee"]
      expect(tokens[2]).toEqual value: " b ", scopes: ["source.coffee"]

  describe "firstLineMatch", ->
    it "recognises interpreter directives", ->
      valid = """
        #!/usr/sbin/coffee foo
        #!/usr/bin/coffee foo=bar/
        #!/usr/sbin/coffee
        #!/usr/sbin/coffee foo bar baz
        #!/usr/bin/coffee perl
        #!/usr/bin/coffee bin/perl
        #!/usr/bin/coffee
        #!/bin/coffee
        #!/usr/bin/coffee --script=usr/bin
        #! /usr/bin/env A=003 B=149 C=150 D=xzd E=base64 F=tar G=gz H=head I=tail coffee
        #!\t/usr/bin/env --foo=bar coffee --quu=quux
        #! /usr/bin/coffee
        #!/usr/bin/env coffee
      """
      for line in valid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

      invalid = """
        \x20#!/usr/sbin/coffee
        \t#!/usr/sbin/coffee
        #!/usr/bin/env-coffee/node-env/
        #!/usr/bin/env-coffee
        #! /usr/bincoffee
        #!\t/usr/bin/env --coffee=bar
      """
      for line in invalid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()

    it "recognises Emacs modelines", ->
      valid = """
        #-*- coffee -*-
        #-*- mode: Coffee -*-
        /* -*-coffee-*- */
        // -*- Coffee -*-
        /* -*- mode:Coffee -*- */
        // -*- font:bar;mode:Coffee -*-
        // -*- font:bar;mode:Coffee;foo:bar; -*-
        // -*-font:mode;mode:COFFEE-*-
        // -*- foo:bar mode: coffee bar:baz -*-
        " -*-foo:bar;mode:cOFFEE;bar:foo-*- ";
        " -*-font-mode:foo;mode:coFFeE;foo-bar:quux-*-"
        "-*-font:x;foo:bar; mode : Coffee; bar:foo;foooooo:baaaaar;fo:ba;-*-";
        "-*- font:x;foo : bar ; mode : Coffee ; bar : foo ; foooooo:baaaaar;fo:ba-*-";
      """
      for line in valid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

      invalid = """
        /* --*coffee-*- */
        /* -*-- coffee -*-
        /* -*- -- Coffee -*-
        /* -*- Coffee -;- -*-
        // -*- freeCoffee -*-
        // -*- Coffee; -*-
        // -*- coffee-sugar -*-
        /* -*- model:coffee -*-
        /* -*- indent-mode:coffee -*-
        // -*- font:mode;Coffee -*-
        // -*- mode: -*- Coffee
        // -*- mode: jfc-give-me-coffee -*-
        // -*-font:mode;mode:coffee--*-
      """
      for line in invalid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()

    it "recognises Vim modelines", ->
      valid = """
        vim: se filetype=coffee:
        # vim: se ft=coffee:
        # vim: set ft=COFFEE:
        # vim: set filetype=CoffEE:
        # vim: ft=CoffEE
        # vim: syntax=CoffEE
        # vim: se syntax=CoffEE:
        # ex: syntax=CoffEE
        # vim:ft=coffee
        # vim600: ft=coffee
        # vim>600: set ft=coffee:
        # vi:noai:sw=3 ts=6 ft=coffee
        # vi::::::::::noai:::::::::::: ft=COFFEE
        # vim:ts=4:sts=4:sw=4:noexpandtab:ft=cOfFeE
        # vi:: noai : : : : sw   =3 ts   =6 ft  =coFFEE
        # vim: ts=4: pi sts=4: ft=cofFeE: noexpandtab: sw=4:
        # vim: ts=4 sts=4: ft=coffee noexpandtab:
        # vim:noexpandtab sts=4 ft=coffEE ts=4
        # vim:noexpandtab:ft=cOFFEe
        # vim:ts=4:sts=4 ft=cofFeE:noexpandtab:\x20
        # vim:noexpandtab titlestring=hi\|there\\\\ ft=cOFFEe ts=4
      """
      for line in valid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

      invalid = """
        ex: se filetype=coffee:
        _vi: se filetype=coffee:
         vi: se filetype=coffee
        # vim set ft=coffee
        # vim: soft=coffee
        # vim: clean-syntax=coffee:
        # vim set ft=coffee:
        # vim: setft=coffee:
        # vim: se ft=coffee backupdir=tmp
        # vim: set ft=coffee set cmdheight=1
        # vim:noexpandtab sts:4 ft:coffee ts:4
        # vim:noexpandtab titlestring=hi\\|there\\ ft=coffee ts=4
        # vim:noexpandtab titlestring=hi\\|there\\\\\\ ft=coffee ts=4
      """
      for line in invalid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()
