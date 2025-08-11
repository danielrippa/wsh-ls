
  do ->

    { value-is-array } = dependency 'value.Type'

    object-member-names = (object) -> [ (member-name) for member-name of object ]

    object-member-values = (object) -> [ (member-value) for member-name, member-value of object ]

    object-member-pairs = (object) -> [ [ name, value ] for name, value of object ]

    object-from-array = (array) -> { [ value, value ] for value in array }

    object-from-keys-and-values = (keys, values) -> { [ (key), (values[index]) ] for key, index in keys }

    object-from-member-pairs = (pairs) -> { [ pair.0, pair.1 ] for pair in pairs }

    id = -> it

    map-object = (object, key-fn = id, value-fn = id) -> { [ (key-fn key, value, object), (value-fn value, key, object) ] for key, value of object }

    each-object-member = (object, proc) ->

      for key, value of object => proc key, value, object
      object

    member-type-descriptors = (pairs) -> [ ("#key:#{ typeof! value }") for [ key, value ] in pairs ]

    object-member-type-descriptors = (object) -> object |> object-member-pairs |> member-type-descriptors

    clone-object = (object) -> { [ member-name, member-value ] for member-name, member-value of object }

    {
      map-object,
      object-from-array,
      object-member-names, object-member-pairs, object-member-values,
      each-object-member,
      object-from-keys-and-values, object-from-member-pairs,
      object-member-type-descriptors,
      clone-object
    }