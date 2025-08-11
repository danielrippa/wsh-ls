
  do ->

    { value-has-typetag } = dependency 'value.TypeTag'

    value-is-null = -> it is null
    value-is-void = -> it is void

    value-is-empty = (value) ->

      match value

        | value-is-null => yes
        | value-is-void => yes

        else no

    is-a = (value, type-name) -> (typeof value) is type-name

    value-is-object = (value) ->

      return no unless value `is-a` 'object'

      not value-is-empty value

    { POSITIVE_INFINITY: posinf, NEGATIVE_INFINITY: neginf } = Number

    value-is-infinity = (value) ->

      switch value

        | posinf, neginf => yes

        else no

    value-is-nan = (!= it)

    value-is-number = (value) -> (value `is-a` 'number') and not (value-is-nan value)

    value-is-string = _ `is-a` 'string'

    value-is-boolean = _ `is-a` 'boolean'

    value-is-function = _ `is-a` 'function'

    value-is-array = _ `value-has-typetag` 'Array'

    value-is-date = _ `value-has-typetag` 'Date'

    value-is-regexp = _ `value-has-typetag` 'RegExp'

    {
      value-is-null, value-is-void, value-is-empty,
      value-is-string, value-is-boolean, value-is-function,
      value-is-number, value-is-nan, value-is-infinity,
      value-is-object, value-is-array,
      value-is-date, value-is-regexp
    }