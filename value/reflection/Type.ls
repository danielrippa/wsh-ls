
  do ->

    { type-descriptor } = dependency 'value.reflection.TypeDescriptor'
    { array-size } = dependency 'value.Array'
    { value-is-array } = dependency 'value.Type'

    ellipsis = '...'

    any-of = (tokens) ->

      prefix = match array-size tokens

        | 1 => 'a'

        else 'any of'

      "#prefix #{ tokens * ', ' }"

    value-with-type = (value, [ descriptor, tokens ]) ->

      return value if '?' in tokens
      return value if (find-item tokens, -> value `is-a` it)?

      throw type-error "Value #{ typed-value-as-string value } must be #{ any-of tokens }"

    #

    is-empty-string = -> (trimmed-string it) is ''

    token-as-types = (/ '|')

    tokens-as-item-types = (tokens) ->

      return null unless (array-size tokens) is 1

      [ token ] = tokens

      unless token `string-contains` ':'
        throw type-error "List type descriptor must contain ':'"

      [ star, types ] = token / ':'

      unless star is '*'
        throw type-error "List type descriptor must start with '*'"

      token-as-types types

    #

    list-with-type = (list, [ descriptor, types ]) ->

      for item, item-index in list

        item-has-valid-type = no

        for type in types

          if item `is-a` type

            item-has-valid-type = yes
            break

        unless item-has-valid-type
          throw new type-error "Item #{ typed-value-as-string item } at index #item-index of array #{ typed-value-as-string list } is of an invalid type as per type descriptor #{ value-as-string descriptor }"

      list

    #

    element-count-mismatch-error = (tuple, descriptor, elements-count, expected-count, strict) ->

      tuple-has-elements = "Tuple #{ value-as-string tuple } has #elements-count elements"

      descriptor-requires = "#{ if strict then 'strict ' else '' }descriptor #{ value-as-string descriptor } requires#{ if strict then '' else ' at least' }"

      type-error "#tuple-has-elements, but #descriptor-requires #expected-count elements"

    #

    tuple-types-and-strict = (tuple, types, descriptor) ->

      elements-count = array-size tuple
      types-count = array-size types

      strict = ellipsis not in types

      if strict

        if elements-count isnt types-count

          throw element-count-mismatch-error tuple, descriptor, elements-count, types-count, strict

      else

        non-ellipsis-count = drop-array-items types, (== ellipsis) |> array-size

        if elements-count < non-ellipsis-count

          throw element-count-mismatch-error tuple, descriptor, elements-count, non-ellipsis-count, strict

      { elements-count, types-count, strict }

    #

    missing-mandatory-types-error = (tuple, descriptor, missing-mandatory-types) ->

      message = switch array-size missing-mandatory-types

        | 0 => ''

        else missing-mandatory-types * ', ' |> -> " #it"

      type-error "Tuple #{ value-as-string tuple } is missing mandatory elements#message as per descriptor #{ value-as-string descriptor }"

    #

    tuple-too-short-error = (tuple, types, descriptor, type-index) ->

      types-count = array-size types

      missing-mandatory-types = []

      loop

        break unless type-index < types-count

        type = types[ type-index ]

        break if (type is '?') or (type is ellipsis)

        missing-mandatory-types.push type

        type-index++

      missing-mandatory-types-error tuple, descriptor, missing-mandatory-types

    #

    unexpected-trailing-elements-error = (tuple, descriptor, element-index, was-prev-ellipsis) ->

      unexpected-elements =

        tuple

          |> (.slice element-index)
          |> map _ , typed-value-as-string
          |> (* ', ')

      suffix = if was-prev-ellipsis then "after its variadic '...' part" else ''

      type-error "Tuple #{ value-as-string tuple } has trailing elements #unexpected-elements not defined by descriptor #{ value-as-string descriptor }"

    #

    consume-elements-for-ellipsis = (tuple, types, element-index, type-index) ->

      elements-count = array-size tuple
      types-count    = array-size types

      loop

        break if element-index is elements-count

        has-type-after-ellipsis = type-index < types-count

        if has-type-after-ellipsis

          if tuple[ element-index ] `is-a` types[ type-index ]

            break

        element-index++

      element-index

    #

    element-type-mismatch-error = (tuple, types, descriptor, element-index, type-index) ->

      element = "#{ typed-value-as-string tuple[ element-index ] } at index #element-index in #{ typed-value-as-string tuple }"

      type = "#{ types[ type-index ] } from descriptor #{ value-as-string descriptor } at index #type-index"

      type-error "Element #element does not match type #type"

    #

    handle-tuple-is-done = (tuple, types, descriptor, type-index) ->

      type = types[ type-index ]

      unless (type is '?') or (type is ellipsis)

        throw tuple-too-short-error tuple, types, descriptor, type-index

      { type-index: (type-index + 1), prev-ellipsis: (type is ellipsis) }

    #

    tuple-with-types = (tuple, [ descriptor, types ]) ->

      { elements-count, types-count, strict } = tuple-types-and-strict tuple, types, descriptor

      element-index = type-index = 0

      increment-indexes = -> element-index++ ; type-index++

      current-element = -> tuple[ element-index ]
      current-type    = -> types[ type-index ]

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

        unless current-element! `is-a` type

          throw element-type-mismatch-error tuple, types, descriptor, element-index, type-index

        increment-indexes!

      tuple

    #

    array-with-type = (array, [ descriptor, tokens ]) ->

      unless value-is-array array
        throw type-error "Value #{ typed-value-as-string array } was expected to be an array as per descriptor #{ value-as-string descriptor }"

      item-types = tokens-as-item-types tokens

      if item-types?

        list-with-type array, [ descriptor, item-types ]

      else

        tuple-with-types array, [ descriptor, tokens ]

    #

    object-with-members = (object, [ descriptor, tokens ]) ->

      unless is-object object
        throw type-error "Value #{ typed-value-as-string object } was expected to be an object as per descriptor #{ value-as-string descriptor }"

      member-names = object-member-names object
      members-count = array-size member-names

      strict = ellipsis not in tokens

      tokens = drop-array-items tokens, (== ellipsis)

      tokens-count = array-size tokens

      if strict

        if members-count isnt tokens-count
          throw type-error "Object #{ value-as-string object } has #members-count members but it must have #tokens-count as per descriptor #{ value-as-string descriptor }"

      else

        if members-count < tokens-count
          throw type-error "Object #{ value-as-string object } has #members-count members but it must have at least #tokens-count as per descriptor #{ value-as-string descriptor }"

      for token in tokens

        if token `string-contains` ':'

          [ required-member-name, required-type-token ] = token / ':'

          unless (camel-case required-member-name) in member-names

            throw type-error "Object #{ value-as-string object } is missing required member '#{ required-member-name }' as per descriptor #{ value-as-string descriptor }"

          continue if required-type-token is '?'

          required-types = required-type-token / '|'

          member-matches-required-type = no

          for required-type in required-types

            if object[ camel-case required-member-name ] `is-a` required-type

              member-matches-required-type = yes

              break

          unless member-matches-required-type

            throw type-error "Member '#required-member-name' of object #{ value-as-string object } fails to match the required type #required-type as per descriptor #{ value-as-string descriptor }"

        else

          unless (camel-case token) in member-names
            throw type-error "Object #{ value-as-string object } is missing member '#token' as per descriptor #{ value-as-string descriptor }"

      object

    #

    function-with-parameters = (value, [ descriptor, tokens ]) ->

      unless is-function value
        throw type-error ""

      parameter-names = function-parameter-names value

      parameters-count = array-size parameter-names
      tokens-count     = array-size tokens

      strict = ellipsis not in tokens

      token-index = parameter-index = 0

      loop

        break if (parameter-index is parameters-count) and (token-index is tokens-count)

        if (parameter-index > parameters-count) or (token-index > tokens-count)

          throw type-error ""

        token = tokens[ token-index ] ; parameter-name = parameter-names[ parameter-index ]

        if token is '?'

          parameter-index++ ; token-index++
          continue

        unless strict

          if token is ellipsis

            token-index++

            loop

              break if parameter-index is parameters-count

              if token-index < tokens-count
                if parameter-names[ parameter-index ] is tokens[ token-index ]

                  break

              parameter-index++

              if parameter-index < parameters-count
                if token-index < tokens-count

                  token = tokens[ token-index ] ; parameter-name = parameter-names[ parameter-index ]

              continue

        if parameter-name isnt token
          throw type-error ""

        parameter-index++ ; token-index++

      if strict

        if parameter-index isnt parameters-count
          throw type-error ""

      value

    #



    type = (descriptor, value) ->

      { type-tokens, descriptor-kind } = type-descriptor descriptor

      value-with-type-tokens = switch descriptor-kind

        | 'type' => value-with-type
        | 'array' => array-with-type
        | 'object' => object-with-members
        | 'function' => function-with-parameters

      value `value-with-type-tokens` { descriptor, type-tokens }

    {
      type
    }