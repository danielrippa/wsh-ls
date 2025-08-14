
  do ->

    { type-descriptor, invalid-type-descriptor-syntax-error } = dependency 'value.reflection.TypeDescriptor'
    { create-argument-error: arg-error } = dependency 'value.ArgumentError'
    { is-a } = dependency 'value.TypeName'
    { is-empty-string } = dependency 'value.string.Whitespace'
    { is-array, is-object, is-function } = dependency 'value.Type'
    { value-as-string, typed-value-as-string } = dependency 'value.Value'
    { find-array-item, drop-array-items } = dependency 'value.Array'
    { string-contains } = dependency 'value.String'
    { object-member-names } = dependency 'value.Object'
    { camel-case } = dependency 'value.string.Case'
    { function-parameter-names } = dependency 'value.Function'

    ellipsis = '...'

    token-as-types = (/ '|')

    any-of = (tokens) ->

      prefix = if tokens.length is 1 then '' else 'any of '

      "#prefix#{ tokens * ', ' }"

    tuple-element-type-mismatch-error = (tuple, tokens, descriptor, element-index, type-index) ->

      token = tokens[ type-index ] ; types = token-as-types token ; element = tuple[ element-index ]

      throw arg-error {element}, "Tuple element #{ typed-value-as-string element } at index #element-index must be #{ any-of types } as per Tuple type descriptor '#descriptor'."

    array-item-type-mismatch-error = (array, types, descriptor, index) ->

      item = array[index]

      throw arg-error {item}, "List item #{ typed-value-as-string item } at index #index must be #{ any-of types } as per List type descriptor '#descriptor'."

    value-with-type = (value, [ descriptor, tokens ]) ->

      unless tokens.length is 1
        throw arg-error {tokens}, "Union types syntax expects exactly one token."

      [ token ] = tokens

      return value if token is '?'

      union-types = token-as-types token

      return value if (find-array-item union-types, -> value `is-a` it)

      throw arg-error {value}, "Value must be #{ any-of union-types }."

    #

    array-with-type = (array, [ descriptor, token ]) ->

      types = token-as-types token

      for item, index in array

        item-is-valid-type = yes

        for type in types

          unless item `is-a` type

            item-is-valid-type = no
            break

        throw array-item-type-mismatch-error array, types, descriptor, index \
          unless item-is-valid-type

      array

    value-is-a = (value, token) ->

      types = token-as-types token

      for type in types => return yes if value `is-a` type

      no

    missing-mandatory-types-error = (tuple, descriptor, missing-mandatory-types) ->

      message = if missing-mandatory-types.length is 0
        ''
      else
        missing-mandatory-types * ', ' |> -> " #it"

      throw arg-error {tuple}, "Tuple is missing mandatory elements#message as per type descriptor '#descriptor'."

    handle-tuple-is-done = (tuple, types, descriptor, type-index) ->

      type = types[ type-index ]

      prev-ellipsis = type is ellipsis

      unless (type is '?') or prev-ellipsis

        throw tuple-too-short-error tuple, types, descriptor, type-index

      { type-index: (type-index + 1), prev-ellipsis }

    tuple-too-short-error = (tuple, types, descriptor, type-index) ->

      types-count = types.length

      missing-mandatory-types = []

      loop

        break unless type-index < types-count

        type = types[ type-index ]

        break if (type is '?') or (type is ellipsis)

        missing-mandatory-types.push type

        type-index++

      throw missing-mandatory-types-error tuple, descriptor, missing-mandatory-types

    unexpected-trailing-elements-error = (tuple, descriptor, element-index, was-prev-ellipsis) ->

      unexpected-elements =

        tuple

          |> (.slice element-index)
          |> map _ typed-value-as-string
          |> (* ', ')

      suffix = if was-prev-ellipsis then "after its variadic '#ellipsis' part" else ''

      new Error "Tuple has trailing elements #unexpected-elements not defined by type descriptor '#descriptor'."

    consume-elements-for-ellipsis = (tuple, types, element-index, type-index) ->

      elements-count = tuple.length
      types-count    = types.length

      loop

        break if element-index is elements-count

        has-type-after-ellipsis = type-index < types-count

        if has-type-after-ellipsis

          if tuple[ element-index ] `is-a` types[ type-index ]

            break

        element-index++

      element-index

    tuple-with-types = (tuple, [ descriptor, types ]) ->

      strict = ellipsis not in types

      elements-count = tuple.length
      types-count = types.length

      if strict

        if elements-count isnt types-count

          throw arg-error {tuple}, "Tuple has #elements-count elements. It must have #types-count elements as per tuple type descriptor '#descriptor'."

      else

        non-ellipsis-count = drop-array-items types, (== ellipsis) .length

        if elements-count < non-ellipsis-count

          throw arg-error {tuple}, "Tuple has #elements-count elements. It must have at least #types-count elements as per tuple type descriptor '#descriptor'."

      element-index = type-index = 0

      increment-indexes = -> element-index++ ; type-index++

      current-element = -> tuple[ element-index ]
      current-type = -> types[ type-index ]

      prev-ellipsis = no

      loop

        tuple-is-done = element-index is elements-count
        types-is-done = type-index is types-count

        break if tuple-is-done and types-is-done

        if tuple-is-done

          { type-index, prev-ellipsis } = handle-tuple-is-done tuple, types, descriptor, type-index

          continue

        ellipsis-context = prev-ellipsis
        prev-ellipsis = no

        if types-is-done

          throw unexpected-trailing-elements-error tuple, descriptor, element-index, ellipsis-context

        type = current-type!

        if type is '?'

          increment-indexes!

          continue

        unless strict

          if type is ellipsis

            type-index++

            element-index = consume-elements-for-ellipsis tuple, types, element-index, type-index

            prev-ellipsis = yes

            continue

        unless current-element! `value-is-a` type

          throw tuple-element-type-mismatch-error tuple, types, descriptor, element-index, type-index

        increment-indexes!

      tuple

    array-with-types = (array, [ descriptor, tokens ]) ->

      unless is-array array
        throw arg-error {array}, "Value must be an Array as per type descriptor '#descriptor'."

      return value if array.length is 0

      switch tokens.length

        | 1 =>

          [ token ] = tokens

          if token is ellipsis => tuple-with-types array, [ descriptor, tokens ]

          if token `string-contains` ':'

            [ star, types ] = token / ':'

            if star is '*'

              return array-with-type array, [ descriptor, types ]

          else

            return tuple-with-types array, [ descriptor, tokens ]

          throw arg-error {descriptor}, "Invalid array type descriptor '#descriptor'. List type descriptor syntax is '*:UnionType'."

      tuple-with-types array, [ descriptor, tokens ]

    object-with-members = (object, [ descriptor, tokens ]) ->

      unless is-object object
        throw arg-error {object}, "Value must be Object as per type descriptor '#descriptor'."

      member-names = object-member-names object
      members-count = member-names.length

      strict = ellipsis not in tokens

      tokens = drop-array-items tokens, (== ellipsis) ; tokens-count = tokens.length

      if strict

        if members-count isnt tokens-count

          throw arg-error {object}, "Object has #members-count members but it must have #tokens-count as per type descriptor '#descriptor'."

      else

        if members-count < tokens-count

          throw arg-error {object}, "Object has #members-count but it must have at least #tokens-count as per type descriptor '#descriptor'."

      for token in tokens

        if token `string-contains` ':'

          [ member-name-token, type-token ] = token / ':'

          member-name = camel-case member-name-token

          unless member-name in member-names

            throw arg-error {object}, "Object is missing member '#member-name' as per type descriptor '#descriptor'."

          continue if type-token is '?'

          types = token-as-types type-token

          member-matches-type = no

          for type in types

            if object[ member-name ] `is-a` type

              member-matches-type = yes
              break

          unless member-matches-type

            member-value = object[ member-name ]

            throw arg-error {object}, "Member '#member-name' with value #{ typed-value-as-string member-value } fails to match the required type '#type' as per type descriptor '#descriptor'."

        else

          member-name = camel-case token

          unless member-name in member-names

            throw arg-error {object}, "Object is missing member '#member-name' as per type descriptor '#descriptor'."

      object

    function-with-parameters = (fn, [ descriptor, tokens ]) ->

      unless is-function fn

        throw arg-error {fn}, "Value must be Function as per type descriptor '#descriptor'."

      parameter-names = function-parameter-names fn ; parameters-count = parameter-names.length
      tokens-count = tokens.length

      strict = ellipsis not in tokens

      token-index = parameter-index = 0

      loop

        parameters-done = parameter-index is parameters-count
        tokens-done = token-index is tokens-count

        break if parameters-done and tokens-done

        if parameters-done

          # Check remaining tokens - they should only be optional or ellipsis
          while token-index < tokens-count
            remaining-token = tokens[token-index]
            unless (remaining-token is '?') or (remaining-token is ellipsis)
              throw arg-error {fn}, "Function has fewer parameters than required by type descriptor '#descriptor'."
            token-index++
          break

        if tokens-done

          throw arg-error {fn}, "Function has more parameters than specified in type descriptor '#descriptor'."

        parameter-token = tokens[token-index]
        
        # Handle ellipsis - it matches remaining parameters
        if parameter-token is ellipsis
          token-index++
          # Ellipsis consumes all remaining parameters
          parameter-index = parameters-count
          continue

        # Handle optional parameter marker
        if parameter-token is '?'
          # Optional marker - skip this parameter if it exists
          if parameter-index < parameters-count
            parameter-index++
          token-index++
          continue

        # We need a parameter to match against
        if parameter-index >= parameters-count
          throw arg-error {fn}, "Function does not match type descriptor '#descriptor'."

        parameter-name = parameter-names[parameter-index]

        if parameter-token `string-contains` ':'

          [ parameter-name-token, parameter-type ] = parameter-token / ':'

          if (camel-case parameter-name-token) isnt parameter-name
            throw arg-error {fn}, "Function parameter name '#{parameter-name}' at index #parameter-index does not match expected '#parameter-name-token' as per type descriptor '#descriptor'."

        else

          if (camel-case parameter-token) isnt parameter-name
            throw arg-error {fn}, "Function parameter name '#parameter-name' does not match expected parameter name '#parameter-token' as per type descriptor '#descriptor'."

        token-index++
        parameter-index++

      fn

    type = (descriptor, value) ->

      { type-tokens, descriptor-kind } = type-descriptor descriptor

      value-with-type-tokens = switch descriptor-kind

        | 'type' => value-with-type
        | 'array' => array-with-types
        | 'object' => object-with-members
        | 'function' => function-with-parameters

      value `value-with-type-tokens` [ descriptor, type-tokens ]

    {
      type
    }