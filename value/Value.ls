
  do ->

    { value-typetag } = dependency 'value.Type'
    { circumfix, angle-brackets, curly-brackets, square-brackets, round-brackets, single-quotes } = dependency 'value.string.Brackets'
    { kebab-case } = dependency 'value.string.Case'
    { map-array-items: map, array-size } = dependency 'value.Array'
    { object-member-pairs } = dependency 'value.Object'
    { function-parameter-names } = dependency 'value.Function'
    { value-type-name } = dependency 'value.TypeName'

    pad-with-space = -> circumfix it, [ ' ' ]

    type-as-string = -> angle-brackets it

    members-as-string = -> curly-brackets pad-with-space it * ', '

    items-as-string = -> square-brackets it * ', '

    array-as-string = (array) -> map array, value-as-string |> items-as-string

    pair-as-member-string = ([ key, value ]) -> "#{ kebab-case key }: #{ value-as-string value }"

    object-as-string = (object) ->

      WScript.Echo object-member-pairs

      object |> object-member-pairs |> map _ , pair-as-member-string |> members-as-string

    parameters-as-string = (fn) ->
      function-parameter-names fn => return if (array-size ..) > 1 then (round-brackets .. * ', ') else ''

    function-as-string = (fn) -> "#{ parameters-as-string fn }->"

    any-value-as-string = -> "#it"

    value-as-string = (value) ->

      switch value-typetag value

        | 'Undefined' => 'void'
        | 'Null' => 'null'

        | 'String' => single-quotes value
        | 'Array' => array-as-string value
        | 'Object', 'Error', 'RegExp' => object-as-string value
        | 'Function' => function-as-string value

        else any-value-as-string value

    typed-array-as-string = (array) ->
      [ (typed-value-as-string item) for item in array ] |> items-as-string

    pair-as-typed-member-string = ([ key, value ]) ->
      "#{ kebab-case key }: #{ typed-value-as-string value }"

    typed-object-as-string = (object) ->
      object |> object-member-pairs |> map _ , pair-as-typed-member-string |> members-as-string

    typed-value-as-string = (value) ->

      typetag = value-typetag value

      value-string = switch typetag
        | 'Array' => typed-array-as-string value
        | 'Object', 'Error', 'RegExp' => typed-object-as-string value
        else value-as-string value

      type-string = type-as-string value-type-name value

      "#type-string #value-string"

    {
      value-as-string,
      typed-value-as-string
    }