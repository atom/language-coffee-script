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

    {tokens} = grammar.tokenizeLine("class_ Foo")
    expect(tokens[0]).toEqual value: "class_", scopes: ["source.coffee", "meta.function-call.coffee", "entity.name.function.coffee"]

    {tokens} = grammar.tokenizeLine("_class Foo")
    expect(tokens[0]).toEqual value: "_class", scopes: ["source.coffee", "meta.function-call.coffee", "entity.name.function.coffee"]

    {tokens} = grammar.tokenizeLine("[class Foo]")
    expect(tokens[0]).toEqual value: "[", scopes: ["source.coffee", "meta.brace.square.coffee"]
    expect(tokens[1]).toEqual value: "class", scopes: ["source.coffee", "meta.class.coffee", "storage.type.class.coffee"]
    expect(tokens[2]).toEqual value: " ", scopes: ["source.coffee", "meta.class.coffee"]
    expect(tokens[3]).toEqual value: "Foo", scopes: ["source.coffee", "meta.class.coffee", "entity.name.type.class.coffee"]
    expect(tokens[4]).toEqual value: "]", scopes: ["source.coffee", "meta.brace.square.coffee"]

    {tokens} = grammar.tokenizeLine("bar(class Foo)")
    expect(tokens[0]).toEqual value: "bar", scopes: ["source.coffee", "meta.function-call.coffee", "entity.name.function.coffee"]
    expect(tokens[1]).toEqual value: "(", scopes: ["source.coffee", "meta.function-call.coffee", "meta.arguments.coffee", "punctuation.definition.arguments.begin.bracket.round.coffee"]
    expect(tokens[2]).toEqual value: "class", scopes: ["source.coffee", "meta.function-call.coffee", "meta.arguments.coffee", "meta.class.coffee", "storage.type.class.coffee"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.coffee", "meta.function-call.coffee", "meta.arguments.coffee", "meta.class.coffee"]
    expect(tokens[4]).toEqual value: "Foo", scopes: ["source.coffee", "meta.function-call.coffee", "meta.arguments.coffee", "meta.class.coffee", "entity.name.type.class.coffee"]
    expect(tokens[5]).toEqual value: ")", scopes: ["source.coffee", "meta.function-call.coffee", "meta.arguments.coffee", "punctuation.definition.arguments.end.bracket.round.coffee"]

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

  describe "numbers", ->
    it "tokenizes hexadecimals", ->
      {tokens} = grammar.tokenizeLine('0x1D306')
      expect(tokens[0]).toEqual value: '0x1D306', scopes: ['source.coffee', 'constant.numeric.hex.coffee']

      {tokens} = grammar.tokenizeLine('0X1D306')
      expect(tokens[0]).toEqual value: '0X1D306', scopes: ['source.coffee', 'constant.numeric.hex.coffee']

    it "tokenizes binary literals", ->
      {tokens} = grammar.tokenizeLine('0b011101110111010001100110')
      expect(tokens[0]).toEqual value: '0b011101110111010001100110', scopes: ['source.coffee', 'constant.numeric.binary.coffee']

      {tokens} = grammar.tokenizeLine('0B011101110111010001100110')
      expect(tokens[0]).toEqual value: '0B011101110111010001100110', scopes: ['source.coffee', 'constant.numeric.binary.coffee']

    it "tokenizes octal literals", ->
      {tokens} = grammar.tokenizeLine('0o1411')
      expect(tokens[0]).toEqual value: '0o1411', scopes: ['source.coffee', 'constant.numeric.octal.coffee']

      {tokens} = grammar.tokenizeLine('0O1411')
      expect(tokens[0]).toEqual value: '0O1411', scopes: ['source.coffee', 'constant.numeric.octal.coffee']

      {tokens} = grammar.tokenizeLine('0010')
      expect(tokens[0]).toEqual value: '0010', scopes: ['source.coffee', 'constant.numeric.octal.coffee']

    it "tokenizes decimals", ->
      {tokens} = grammar.tokenizeLine('1234')
      expect(tokens[0]).toEqual value: '1234', scopes: ['source.coffee', 'constant.numeric.decimal.coffee']

      {tokens} = grammar.tokenizeLine('5e-10')
      expect(tokens[0]).toEqual value: '5e-10', scopes: ['source.coffee', 'constant.numeric.decimal.coffee']

      {tokens} = grammar.tokenizeLine('5E+5')
      expect(tokens[0]).toEqual value: '5E+5', scopes: ['source.coffee', 'constant.numeric.decimal.coffee']

      {tokens} = grammar.tokenizeLine('9.')
      expect(tokens[0]).toEqual value: '9', scopes: ['source.coffee', 'constant.numeric.decimal.coffee']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.coffee', 'constant.numeric.decimal.coffee', 'meta.delimiter.decimal.period.coffee']

      {tokens} = grammar.tokenizeLine('.9')
      expect(tokens[0]).toEqual value: '.', scopes: ['source.coffee', 'constant.numeric.decimal.coffee', 'meta.delimiter.decimal.period.coffee']
      expect(tokens[1]).toEqual value: '9', scopes: ['source.coffee', 'constant.numeric.decimal.coffee']

      {tokens} = grammar.tokenizeLine('9.9')
      expect(tokens[0]).toEqual value: '9', scopes: ['source.coffee', 'constant.numeric.decimal.coffee']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.coffee', 'constant.numeric.decimal.coffee', 'meta.delimiter.decimal.period.coffee']
      expect(tokens[2]).toEqual value: '9', scopes: ['source.coffee', 'constant.numeric.decimal.coffee']

      {tokens} = grammar.tokenizeLine('.1e-23')
      expect(tokens[0]).toEqual value: '.', scopes: ['source.coffee', 'constant.numeric.decimal.coffee', 'meta.delimiter.decimal.period.coffee']
      expect(tokens[1]).toEqual value: '1e-23', scopes: ['source.coffee', 'constant.numeric.decimal.coffee']

      {tokens} = grammar.tokenizeLine('1.E3')
      expect(tokens[0]).toEqual value: '1', scopes: ['source.coffee', 'constant.numeric.decimal.coffee']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.coffee', 'constant.numeric.decimal.coffee', 'meta.delimiter.decimal.period.coffee']
      expect(tokens[2]).toEqual value: 'E3', scopes: ['source.coffee', 'constant.numeric.decimal.coffee']

    it "does not tokenize numbers that are part of a variable", ->
      {tokens} = grammar.tokenizeLine('hi$1')
      expect(tokens[0]).toEqual value: 'hi$1', scopes: ['source.coffee']

      {tokens} = grammar.tokenizeLine('hi_1')
      expect(tokens[0]).toEqual value: 'hi_1', scopes: ['source.coffee']

  it "tokenizes variable assignments", ->
    {tokens} = grammar.tokenizeLine("something = b")
    expect(tokens[0]).toEqual value: "something", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "=", scopes: ["source.coffee", "keyword.operator.assignment.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("something : b")
    expect(tokens[0]).toEqual value: "something", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: ":", scopes: ["source.coffee", "keyword.operator.assignment.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a and= b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "and=", scopes: ["source.coffee", "keyword.operator.assignment.compound.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a or= b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "or=", scopes: ["source.coffee", "keyword.operator.assignment.compound.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a -= b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "-=", scopes: ["source.coffee", "keyword.operator.assignment.compound.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a += b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "+=", scopes: ["source.coffee", "keyword.operator.assignment.compound.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a /= b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "/=", scopes: ["source.coffee", "keyword.operator.assignment.compound.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a &= b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "&=", scopes: ["source.coffee", "keyword.operator.assignment.compound.bitwise.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a %= b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "%=", scopes: ["source.coffee", "keyword.operator.assignment.compound.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a *= b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "*=", scopes: ["source.coffee", "keyword.operator.assignment.compound.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a ?= b")
    expect(tokens[0]).toEqual value: "a", scopes: ["source.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "?=", scopes: ["source.coffee", "keyword.operator.assignment.compound.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("a == b")
    expect(tokens[0]).toEqual value: "a ", scopes: ["source.coffee"]
    expect(tokens[1]).toEqual value: "==", scopes: ["source.coffee", "keyword.operator.comparison.coffee"]
    expect(tokens[2]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("false == b")
    expect(tokens[0]).toEqual value: "false", scopes: ["source.coffee", "constant.language.boolean.false.coffee"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee"]
    expect(tokens[2]).toEqual value: "==", scopes: ["source.coffee", "keyword.operator.comparison.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("true == b")
    expect(tokens[0]).toEqual value: "true", scopes: ["source.coffee", "constant.language.boolean.true.coffee"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee"]
    expect(tokens[2]).toEqual value: "==", scopes: ["source.coffee", "keyword.operator.comparison.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("null == b")
    expect(tokens[0]).toEqual value: "null", scopes: ["source.coffee", "constant.language.null.coffee"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee"]
    expect(tokens[2]).toEqual value: "==", scopes: ["source.coffee", "keyword.operator.comparison.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

    {tokens} = grammar.tokenizeLine("this == b")
    expect(tokens[0]).toEqual value: "this", scopes: ["source.coffee", "variable.language.this.coffee"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee"]
    expect(tokens[2]).toEqual value: "==", scopes: ["source.coffee", "keyword.operator.comparison.coffee"]
    expect(tokens[3]).toEqual value: " b", scopes: ["source.coffee"]

  it "tokenizes compound operators properly", ->
    assignmentOperators = ["and=", "or=", "&&=", "||=", "/=", "*=", "%=", "+=", "-="]
    bitwiseOperators = ["<<=", ">>=", ">>>=", "&=", "|=", "^="]
    comparisonOperators = ["==", "!=", "<=", ">="]

    for assignmentOperator in assignmentOperators
      {tokens} = grammar.tokenizeLine(assignmentOperator)
      expect(tokens[0]).toEqual value: assignmentOperator, scopes: ["source.coffee", "keyword.operator.assignment.compound.coffee"]

    for bitwiseOperator in bitwiseOperators
      {tokens} = grammar.tokenizeLine(bitwiseOperator)
      expect(tokens[0]).toEqual value: bitwiseOperator, scopes: ["source.coffee", "keyword.operator.assignment.compound.bitwise.coffee"]

    for comparisonOperator in comparisonOperators
      {tokens} = grammar.tokenizeLine(comparisonOperator)
      expect(tokens[0]).toEqual value: comparisonOperator, scopes: ["source.coffee", "keyword.operator.comparison.coffee"]

  it "tokenizes operators properly", ->
    logicalOperators = ["!", "&&", "||", "and", "or", "not"]
    bitwiseOperators = ["^", "~", "&", "|"]
    comparisonOperators = ["<", ">", "is", "isnt"]
    decrementOperators = ["--"]
    incrementOperators = ["++"]
    splatOperators = ["..."]
    existentialOperators = ["?"]
    operators = ["%", "*", "/", "-", "+"]
    keywords = ["delete", "instanceof", "new", "typeof"]

    for logicalOperator in logicalOperators
      {tokens} = grammar.tokenizeLine(logicalOperator)
      expect(tokens[0]).toEqual value: logicalOperator, scopes: ["source.coffee", "keyword.operator.logical.coffee"]

    for bitwiseOperator in bitwiseOperators
      {tokens} = grammar.tokenizeLine(bitwiseOperator)
      expect(tokens[0]).toEqual value: bitwiseOperator, scopes: ["source.coffee", "keyword.operator.bitwise.coffee"]

    for comparisonOperator in comparisonOperators
      {tokens} = grammar.tokenizeLine(comparisonOperator)
      expect(tokens[0]).toEqual value: comparisonOperator, scopes: ["source.coffee", "keyword.operator.comparison.coffee"]

    for decrementOperator in decrementOperators
      {tokens} = grammar.tokenizeLine(decrementOperator)
      expect(tokens[0]).toEqual value: decrementOperator, scopes: ["source.coffee", "keyword.operator.decrement.coffee"]

    for incrementOperator in incrementOperators
      {tokens} = grammar.tokenizeLine(incrementOperator)
      expect(tokens[0]).toEqual value: incrementOperator, scopes: ["source.coffee", "keyword.operator.increment.coffee"]

    for splatOperator in splatOperators
      {tokens} = grammar.tokenizeLine(splatOperator)
      expect(tokens[0]).toEqual value: splatOperator, scopes: ["source.coffee", "keyword.operator.splat.coffee"]

    for existentialOperator in existentialOperators
      {tokens} = grammar.tokenizeLine(existentialOperator)
      expect(tokens[0]).toEqual value: existentialOperator, scopes: ["source.coffee", "keyword.operator.existential.coffee"]

    for operator in operators
      {tokens} = grammar.tokenizeLine(operator)
      expect(tokens[0]).toEqual value: operator, scopes: ["source.coffee", "keyword.operator.coffee"]

    for keyword in keywords
      {tokens} = grammar.tokenizeLine(keyword)
      expect(tokens[0]).toEqual value: keyword, scopes: ["source.coffee", "keyword.operator.#{keyword}.coffee"]

  it "does not tokenize non-operators as operators", ->
    notOperators = ["(/=", "-->", "=>", "->"]

    for notOperator in notOperators
      {tokens} = grammar.tokenizeLine(notOperator)
      expect(tokens[0]).not.toEqual value: notOperator, scopes: ["source.coffee", "keyword.operator.coffee"]

  describe "properties", ->
    it "tokenizes properties", ->
      {tokens} = grammar.tokenizeLine('obj.property')
      expect(tokens[0]).toEqual value: 'obj', scopes: ['source.coffee', 'variable.other.object.coffee']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.coffee', 'meta.delimiter.property.period.coffee']
      expect(tokens[2]).toEqual value: 'property', scopes: ['source.coffee', 'variable.other.property.coffee']

      {tokens} = grammar.tokenizeLine('obj.property.property')
      expect(tokens[0]).toEqual value: 'obj', scopes: ['source.coffee', 'variable.other.object.coffee']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.coffee', 'meta.delimiter.property.period.coffee']
      expect(tokens[2]).toEqual value: 'property', scopes: ['source.coffee', 'variable.other.object.property.coffee']

      {tokens} = grammar.tokenizeLine('obj.Property')
      expect(tokens[0]).toEqual value: 'obj', scopes: ['source.coffee', 'variable.other.object.coffee']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.coffee', 'meta.delimiter.property.period.coffee']
      expect(tokens[2]).toEqual value: 'Property', scopes: ['source.coffee', 'variable.other.property.coffee']

      {tokens} = grammar.tokenizeLine('obj.prop1?.prop2?')
      expect(tokens[0]).toEqual value: 'obj', scopes: ['source.coffee', 'variable.other.object.coffee']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.coffee', 'meta.delimiter.property.period.coffee']
      expect(tokens[2]).toEqual value: 'prop1', scopes: ['source.coffee', 'variable.other.object.property.coffee']
      expect(tokens[3]).toEqual value: '?', scopes: ['source.coffee', 'keyword.operator.existential.coffee']
      expect(tokens[4]).toEqual value: '.', scopes: ['source.coffee', 'meta.delimiter.property.period.coffee']
      expect(tokens[5]).toEqual value: 'prop2', scopes: ['source.coffee', 'variable.other.property.coffee']
      expect(tokens[6]).toEqual value: '?', scopes: ['source.coffee', 'keyword.operator.existential.coffee']

      {tokens} = grammar.tokenizeLine('obj.$abc$')
      expect(tokens[2]).toEqual value: '$abc$', scopes: ['source.coffee', 'variable.other.property.coffee']

      {tokens} = grammar.tokenizeLine('obj.$$')
      expect(tokens[2]).toEqual value: '$$', scopes: ['source.coffee', 'variable.other.property.coffee']

      {tokens} = grammar.tokenizeLine('a().b')
      expect(tokens[2]).toEqual value: ')', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.end.bracket.round.coffee']
      expect(tokens[3]).toEqual value: '.', scopes: ['source.coffee', 'meta.delimiter.property.period.coffee']
      expect(tokens[4]).toEqual value: 'b', scopes: ['source.coffee', 'variable.other.property.coffee']

      {tokens} = grammar.tokenizeLine('a.123illegal')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.coffee']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.coffee', 'meta.delimiter.property.period.coffee']
      expect(tokens[2]).toEqual value: '123illegal', scopes: ['source.coffee', 'invalid.illegal.identifier.coffee']

    it "tokenizes constant properties", ->
      {tokens} = grammar.tokenizeLine('obj.MY_CONSTANT')
      expect(tokens[0]).toEqual value: 'obj', scopes: ['source.coffee', 'variable.other.object.coffee']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.coffee', 'meta.delimiter.property.period.coffee']
      expect(tokens[2]).toEqual value: 'MY_CONSTANT', scopes: ['source.coffee', 'constant.other.property.coffee']

      {tokens} = grammar.tokenizeLine('obj.MY_CONSTANT.prop')
      expect(tokens[0]).toEqual value: 'obj', scopes: ['source.coffee', 'variable.other.object.coffee']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.coffee', 'meta.delimiter.property.period.coffee']
      expect(tokens[2]).toEqual value: 'MY_CONSTANT', scopes: ['source.coffee', 'constant.other.object.property.coffee']

      {tokens} = grammar.tokenizeLine('a.C')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.coffee', 'variable.other.object.coffee']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.coffee', 'meta.delimiter.property.period.coffee']
      expect(tokens[2]).toEqual value: 'C', scopes: ['source.coffee', 'constant.other.property.coffee']

    it "does not confuse prototype properties with constants and keywords", ->
      {tokens} = grammar.tokenizeLine("Foo::true")
      expect(tokens[0]).toEqual value: "Foo", scopes: ["source.coffee"]
      expect(tokens[1]).toEqual value: "::", scopes: ["source.coffee", "keyword.operator.prototype.coffee"]
      expect(tokens[2]).toEqual value: "true", scopes: ["source.coffee"]

      {tokens} = grammar.tokenizeLine("Foo::on")
      expect(tokens[0]).toEqual value: "Foo", scopes: ["source.coffee"]
      expect(tokens[1]).toEqual value: "::", scopes: ["source.coffee", "keyword.operator.prototype.coffee"]
      expect(tokens[2]).toEqual value: "on", scopes: ["source.coffee"]

      {tokens} = grammar.tokenizeLine("Foo::yes")
      expect(tokens[0]).toEqual value: "Foo", scopes: ["source.coffee"]
      expect(tokens[1]).toEqual value: "::", scopes: ["source.coffee", "keyword.operator.prototype.coffee"]
      expect(tokens[2]).toEqual value: "yes", scopes: ["source.coffee"]

      {tokens} = grammar.tokenizeLine("Foo::false")
      expect(tokens[0]).toEqual value: "Foo", scopes: ["source.coffee"]
      expect(tokens[1]).toEqual value: "::", scopes: ["source.coffee", "keyword.operator.prototype.coffee"]
      expect(tokens[2]).toEqual value: "false", scopes: ["source.coffee"]

      {tokens} = grammar.tokenizeLine("Foo::off")
      expect(tokens[0]).toEqual value: "Foo", scopes: ["source.coffee"]
      expect(tokens[1]).toEqual value: "::", scopes: ["source.coffee", "keyword.operator.prototype.coffee"]
      expect(tokens[2]).toEqual value: "off", scopes: ["source.coffee"]

      {tokens} = grammar.tokenizeLine("Foo::no")
      expect(tokens[0]).toEqual value: "Foo", scopes: ["source.coffee"]
      expect(tokens[1]).toEqual value: "::", scopes: ["source.coffee", "keyword.operator.prototype.coffee"]
      expect(tokens[2]).toEqual value: "no", scopes: ["source.coffee"]

      {tokens} = grammar.tokenizeLine("Foo::null")
      expect(tokens[0]).toEqual value: "Foo", scopes: ["source.coffee"]
      expect(tokens[1]).toEqual value: "::", scopes: ["source.coffee", "keyword.operator.prototype.coffee"]
      expect(tokens[2]).toEqual value: "null", scopes: ["source.coffee"]

      {tokens} = grammar.tokenizeLine("Foo::extends")
      expect(tokens[0]).toEqual value: "Foo", scopes: ["source.coffee"]
      expect(tokens[1]).toEqual value: "::", scopes: ["source.coffee", "keyword.operator.prototype.coffee"]
      expect(tokens[2]).toEqual value: "extends", scopes: ["source.coffee"]

  describe "variables", ->
    it "tokenizes 'this'", ->
      {tokens} = grammar.tokenizeLine('this')
      expect(tokens[0]).toEqual value: 'this', scopes: ['source.coffee', 'variable.language.this.coffee']

      {tokens} = grammar.tokenizeLine('this.obj.prototype = new El()')
      expect(tokens[0]).toEqual value: 'this', scopes: ['source.coffee', 'variable.language.this.coffee']

      {tokens} = grammar.tokenizeLine('$this')
      expect(tokens[0]).toEqual value: '$this', scopes: ['source.coffee']

      {tokens} = grammar.tokenizeLine('this$')
      expect(tokens[0]).toEqual value: 'this$', scopes: ['source.coffee']

    it "tokenizes 'super'", ->
      {tokens} = grammar.tokenizeLine('super')
      expect(tokens[0]).toEqual value: 'super', scopes: ['source.coffee', 'variable.language.super.coffee']

    it "tokenizes 'arguments'", ->
      {tokens} = grammar.tokenizeLine('arguments')
      expect(tokens[0]).toEqual value: 'arguments', scopes: ['source.coffee', 'variable.language.arguments.coffee']

      {tokens} = grammar.tokenizeLine('arguments[0]')
      expect(tokens[0]).toEqual value: 'arguments', scopes: ['source.coffee', 'variable.language.arguments.coffee']

      {tokens} = grammar.tokenizeLine('arguments.length')
      expect(tokens[0]).toEqual value: 'arguments', scopes: ['source.coffee', 'variable.language.arguments.coffee']

    it "tokenizes illegal identifiers", ->
      {tokens} = grammar.tokenizeLine('0illegal')
      expect(tokens[0]).toEqual value: '0illegal', scopes: ['source.coffee', 'invalid.illegal.identifier.coffee']

      {tokens} = grammar.tokenizeLine('123illegal')
      expect(tokens[0]).toEqual value: '123illegal', scopes: ['source.coffee', 'invalid.illegal.identifier.coffee']

      {tokens} = grammar.tokenizeLine('123$illegal')
      expect(tokens[0]).toEqual value: '123$illegal', scopes: ['source.coffee', 'invalid.illegal.identifier.coffee']

    describe "objects", ->
      it "tokenizes them", ->
        {tokens} = grammar.tokenizeLine('obj.prop')
        expect(tokens[0]).toEqual value: 'obj', scopes: ['source.coffee', 'variable.other.object.coffee']

        {tokens} = grammar.tokenizeLine('$abc$.prop')
        expect(tokens[0]).toEqual value: '$abc$', scopes: ['source.coffee', 'variable.other.object.coffee']

        {tokens} = grammar.tokenizeLine('$$.prop')
        expect(tokens[0]).toEqual value: '$$', scopes: ['source.coffee', 'variable.other.object.coffee']

        {tokens} = grammar.tokenizeLine('obj?.prop')
        expect(tokens[0]).toEqual value: 'obj', scopes: ['source.coffee', 'variable.other.object.coffee']
        expect(tokens[1]).toEqual value: '?', scopes: ['source.coffee', 'keyword.operator.existential.coffee']

      it "tokenizes illegal objects", ->
        {tokens} = grammar.tokenizeLine('1.prop')
        expect(tokens[0]).toEqual value: '1', scopes: ['source.coffee', 'invalid.illegal.identifier.coffee']

        {tokens} = grammar.tokenizeLine('123.prop')
        expect(tokens[0]).toEqual value: '123', scopes: ['source.coffee', 'invalid.illegal.identifier.coffee']

        {tokens} = grammar.tokenizeLine('123a.prop')
        expect(tokens[0]).toEqual value: '123a', scopes: ['source.coffee', 'invalid.illegal.identifier.coffee']

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

  describe "function calls", ->
    it "tokenizes function calls", ->
      {tokens} = grammar.tokenizeLine('functionCall()')
      expect(tokens[0]).toEqual value: 'functionCall', scopes: ['source.coffee', 'meta.function-call.coffee', 'entity.name.function.coffee']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.begin.bracket.round.coffee']
      expect(tokens[2]).toEqual value: ')', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.end.bracket.round.coffee']

      {tokens} = grammar.tokenizeLine('functionCall(arg1, "test", {a: 123})')
      expect(tokens[0]).toEqual value: 'functionCall', scopes: ['source.coffee', 'meta.function-call.coffee', 'entity.name.function.coffee']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.begin.bracket.round.coffee']
      expect(tokens[2]).toEqual value: 'arg1', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee']
      expect(tokens[3]).toEqual value: ',', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.delimiter.object.comma.coffee']
      expect(tokens[5]).toEqual value: '"', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'string.quoted.double.coffee', 'punctuation.definition.string.begin.coffee']
      expect(tokens[6]).toEqual value: 'test', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'string.quoted.double.coffee']
      expect(tokens[7]).toEqual value: '"', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'string.quoted.double.coffee', 'punctuation.definition.string.end.coffee']
      expect(tokens[8]).toEqual value: ',', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.delimiter.object.comma.coffee']
      expect(tokens[10]).toEqual value: '{', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.brace.curly.coffee']
      expect(tokens[11]).toEqual value: 'a', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'variable.assignment.coffee']
      expect(tokens[12]).toEqual value: ':', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'keyword.operator.assignment.coffee']
      expect(tokens[14]).toEqual value: '123', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'constant.numeric.decimal.coffee']
      expect(tokens[15]).toEqual value: '}', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.brace.curly.coffee']
      expect(tokens[16]).toEqual value: ')', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.end.bracket.round.coffee']

      {tokens} = grammar.tokenizeLine('functionCall((123).toString())')
      expect(tokens[1]).toEqual value: '(', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.begin.bracket.round.coffee']
      expect(tokens[2]).toEqual value: '(', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.brace.round.coffee']
      expect(tokens[3]).toEqual value: '123', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'constant.numeric.decimal.coffee']
      expect(tokens[4]).toEqual value: ')', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.brace.round.coffee']
      expect(tokens[9]).toEqual value: ')', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.end.bracket.round.coffee']

      {tokens} = grammar.tokenizeLine('$abc$()')
      expect(tokens[0]).toEqual value: '$abc$', scopes: ['source.coffee', 'meta.function-call.coffee', 'entity.name.function.coffee']

      {tokens} = grammar.tokenizeLine('$$()')
      expect(tokens[0]).toEqual value: '$$', scopes: ['source.coffee', 'meta.function-call.coffee', 'entity.name.function.coffee']

      {tokens} = grammar.tokenizeLine('ABC()')
      expect(tokens[0]).toEqual value: 'ABC', scopes: ['source.coffee', 'meta.function-call.coffee', 'entity.name.function.coffee']

      {tokens} = grammar.tokenizeLine('$ABC$()')
      expect(tokens[0]).toEqual value: '$ABC$', scopes: ['source.coffee', 'meta.function-call.coffee', 'entity.name.function.coffee']

      {tokens} = grammar.tokenizeLine('@$()')
      expect(tokens[0]).toEqual value: '@', scopes: ['source.coffee', 'meta.function-call.coffee', 'variable.other.readwrite.instance.coffee']
      expect(tokens[1]).toEqual value: '$', scopes: ['source.coffee', 'meta.function-call.coffee', 'entity.name.function.coffee']

      {tokens} = grammar.tokenizeLine('functionCall arg1, "test", {a: 123}')
      expect(tokens[0]).toEqual value: 'functionCall', scopes: ['source.coffee', 'meta.function-call.coffee', 'entity.name.function.coffee']
      expect(tokens[2]).toEqual value: 'arg1', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee']
      expect(tokens[3]).toEqual value: ',', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.delimiter.object.comma.coffee']
      expect(tokens[5]).toEqual value: '"', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'string.quoted.double.coffee', 'punctuation.definition.string.begin.coffee']
      expect(tokens[6]).toEqual value: 'test', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'string.quoted.double.coffee']
      expect(tokens[7]).toEqual value: '"', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'string.quoted.double.coffee', 'punctuation.definition.string.end.coffee']
      expect(tokens[8]).toEqual value: ',', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.delimiter.object.comma.coffee']
      expect(tokens[10]).toEqual value: '{', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.brace.curly.coffee']
      expect(tokens[11]).toEqual value: 'a', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'variable.assignment.coffee']
      expect(tokens[12]).toEqual value: ':', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'keyword.operator.assignment.coffee']
      expect(tokens[14]).toEqual value: '123', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'constant.numeric.decimal.coffee']
      expect(tokens[15]).toEqual value: '}', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.brace.curly.coffee']

      {tokens} = grammar.tokenizeLine("foo bar")
      expect(tokens[0]).toEqual value: "foo", scopes: ["source.coffee", "meta.function-call.coffee", "entity.name.function.coffee"]
      expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee", "meta.function-call.coffee"]
      expect(tokens[2]).toEqual value: "bar", scopes: ["source.coffee", "meta.function-call.coffee", "meta.arguments.coffee"]

      {tokens} = grammar.tokenizeLine("eat food for food in foods")
      expect(tokens[0]).toEqual value: "eat", scopes: ["source.coffee", "meta.function-call.coffee", "entity.name.function.coffee"]
      expect(tokens[2]).toEqual value: "food", scopes: ["source.coffee", "meta.function-call.coffee", "meta.arguments.coffee"]
      expect(tokens[4]).toEqual value: "for", scopes: ["source.coffee", "keyword.control.coffee"]
      expect(tokens[5]).toEqual value: " food ", scopes: ["source.coffee"]
      expect(tokens[6]).toEqual value: "in", scopes: ["source.coffee", "keyword.control.coffee"]
      expect(tokens[7]).toEqual value: " foods", scopes: ["source.coffee"]

      {tokens} = grammar.tokenizeLine("foo @bar")
      expect(tokens[0]).toEqual value: "foo", scopes: ["source.coffee", "meta.function-call.coffee", "entity.name.function.coffee"]
      expect(tokens[2]).toEqual value: "@bar", scopes: ["source.coffee", "meta.function-call.coffee", "meta.arguments.coffee", "variable.other.readwrite.instance.coffee"]

      {tokens} = grammar.tokenizeLine("@foo bar")
      expect(tokens[0]).toEqual value: "@", scopes: ["source.coffee", "meta.function-call.coffee", "variable.other.readwrite.instance.coffee"]
      expect(tokens[1]).toEqual value: "foo", scopes: ["source.coffee", "meta.function-call.coffee", "entity.name.function.coffee"]
      expect(tokens[3]).toEqual value: "bar", scopes: ["source.coffee", "meta.function-call.coffee", "meta.arguments.coffee"]

      {tokens} = grammar.tokenizeLine("foo baz, @bar")
      expect(tokens[0]).toEqual value: "foo", scopes: ["source.coffee", "meta.function-call.coffee", "entity.name.function.coffee"]
      expect(tokens[2]).toEqual value: "baz", scopes: ["source.coffee", "meta.function-call.coffee", "meta.arguments.coffee"]
      expect(tokens[3]).toEqual value: ",", scopes: ["source.coffee", "meta.function-call.coffee", "meta.arguments.coffee", "meta.delimiter.object.comma.coffee"]
      expect(tokens[5]).toEqual value: "@bar", scopes: ["source.coffee", "meta.function-call.coffee", "meta.arguments.coffee", "variable.other.readwrite.instance.coffee"]

      {tokens} = grammar.tokenizeLine("$ @$")
      expect(tokens[0]).toEqual value: "$", scopes: ["source.coffee", "meta.function-call.coffee", "entity.name.function.coffee"]
      expect(tokens[2]).toEqual value: "@$", scopes: ["source.coffee", "meta.function-call.coffee", "meta.arguments.coffee", "variable.other.readwrite.instance.coffee"]

    it "tokenizes function calls when they are arguments", ->
      {tokens} = grammar.tokenizeLine('a(b(c))')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.coffee', 'meta.function-call.coffee', 'entity.name.function.coffee']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.begin.bracket.round.coffee']
      expect(tokens[2]).toEqual value: 'b', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.function-call.coffee', 'entity.name.function.coffee']
      expect(tokens[3]).toEqual value: '(', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.begin.bracket.round.coffee']
      expect(tokens[4]).toEqual value: 'c', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee']
      expect(tokens[5]).toEqual value: ')', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.end.bracket.round.coffee']
      expect(tokens[6]).toEqual value: ')', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.end.bracket.round.coffee']

      {tokens} = grammar.tokenizeLine('a b c')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.coffee', 'meta.function-call.coffee', 'entity.name.function.coffee']
      expect(tokens[2]).toEqual value: 'b', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.function-call.coffee', 'entity.name.function.coffee']
      expect(tokens[4]).toEqual value: 'c', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee']

    it "tokenizes illegal function calls", ->
      {tokens} = grammar.tokenizeLine('0illegal()')
      expect(tokens[0]).toEqual value: '0illegal', scopes: ['source.coffee', 'meta.function-call.coffee', 'invalid.illegal.identifier.coffee']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.begin.bracket.round.coffee']
      expect(tokens[2]).toEqual value: ')', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.end.bracket.round.coffee']

    it "tokenizes illegal arguments", ->
      {tokens} = grammar.tokenizeLine('a(1a)')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.coffee', 'meta.function-call.coffee', 'entity.name.function.coffee']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.begin.bracket.round.coffee']
      expect(tokens[2]).toEqual value: '1a', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'invalid.illegal.identifier.coffee']
      expect(tokens[3]).toEqual value: ')', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.end.bracket.round.coffee']

      {tokens} = grammar.tokenizeLine('a(123a)')
      expect(tokens[2]).toEqual value: '123a', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'invalid.illegal.identifier.coffee']

      {tokens} = grammar.tokenizeLine('a(1.prop)')
      expect(tokens[2]).toEqual value: '1', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'invalid.illegal.identifier.coffee']
      expect(tokens[3]).toEqual value: '.', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.delimiter.property.period.coffee']
      expect(tokens[4]).toEqual value: 'prop', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'variable.other.property.coffee']

      {tokens} = grammar.tokenizeLine('a 1a')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.coffee', 'meta.function-call.coffee', 'entity.name.function.coffee']
      expect(tokens[2]).toEqual value: '1a', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'invalid.illegal.identifier.coffee']

    it "tokenizes function declaration as an argument", ->
      {tokens} = grammar.tokenizeLine('a((p) -> return p )')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.coffee', 'meta.function-call.coffee', 'entity.name.function.coffee']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.begin.bracket.round.coffee']
      expect(tokens[2]).toEqual value: '(', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.function.inline.coffee', 'meta.parameters.coffee', 'punctuation.definition.parameters.begin.bracket.round.coffee']
      expect(tokens[3]).toEqual value: 'p', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.function.inline.coffee', 'meta.parameters.coffee', 'variable.parameter.function.coffee']
      expect(tokens[4]).toEqual value: ')', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'meta.function.inline.coffee', 'meta.parameters.coffee', 'punctuation.definition.parameters.end.bracket.round.coffee']
      expect(tokens[8]).toEqual value: 'return', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'keyword.control.coffee']
      expect(tokens[9]).toEqual value: ' p ', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee']
      expect(tokens[10]).toEqual value: ')', scopes: ['source.coffee', 'meta.function-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.end.bracket.round.coffee']

    it "does not tokenize booleans as functions", ->
      {tokens} = grammar.tokenizeLine("false unless true")
      expect(tokens[0]).toEqual value: "false", scopes: ["source.coffee", "constant.language.boolean.false.coffee"]
      expect(tokens[2]).toEqual value: "unless", scopes: ["source.coffee", "keyword.control.coffee"]
      expect(tokens[4]).toEqual value: "true", scopes: ["source.coffee", "constant.language.boolean.true.coffee"]

      {tokens} = grammar.tokenizeLine("true if false")
      expect(tokens[0]).toEqual value: "true", scopes: ["source.coffee", "constant.language.boolean.true.coffee"]
      expect(tokens[2]).toEqual value: "if", scopes: ["source.coffee", "keyword.control.coffee"]
      expect(tokens[4]).toEqual value: "false", scopes: ["source.coffee", "constant.language.boolean.false.coffee"]

  describe "functions", ->
    it "tokenizes regular functions", ->
      {tokens} = grammar.tokenizeLine("foo = -> 1")
      expect(tokens[0]).toEqual value: "foo", scopes: ["source.coffee", "meta.function.coffee", "entity.name.function.coffee"]
      expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee", "meta.function.coffee"]
      expect(tokens[2]).toEqual value: "=", scopes: ["source.coffee", "meta.function.coffee", "keyword.operator.assignment.coffee"]
      expect(tokens[3]).toEqual value: " ", scopes: ["source.coffee", "meta.function.coffee"]
      expect(tokens[4]).toEqual value: "->", scopes: ["source.coffee", "meta.function.coffee", "storage.type.function.coffee"]
      expect(tokens[5]).toEqual value: " ", scopes: ["source.coffee"]
      expect(tokens[6]).toEqual value: "1", scopes: ["source.coffee", "constant.numeric.decimal.coffee"]

      {tokens} = grammar.tokenizeLine("@foo = -> 1")
      expect(tokens[0]).toEqual value: "@", scopes: ["source.coffee", "meta.function.coffee", "entity.name.function.coffee", "variable.other.readwrite.instance.coffee"]
      expect(tokens[1]).toEqual value: "foo", scopes: ["source.coffee", "meta.function.coffee", "entity.name.function.coffee"]
      expect(tokens[3]).toEqual value: "=", scopes: ["source.coffee", "meta.function.coffee", "keyword.operator.assignment.coffee"]

      {tokens} = grammar.tokenizeLine("$ = => 1")
      expect(tokens[0]).toEqual value: "$", scopes: ["source.coffee", "meta.function.coffee", "entity.name.function.coffee"]
      expect(tokens[2]).toEqual value: "=", scopes: ["source.coffee", "meta.function.coffee", "keyword.operator.assignment.coffee"]

      {tokens} = grammar.tokenizeLine("foo: -> 1")
      expect(tokens[0]).toEqual value: "foo", scopes: ["source.coffee", "meta.function.coffee", "entity.name.function.coffee"]
      expect(tokens[1]).toEqual value: ":", scopes: ["source.coffee", "meta.function.coffee", "keyword.operator.assignment.coffee"]
      expect(tokens[2]).toEqual value: " ", scopes: ["source.coffee", "meta.function.coffee"]
      expect(tokens[3]).toEqual value: "->", scopes: ["source.coffee", "meta.function.coffee", "storage.type.function.coffee"]
      expect(tokens[4]).toEqual value: " ", scopes: ["source.coffee"]
      expect(tokens[5]).toEqual value: "1", scopes: ["source.coffee", "constant.numeric.decimal.coffee"]

      {tokens} = grammar.tokenizeLine("'quoted': (a) => true")
      expect(tokens[0]).toEqual value: "'", scopes: ["source.coffee", "meta.function.coffee", "string.quoted.single.coffee", "punctuation.definition.string.begin.coffee"]
      expect(tokens[1]).toEqual value: "quoted", scopes: ["source.coffee", "meta.function.coffee", "string.quoted.single.coffee", "entity.name.function.coffee"]
      expect(tokens[2]).toEqual value: "'", scopes: ["source.coffee", "meta.function.coffee", "string.quoted.single.coffee", "punctuation.definition.string.end.coffee"]
      expect(tokens[3]).toEqual value: ":", scopes: ["source.coffee", "meta.function.coffee", "keyword.operator.assignment.coffee"]
      expect(tokens[4]).toEqual value: " ", scopes: ["source.coffee", "meta.function.coffee"]
      expect(tokens[5]).toEqual value: "(", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "punctuation.definition.parameters.begin.bracket.round.coffee"]
      expect(tokens[6]).toEqual value: "a", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "variable.parameter.function.coffee"]
      expect(tokens[7]).toEqual value: ")", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "punctuation.definition.parameters.end.bracket.round.coffee"]
      expect(tokens[8]).toEqual value: " ", scopes: ["source.coffee", "meta.function.coffee"]
      expect(tokens[9]).toEqual value: "=>", scopes: ["source.coffee", "meta.function.coffee", "storage.type.function.coffee"]
      expect(tokens[10]).toEqual value: " ", scopes: ["source.coffee"]
      expect(tokens[11]).toEqual value: "true", scopes: ["source.coffee", "constant.language.boolean.true.coffee"]

      {tokens} = grammar.tokenizeLine('"quoted": (a) -> true')
      expect(tokens[0]).toEqual value: '"', scopes: ["source.coffee", "meta.function.coffee", "string.quoted.double.coffee", "punctuation.definition.string.begin.coffee"]
      expect(tokens[1]).toEqual value: "quoted", scopes: ["source.coffee", "meta.function.coffee", "string.quoted.double.coffee", "entity.name.function.coffee"]
      expect(tokens[2]).toEqual value: '"', scopes: ["source.coffee", "meta.function.coffee", "string.quoted.double.coffee", "punctuation.definition.string.end.coffee"]
      expect(tokens[3]).toEqual value: ":", scopes: ["source.coffee", "meta.function.coffee", "keyword.operator.assignment.coffee"]
      expect(tokens[4]).toEqual value: " ", scopes: ["source.coffee", "meta.function.coffee"]
      expect(tokens[5]).toEqual value: "(", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "punctuation.definition.parameters.begin.bracket.round.coffee"]
      expect(tokens[6]).toEqual value: "a", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "variable.parameter.function.coffee"]
      expect(tokens[7]).toEqual value: ")", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "punctuation.definition.parameters.end.bracket.round.coffee"]
      expect(tokens[8]).toEqual value: " ", scopes: ["source.coffee", "meta.function.coffee"]
      expect(tokens[9]).toEqual value: "->", scopes: ["source.coffee", "meta.function.coffee", "storage.type.function.coffee"]
      expect(tokens[10]).toEqual value: " ", scopes: ["source.coffee"]
      expect(tokens[11]).toEqual value: "true", scopes: ["source.coffee", "constant.language.boolean.true.coffee"]

      {tokens} = grammar.tokenizeLine("hello: (a) -> 1")
      expect(tokens[0]).toEqual value: "hello", scopes: ["source.coffee", "meta.function.coffee", "entity.name.function.coffee"]
      expect(tokens[1]).toEqual value: ":", scopes: ["source.coffee", "meta.function.coffee", "keyword.operator.assignment.coffee"]
      expect(tokens[2]).toEqual value: " ", scopes: ["source.coffee", "meta.function.coffee"]
      expect(tokens[3]).toEqual value: "(", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "punctuation.definition.parameters.begin.bracket.round.coffee"]
      expect(tokens[4]).toEqual value: "a", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "variable.parameter.function.coffee"]
      expect(tokens[5]).toEqual value: ")", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "punctuation.definition.parameters.end.bracket.round.coffee"]
      expect(tokens[6]).toEqual value: " ", scopes: ["source.coffee", "meta.function.coffee"]
      expect(tokens[7]).toEqual value: "->", scopes: ["source.coffee", "meta.function.coffee", "storage.type.function.coffee"]
      expect(tokens[9]).toEqual value: "1", scopes: ["source.coffee", "constant.numeric.decimal.coffee"]

      {tokens} = grammar.tokenizeLine("hello: (a, b, {c, d}, e = 'test', f = 3, g = -> 4) -> 1")
      expect(tokens[0]).toEqual value: "hello", scopes: ["source.coffee", "meta.function.coffee", "entity.name.function.coffee"]
      expect(tokens[1]).toEqual value: ":", scopes: ["source.coffee", "meta.function.coffee", "keyword.operator.assignment.coffee"]
      expect(tokens[3]).toEqual value: "(", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "punctuation.definition.parameters.begin.bracket.round.coffee"]
      expect(tokens[4]).toEqual value: "a", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "variable.parameter.function.coffee"]
      expect(tokens[5]).toEqual value: ",", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "meta.delimiter.object.comma.coffee"]
      expect(tokens[6]).toEqual value: " ", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee"]
      expect(tokens[7]).toEqual value: "b", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "variable.parameter.function.coffee"]
      expect(tokens[8]).toEqual value: ",", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "meta.delimiter.object.comma.coffee"]
      expect(tokens[10]).toEqual value: "{", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "meta.brace.curly.coffee"]
      expect(tokens[11]).toEqual value: "c", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee"]
      expect(tokens[12]).toEqual value: ",", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "meta.delimiter.object.comma.coffee"]
      expect(tokens[13]).toEqual value: " d", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee"]
      expect(tokens[14]).toEqual value: "}", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "meta.brace.curly.coffee"]
      expect(tokens[17]).toEqual value: "e", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "variable.parameter.function.coffee"]
      expect(tokens[19]).toEqual value: "=", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "keyword.operator.assignment.coffee"]
      expect(tokens[21]).toEqual value: "'", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "string.quoted.single.coffee", "punctuation.definition.string.begin.coffee"]
      expect(tokens[24]).toEqual value: ",", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "meta.delimiter.object.comma.coffee"]
      expect(tokens[26]).toEqual value: "f", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "variable.parameter.function.coffee"]
      expect(tokens[30]).toEqual value: "3", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "constant.numeric.decimal.coffee"]
      expect(tokens[33]).toEqual value: "g", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "variable.parameter.function.coffee"]
      expect(tokens[35]).toEqual value: "=", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "keyword.operator.assignment.coffee"]
      expect(tokens[37]).toEqual value: "->", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "meta.function.inline.coffee", "storage.type.function.coffee"]
      expect(tokens[40]).toEqual value: ")", scopes: ["source.coffee", "meta.function.coffee", "meta.parameters.coffee", "punctuation.definition.parameters.end.bracket.round.coffee"]
      expect(tokens[42]).toEqual value: "->", scopes: ["source.coffee", "meta.function.coffee", "storage.type.function.coffee"]

    it "tokenizes inline functions", ->
      {tokens} = grammar.tokenizeLine("-> true")
      expect(tokens[0]).toEqual value: "->", scopes: ["source.coffee", "meta.function.inline.coffee", "storage.type.function.coffee"]
      expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee"]

      {tokens} = grammar.tokenizeLine(" -> true")
      expect(tokens[0]).toEqual value: " ", scopes: ["source.coffee"]
      expect(tokens[1]).toEqual value: "->", scopes: ["source.coffee", "meta.function.inline.coffee", "storage.type.function.coffee"]
      expect(tokens[2]).toEqual value: " ", scopes: ["source.coffee"]

      {tokens} = grammar.tokenizeLine("->true")
      expect(tokens[0]).toEqual value: "->", scopes: ["source.coffee", "meta.function.inline.coffee", "storage.type.function.coffee"]

      {tokens} = grammar.tokenizeLine("(arg) -> true")
      expect(tokens[0]).toEqual value: "(", scopes: ["source.coffee", "meta.function.inline.coffee", "meta.parameters.coffee", "punctuation.definition.parameters.begin.bracket.round.coffee"]
      expect(tokens[1]).toEqual value: "arg", scopes: ["source.coffee", "meta.function.inline.coffee", "meta.parameters.coffee", "variable.parameter.function.coffee"]
      expect(tokens[2]).toEqual value: ")", scopes: ["source.coffee", "meta.function.inline.coffee", "meta.parameters.coffee", "punctuation.definition.parameters.end.bracket.round.coffee"]
      expect(tokens[3]).toEqual value: " ", scopes: ["source.coffee", "meta.function.inline.coffee"]
      expect(tokens[4]).toEqual value: "->", scopes: ["source.coffee", "meta.function.inline.coffee", "storage.type.function.coffee"]
      expect(tokens[5]).toEqual value: " ", scopes: ["source.coffee"]

      {tokens} = grammar.tokenizeLine("(arg1, arg2) -> true")
      expect(tokens[0]).toEqual value: "(", scopes: ["source.coffee", "meta.function.inline.coffee", "meta.parameters.coffee", "punctuation.definition.parameters.begin.bracket.round.coffee"]
      expect(tokens[1]).toEqual value: "arg1", scopes: ["source.coffee", "meta.function.inline.coffee", "meta.parameters.coffee", "variable.parameter.function.coffee"]
      expect(tokens[2]).toEqual value: ",", scopes: ["source.coffee", "meta.function.inline.coffee", "meta.parameters.coffee", "meta.delimiter.object.comma.coffee"]
      expect(tokens[3]).toEqual value: " ", scopes: ["source.coffee", "meta.function.inline.coffee", "meta.parameters.coffee"]
      expect(tokens[4]).toEqual value: "arg2", scopes: ["source.coffee", "meta.function.inline.coffee", "meta.parameters.coffee", "variable.parameter.function.coffee"]
      expect(tokens[5]).toEqual value: ")", scopes: ["source.coffee", "meta.function.inline.coffee", "meta.parameters.coffee", "punctuation.definition.parameters.end.bracket.round.coffee"]
      expect(tokens[6]).toEqual value: " ", scopes: ["source.coffee", "meta.function.inline.coffee"]
      expect(tokens[7]).toEqual value: "->", scopes: ["source.coffee", "meta.function.inline.coffee", "storage.type.function.coffee"]
      expect(tokens[8]).toEqual value: " ", scopes: ["source.coffee"]

      {tokens} = grammar.tokenizeLine("( arg1, arg2 )-> true")
      expect(tokens[0]).toEqual value: "(", scopes: ["source.coffee", "meta.function.inline.coffee", "meta.parameters.coffee", "punctuation.definition.parameters.begin.bracket.round.coffee"]
      expect(tokens[1]).toEqual value: " ", scopes: ["source.coffee", "meta.function.inline.coffee", "meta.parameters.coffee"]
      expect(tokens[2]).toEqual value: "arg1", scopes: ["source.coffee", "meta.function.inline.coffee", "meta.parameters.coffee", "variable.parameter.function.coffee"]
      expect(tokens[3]).toEqual value: ",", scopes: ["source.coffee", "meta.function.inline.coffee", "meta.parameters.coffee", "meta.delimiter.object.comma.coffee"]
      expect(tokens[4]).toEqual value: " ", scopes: ["source.coffee", "meta.function.inline.coffee", "meta.parameters.coffee"]
      expect(tokens[5]).toEqual value: "arg2", scopes: ["source.coffee", "meta.function.inline.coffee", "meta.parameters.coffee", "variable.parameter.function.coffee"]
      expect(tokens[6]).toEqual value: " ", scopes: ["source.coffee", "meta.function.inline.coffee", "meta.parameters.coffee"]
      expect(tokens[7]).toEqual value: ")", scopes: ["source.coffee", "meta.function.inline.coffee", "meta.parameters.coffee", "punctuation.definition.parameters.end.bracket.round.coffee"]
      expect(tokens[8]).toEqual value: "->", scopes: ["source.coffee", "meta.function.inline.coffee", "storage.type.function.coffee"]
      expect(tokens[9]).toEqual value: " ", scopes: ["source.coffee"]

  describe "method calls", ->
    it "tokenizes method calls", ->
      {tokens} = grammar.tokenizeLine('a.b(1+1)')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.coffee', 'variable.other.object.coffee']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.coffee', 'meta.method-call.coffee', 'meta.delimiter.method.period.coffee']
      expect(tokens[2]).toEqual value: 'b', scopes: ['source.coffee', 'meta.method-call.coffee', 'entity.name.function.coffee']
      expect(tokens[3]).toEqual value: '(', scopes: ['source.coffee', 'meta.method-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.begin.bracket.round.coffee']
      expect(tokens[4]).toEqual value: '1', scopes: ['source.coffee', 'meta.method-call.coffee', 'meta.arguments.coffee', 'constant.numeric.decimal.coffee']
      expect(tokens[5]).toEqual value: '+', scopes: ['source.coffee', 'meta.method-call.coffee', 'meta.arguments.coffee', 'keyword.operator.coffee']
      expect(tokens[6]).toEqual value: '1', scopes: ['source.coffee', 'meta.method-call.coffee', 'meta.arguments.coffee', 'constant.numeric.decimal.coffee']
      expect(tokens[7]).toEqual value: ')', scopes: ['source.coffee', 'meta.method-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.end.bracket.round.coffee']

      {tokens} = grammar.tokenizeLine('a . b(1+1)')
      expect(tokens[2]).toEqual value: '.', scopes: ['source.coffee', 'meta.method-call.coffee', 'meta.delimiter.method.period.coffee']
      expect(tokens[4]).toEqual value: 'b', scopes: ['source.coffee', 'meta.method-call.coffee', 'entity.name.function.coffee']
      expect(tokens[5]).toEqual value: '(', scopes: ['source.coffee', 'meta.method-call.coffee', 'meta.arguments.coffee', 'punctuation.definition.arguments.begin.bracket.round.coffee']

      {tokens} = grammar.tokenizeLine('a.$abc$()')
      expect(tokens[2]).toEqual value: '$abc$', scopes: ['source.coffee', 'meta.method-call.coffee', 'entity.name.function.coffee']

      {tokens} = grammar.tokenizeLine('a.$$()')
      expect(tokens[2]).toEqual value: '$$', scopes: ['source.coffee', 'meta.method-call.coffee', 'entity.name.function.coffee']

      {tokens} = grammar.tokenizeLine('a.b c')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.coffee', 'variable.other.object.coffee']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.coffee', 'meta.method-call.coffee', 'meta.delimiter.method.period.coffee']
      expect(tokens[2]).toEqual value: 'b', scopes: ['source.coffee', 'meta.method-call.coffee', 'entity.name.function.coffee']
      expect(tokens[3]).toEqual value: ' ', scopes: ['source.coffee', 'meta.method-call.coffee']
      expect(tokens[4]).toEqual value: 'c', scopes: ['source.coffee', 'meta.method-call.coffee', 'meta.arguments.coffee']

      {tokens} = grammar.tokenizeLine('a.b 1+1')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.coffee', 'variable.other.object.coffee']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.coffee', 'meta.method-call.coffee', 'meta.delimiter.method.period.coffee']
      expect(tokens[2]).toEqual value: 'b', scopes: ['source.coffee', 'meta.method-call.coffee', 'entity.name.function.coffee']
      expect(tokens[3]).toEqual value: ' ', scopes: ['source.coffee', 'meta.method-call.coffee']
      expect(tokens[4]).toEqual value: '1', scopes: ['source.coffee', 'meta.method-call.coffee', 'meta.arguments.coffee', 'constant.numeric.decimal.coffee']
      expect(tokens[5]).toEqual value: '+', scopes: ['source.coffee', 'meta.method-call.coffee', 'meta.arguments.coffee', 'keyword.operator.coffee']
      expect(tokens[6]).toEqual value: '1', scopes: ['source.coffee', 'meta.method-call.coffee', 'meta.arguments.coffee', 'constant.numeric.decimal.coffee']

      {tokens} = grammar.tokenizeLine('a.b @')
      expect(tokens[2]).toEqual value: 'b', scopes: ['source.coffee', 'meta.method-call.coffee', 'entity.name.function.coffee']
      expect(tokens[4]).toEqual value: '@', scopes: ['source.coffee', 'meta.method-call.coffee', 'meta.arguments.coffee', 'variable.other.readwrite.instance.coffee']

      {tokens} = grammar.tokenizeLine('a.$abc$ "q"')
      expect(tokens[2]).toEqual value: '$abc$', scopes: ['source.coffee', 'meta.method-call.coffee', 'entity.name.function.coffee']

      {tokens} = grammar.tokenizeLine('a.$$ 4')
      expect(tokens[2]).toEqual value: '$$', scopes: ['source.coffee', 'meta.method-call.coffee', 'entity.name.function.coffee']

      {tokens} = grammar.tokenizeLine('a.b @$')
      expect(tokens[0]).toEqual value: 'a', scopes: ['source.coffee', 'variable.other.object.coffee']
      expect(tokens[1]).toEqual value: '.', scopes: ['source.coffee', 'meta.method-call.coffee', 'meta.delimiter.method.period.coffee']
      expect(tokens[2]).toEqual value: 'b', scopes: ['source.coffee', 'meta.method-call.coffee', 'entity.name.function.coffee']
      expect(tokens[3]).toEqual value: ' ', scopes: ['source.coffee', 'meta.method-call.coffee']
      expect(tokens[4]).toEqual value: '@$', scopes: ['source.coffee', 'meta.method-call.coffee', 'meta.arguments.coffee', 'variable.other.readwrite.instance.coffee']

  it "tokenizes destructuring assignments", ->
    {tokens} = grammar.tokenizeLine("{something} = hi")
    expect(tokens[0]).toEqual value: "{", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.begin.bracket.curly.coffee"]
    expect(tokens[1]).toEqual value: "something", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "variable.assignment.coffee", "variable.assignment.coffee"]
    expect(tokens[2]).toEqual value: "}", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.end.bracket.curly.coffee"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.coffee"]
    expect(tokens[4]).toEqual value: "=", scopes: ["source.coffee", "keyword.operator.assignment.coffee"]
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
    expect(tokens[20]).toEqual value: "=", scopes: ["source.coffee", "keyword.operator.assignment.coffee"]

  it "tokenizes multiple nested destructuring assignments", ->
    {tokens} = grammar.tokenizeLine("{start: {row: startRow}, end: {row: endRow}} = range")
    expect(tokens[0]).toEqual value: "{", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.begin.bracket.curly.coffee"]
    expect(tokens[4]).toEqual value: "{", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.begin.bracket.curly.coffee"]
    expect(tokens[9]).toEqual value: "}", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.end.bracket.curly.coffee"]
    expect(tokens[15]).toEqual value: "{", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.begin.bracket.curly.coffee"]
    expect(tokens[20]).toEqual value: "}", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.end.bracket.curly.coffee"]
    expect(tokens[21]).toEqual value: "}", scopes: ["source.coffee", "meta.variable.assignment.destructured.object.coffee", "punctuation.definition.destructuring.end.bracket.curly.coffee"]
    expect(tokens[22]).toEqual value: " ", scopes: ["source.coffee"]
    expect(tokens[23]).toEqual value: "=", scopes: ["source.coffee", "keyword.operator.assignment.coffee"]

  it "doesn't tokenize nested brackets as destructuring assignments", ->
    {tokens} = grammar.tokenizeLine("[Point(0, 1), [Point(0, 0), Point(0, 1)]]")
    expect(tokens[0]).not.toEqual value: "[", scopes: ["source.coffee", "meta.variable.assignment.destructured.array.coffee", "punctuation.definition.destructuring.begin.bracket.square.coffee"]
    expect(tokens[0]).toEqual value: "[", scopes: ["source.coffee", "meta.brace.square.coffee"]

  it "tokenizes inline constant followed by unless statement correctly", ->
    {tokens} = grammar.tokenizeLine("return 0 unless true")
    expect(tokens[0]).toEqual value: "return", scopes: ["source.coffee", "keyword.control.coffee"]
    expect(tokens[2]).toEqual value: "0", scopes: ["source.coffee", "constant.numeric.decimal.coffee"]
    expect(tokens[4]).toEqual value: "unless", scopes: ["source.coffee", "keyword.control.coffee"]
    expect(tokens[6]).toEqual value: "true", scopes: ["source.coffee", "constant.language.boolean.true.coffee"]

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
