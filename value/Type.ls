
  do ->

    value-typetag = (value) -> {} |> (.to-string) |> (.call value) |> (.slice 8, -1)

    has-typetag = (value, typetag) -> (value-typetag value) is typetag

    is-null = -> it is null
    is-void = -> it is void

    is-empty-value = (value) ->

      match value

        | is-null => yes
        | is-void => yes

        else no

    has-type = (value, type) -> (typeof value) is type

    is-object = (value) ->

      return no unless value `has-type` 'object'

      not is-empty-value value

    { POSITIVE_INFINITY: posinf, NEGATIVE_INFINITY: neginf } = Number

    is-infinity = (value) ->

      switch value

        | posinf, neginf => yes

        else no

    is-nan = (!= it)

    is-number = (value) -> (value `has-type` 'number') and not (is-nan value)

    is-string = _ `has-type` 'string'

    is-boolean = _ `has-type` 'boolean'

    is-function = _ `has-type` 'function'

    is-error = _ `has-typetag`  'Error'

    is-array = _ `has-typetag` 'Array'

    is-date = _ `has-typetag` 'Date'

    is-regexp = _ `has-typetag` 'RegExp'

    {
      value-typetag, has-typetag,
      is-null, is-void, is-empty-value,
      is-string, is-boolean, is-function,
      is-number, is-nan, is-infinity,
      is-object, is-array,
      is-date, is-regexp,
    }