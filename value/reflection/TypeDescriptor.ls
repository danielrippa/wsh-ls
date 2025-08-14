
  do ->

    { create-argument-type-error: argtype-error, create-argument-requirement-error: arg-error } = dependency 'value.ArgumentError'
    { string-as-words } = dependency 'value.string.Whitespace'
    { is-string } = dependency 'value.Type'
    { first-middle-and-last-array-items: first-middle-last, drop-array-items } = dependency 'value.Array'

    invalid-type-descriptor-syntax-error = (descriptor) ->

    type-descriptor = (descriptor) ->

      throw argtype-error {descriptor}, 'String' \
        unless is-string descriptor

      { first, middle: chars, last } = first-middle-last descriptor / '' # TODO check

      descriptor-kind = match first, last

        | '<', '>' => 'type'
        | '{', '}' => 'object'
        | '[', ']' => 'array'
        | '(', ')' => 'function'

        else throw arg-error {descriptor}, "coso"

      type-tokens = chars * '' |> string-as-words |> drop-array-items _ , (== '')

      { type-tokens, descriptor-kind }

    {
      type-descriptor,
      invalid-type-descriptor-syntax-error
    }