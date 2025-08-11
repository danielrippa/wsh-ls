
  do ->

    value-typetag = (value) -> {} |> (.to-string) |> (.call value) |> (.slice 8, -1)

    value-has-typetag = (value, typetag) -> (value-typetag value) is typetag

    {
      value-typetag, value-has-typetag
    }