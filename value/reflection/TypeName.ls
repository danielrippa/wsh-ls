
  do ->

    { value-is-infinity, value-is-nan, value-is-function } = dependency 'value.Type'
    { function-name } = dependency 'value.Function'
    { value-typetag: value-type } = dependency 'value.TypeTag'

    value-type-tag = (value) ->

      type-tag = value-type value

      switch type-tag

        | 'Object' =>

          switch value

            | void => 'Undefined'
            | null => 'Null'

            else type-tag

        | 'Number' =>

          match value

            | value-is-infinity => 'Infinity'
            | value-is-nan => 'NaN'

            else type-tag

        else type-tag

    #

    object-constructor-name = (value) ->

      { constructor } = value

      return null unless value-is-function constructor

      constructor |> function-name

    #

    value-type-name = (value) ->

      type-tag = value-type-tag value

      switch type-tag

        | 'Object' =>

          constructor-name = object-constructor-name value

          if constructor-name? then constructor-name else type-tag

        | 'Error' => value.name

        else type-tag

    #

    is-a = (value, descriptor) ->

      return yes if (value-type-name value) is descriptor
      return yes if (value-type-tag  value) is descriptor

      no

    {
      value-type-tag, value-type-name,
      is-a
    }