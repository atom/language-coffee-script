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

  it "tokenizes Oniguruma-regex comments in strings", ->
    {tokens} = grammar.tokenizeLine('\"a (?# X Y\\\" Z \\\\\\\" 123) ABC\"')
    expect(tokens[0]).toEqual  value: "\"",   scopes: ["source.coffee", "string.quoted.double.coffee", "punctuation.definition.string.begin.coffee"]
    expect(tokens[1]).toEqual  value: "a ",   scopes: ["source.coffee", "string.quoted.double.coffee"]
    expect(tokens[2]).toEqual  value: "(?#",  scopes: ["source.coffee", "string.quoted.double.coffee", "comment.block.oniguruma.coffee", "punctuation.definition.comment.begin.coffee"]
    expect(tokens[3]).toEqual  value: " X Y", scopes: ["source.coffee", "string.quoted.double.coffee", "comment.block.oniguruma.coffee"]
    expect(tokens[4]).toEqual  value: "\\\"", scopes: ["source.coffee", "string.quoted.double.coffee", "comment.block.oniguruma.coffee", "constant.character.escape.backslash.coffee"]
    expect(tokens[5]).toEqual  value: " Z ",  scopes: ["source.coffee", "string.quoted.double.coffee", "comment.block.oniguruma.coffee"]
    expect(tokens[6]).toEqual  value: "\\\\", scopes: ["source.coffee", "string.quoted.double.coffee", "comment.block.oniguruma.coffee", "constant.character.escape.backslash.coffee"]
    expect(tokens[7]).toEqual  value: "\\\"", scopes: ["source.coffee", "string.quoted.double.coffee", "comment.block.oniguruma.coffee", "constant.character.escape.backslash.coffee"]
    expect(tokens[8]).toEqual  value: " 123", scopes: ["source.coffee", "string.quoted.double.coffee", "comment.block.oniguruma.coffee"]
    expect(tokens[9]).toEqual  value: ")",    scopes: ["source.coffee", "string.quoted.double.coffee", "comment.block.oniguruma.coffee", "punctuation.definition.comment.end.coffee"]
    expect(tokens[10]).toEqual value: " ABC", scopes: ["source.coffee", "string.quoted.double.coffee"]
    expect(tokens[11]).toEqual value: "\"",   scopes: ["source.coffee", "string.quoted.double.coffee", "punctuation.definition.string.end.coffee"]

  it "does not ignore closing quote of unterminated Oniguruma comments", ->
    {tokens} = grammar.tokenizeLine('\'a (?#\' z')
    expect(tokens[0]).toEqual  value: "'",    scopes: ["source.coffee", "string.quoted.single.coffee", "punctuation.definition.string.begin.coffee"]
    expect(tokens[1]).toEqual  value: "a ",   scopes: ["source.coffee", "string.quoted.single.coffee"]
    expect(tokens[2]).toEqual  value: "(?#",  scopes: ["source.coffee", "string.quoted.single.coffee", "comment.block.oniguruma.coffee", "punctuation.definition.comment.begin.coffee"]
    expect(tokens[3]).toEqual  value: "'",    scopes: ["source.coffee", "string.quoted.single.coffee", "punctuation.definition.string.end.coffee"]
    expect(tokens[4]).toEqual  value: " z",   scopes: ["source.coffee"]
