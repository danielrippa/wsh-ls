
  do ->

    { value-typetag } = dependency 'value.TypeTag'
    { circumfix, angle-brackets, curly-brackets, square-brackets, round-brackets, single-quotes } = dependency 'value.string.Brackets'
    { kebab-case } = dependency 'value.string.Case'
    { map-array-items: map, array-size } = dependency 'value.Array'
    { object-member-pairs } = dependency 'value.Object'
    { function-parameter-names } = dependency 'value.Function'

    pad-with-space = -> circumfix it, [ ' ' ]

    type-as-string = -> angle-brackets it

    members-as-string = -> curly-brackets pad-with-space it * ', '

    items-as-string = -> square-brackets it * ', '

    array-as-display-string = (array) -> map array, value-as-display-string |> items-as-string

    pair-as-display-member-string = ([ key, value ]) -> "#{ kebab-case key }: #{ value-as-display-string value }"

    object-as-display-string = (object) -> 
      object |> object-member-pairs |> map _ , pair-as-display-member-string |> members-as-string

    parameters-as-string = (fn) -> 
      function-parameter-names fn => return if (array-size ..) > 1 then (round-brackets .. * ', ') else ''

    function-as-display-string = (fn) -> "#{ parameters-as-string fn }->"

    any-value-as-display-string = -> "#it"

    value-as-display-string = (value) ->

      switch value-typetag value

        | 'Undefined' => 'void'
        | 'Null' => 'null'

        | 'String' => single-quotes value
        | 'Array' => array-as-display-string value
        | 'Object' => object-as-display-string value
        | 'Function' => function-as-display-string value

        else any-value-as-display-string value

    typed-array-as-display-string = (array) ->
      [ (typed-value-as-display-string item) for item in array ] |> items-as-string

    pair-as-typed-display-member-string = ([ key, value ]) -> 
      "#{ kebab-case key }: #{ typed-value-as-display-string value }"

    typed-object-as-display-string = (object) ->
      object |> object-member-pairs |> map _ , pair-as-typed-display-member-string |> members-as-string

    typed-value-as-display-string = (value) ->
      type-name = value-typetag value
      value-string = switch type-name
        | 'Array' => typed-array-as-display-string value
        | 'Object' => typed-object-as-display-string value
        else value-as-display-string value
      type-string = type-as-string type-name

      "#type-string #value-string"

    {
      value-as-display-string,
      typed-value-as-display-string
    }