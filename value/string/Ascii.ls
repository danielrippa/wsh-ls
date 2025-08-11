
  do ->

    { codeunit-as-string: char } = dependency 'value.string.CodeUnit'

    c0-control-codes = { [ name, char-code ] for name, char-code in <[ nul soh stx etx eot enq ack bel bs ht lf vt ff cr so si dle dc1 dc2 dc3 dc4 nak syn etb can em sub esc fs gs rs us sp ]> }

    c1-control-codes = { [ name, char-code + 127 ] for name, char-code in <[ del pad hop bph nbh ind nel ssa esa hts htj vts pld plu ri ss2 ss3 dcs pu1 pu2 sts cch mw spa epa sos sgc sci csi st osc pm apc ]> }

    control-codes = {} <<< c0-control-codes <<< c1-control-codes

    control-chars = { [ (name), (char char-code) ] for name, char-code of control-codes }

    basic-punctuation = { [ name, char-code + 33 ] for name, char-code in <[ exclamation quotation hash dollar percent ampersand apostrophe left-paren right-paren asterisk plus comma hyphen period slash ]> }

    extended-punctuation = { [ name, char-code + 58 ] for name, char-code in <[ colon semicolon less-than equals greater-than question at ]> }

    bracket-punctuation = { [ name, char-code + 91 ] for name, char-code in <[ left-bracket backslash right-bracket caret underscore backtick ]> }

    brace-punctuation = { [ name, char-code + 123 ] for name, char-code in <[ left-brace pipe right-brace tilde ]> }

    punctuation-codes = {} <<< basic-punctuation <<< extended-punctuation <<< bracket-punctuation <<< brace-punctuation

    punctuation-chars = { [ (name), (char char-code) ] for name, char-code of punctuation-codes }

    {
      control-chars
      punctuation-chars
    }