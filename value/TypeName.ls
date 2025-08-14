
  do ->

    { function-name } = dependency 'value.Function'
    { is-function, is-infinity, is-nan, value-typetag } = dependency 'value.Type'

    object-constructor-name = (value) ->

      { constructor } = value

      return null unless is-function constructor

      constructor |> function-name

    #

    value-type-name = (value) ->

      typetag = value-typetag value

      switch typetag

        | 'Object' =>

          switch value

            | void => 'Undefined'
            | null => 'Null'

          else

            constructor-name = object-constructor-name value

            if constructor-name? then constructor-name else type-tag

        | 'Error' => value.name

        | 'Number' =>

          match value

            | is-infinity => 'Infinity'
            | is-nan => 'NaN'

            else typetag

        else typetag

    #

    is-a = (value, descriptor) ->

      return yes if (value-type-name value) is descriptor
      return yes if (value-typetag  value) is descriptor

      no

    {
      value-type-name, is-a
    }