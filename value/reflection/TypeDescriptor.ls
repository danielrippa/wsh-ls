
  do ->

    { create-argument-type-error: argtype-error, create-argument-requirement-error: arg-error } = dependency 'value.error.ArgumentError'
    { string-as-words } = dependency 'value.string.Whitespace'
    { value-is-string } = dependency 'value.Type'
    { first-middle-and-last-array-items: first-middle-last } = dependency 'value.Array'

    type-descriptor = (descriptor) ->

      throw argtype-error {descriptor}, 'String' \
        unless value-is-string descriptor

      { first, middle: chars, last } = first-middle-last descriptor / '' # TODO check

      descriptor-kind = match first, last

        | '<', '>' => 'type'
        | '{', '}' => 'object'
        | '[', ']' => 'array'
        | '(', ')' => 'function'

        else throw arg-error {descriptor}, "coso"

        type-tokens = chars * '' |> string-as-words

      { type-tokens, descriptor-kind }

    {
      type-descriptor
    }