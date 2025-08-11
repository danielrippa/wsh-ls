  do ->

    { fold-array-items: fold } = dependency 'value.Array'

    HIGH_SURROGATE_START = 0xD800
    HIGH_SURROGATE_END = 0xDBFF
    LOW_SURROGATE_START = 0xDC00
    LOW_SURROGATE_END = 0xDFFF

    needs-pair = (codeunit) -> codeunit >= HIGH_SURROGATE_START and codeunit <= HIGH_SURROGATE_END

    completes-pair = (codeunit) -> codeunit >= LOW_SURROGATE_START and codeunit <= LOW_SURROGATE_END

    string-as-codeunit-sequence = (string) ->
      codeunits = [ string.char-code-at i for i from 0 til string.length ]
      fold codeunits, { sequence: [], consumed: false }, (acc, codeunit, i) ->
        was-consumed = acc.consumed
        has-next = i + 1 < codeunits.length
        next-completes = has-next and completes-pair codeunits[i + 1]
        is-surrogate-pair = needs-pair codeunit and next-completes
        
        switch
        | was-consumed =>
          acc.consumed = false
          acc
        | is-surrogate-pair =>
          acc.sequence.push [ codeunit, codeunits[i + 1] ]
          acc.consumed = true
          acc
        | otherwise =>
          acc.sequence.push [ codeunit ]
          acc
      .sequence

    codeunit-element-as-char = (element) ->
      String.fromCharCode.apply null, element

    codeunit-sequence-as-string = (sequence) ->
      [ codeunit-element-as-char element for element in sequence ].join ''

    codeunit-sequence-element-at-position = (sequence, position) -> sequence[position]

    codeunit-sequence-logical-character-count = (sequence) -> sequence.length

    logical-character-as-codeunit-element = (character) ->
      [ character.char-code-at i for i from 0 til character.length ]

    codeunits-as-codeunit-sequence = (codeunits) ->
      fold codeunits, { sequence: [], consumed: false }, (acc, codeunit, i) ->
        was-consumed = acc.consumed
        has-next = i + 1 < codeunits.length
        next-completes = has-next and completes-pair codeunits[i + 1]
        is-surrogate-pair = needs-pair codeunit and next-completes
        
        switch
        | was-consumed =>
          acc.consumed = false
          acc
        | is-surrogate-pair =>
          acc.sequence.push [ codeunit, codeunits[i + 1] ]
          acc.consumed = true
          acc
        | otherwise =>
          acc.sequence.push [ codeunit ]
          acc
      .sequence

    string-as-logical-character-array = (string) ->
      sequence = string-as-codeunit-sequence string
      [ codeunit-element-as-char element for element in sequence ]

    string-logical-character-at-position = (string, position) ->
      sequence = string-as-codeunit-sequence string
      element = codeunit-sequence-element-at-position sequence, position
      if element isnt void then codeunit-element-as-char element else void

    string-logical-character-count = (string) ->
      sequence = string-as-codeunit-sequence string
      codeunit-sequence-logical-character-count sequence

    codeunits-as-string = (codeunits) ->
      sequence = codeunits-as-codeunit-sequence codeunits
      codeunit-sequence-as-string sequence

    codeunit-as-string = (codeunit) ->
      codeunits-as-string [ codeunit ]

    {
      string-as-codeunit-sequence
      codeunits-as-codeunit-sequence
      codeunit-element-as-char
      codeunit-sequence-as-string
      codeunit-sequence-element-at-position
      codeunit-sequence-logical-character-count
      logical-character-as-codeunit-element
      string-as-logical-character-array
      string-logical-character-at-position
      string-logical-character-count
      codeunits-as-string
      codeunit-as-string
    }