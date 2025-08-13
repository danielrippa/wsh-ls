
  do ->

    string-size = (.length)

    maybe-null = -> if it is -1 then null else it

    first-index-of = (haystack, needle, from-index = 0)               -> haystack.index-of      needle, from-index |> maybe-null
    last-index-of  = (haystack, needle, from-index = haystack.length) -> haystack.last-index-of needle, from-index |> maybe-null

    string-contains = (haystack, needle) -> (haystack `first-index-of` needle)?

    {
      string-size,
      first-index-of, last-index-of,
      string-contains
    }