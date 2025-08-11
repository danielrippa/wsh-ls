
  do ->

    { create-regexp } = dependency 'value.string.RegExp'

    maybe-null = -> if it is -1 then null else it

    first-index-of = (haystack, needle, from-index = 0)               -> haystack.index-of      needle, from-index |> maybe-null
    last-index-of  = (haystack, needle, from-index = haystack.length) -> haystack.last-index-of needle, from-index |> maybe-null

    string-contains = (haystack, needle) -> (haystack `first-index-of` needle)?

    string-segment = (string, [ first-index = 0, size = string.length - first-index ]) -> string.slice first-index, first-index + size

    string-interval = (string, [ first-index = 0, last-index = string.length ]) -> string.slice first-index, last-index

    string-split-at-index = (string, index) ->

      * string `string-interval` [ 0, index ]
        string `string-segment`  [ index ]

    string-segment-prefix-and-suffix = (string, [ start-index, end-index ]) ->

      return [ string, '' ] unless start-index?

      prefix = string `string-interval` [ 0, start-index ]
      suffix = string `string-segment`  [ end-index ]

      [ prefix, suffix ]

    string-split-by-segment = (haystack, needle, use-last = no) ->

      index-of = if use-last then last-index-of else first-index-of

      start-index = haystack `index-of` needle

      end-index = start-index + (string-size needle)

      haystack `string-segment-prefix-and-suffix` [ start-index, end-index ]

    string-split-by-first-segment = (haystack, needle) -> string-split-by-segment haystack, needle, no
    string-split-by-last-segment  = (haystack, needle) -> string-split-by-segment haystack, needle, yes

    string-between = (string, [ prefix, suffix ], use-last-for-suffix = no) ->

      index-of = if use-last-for-suffix then last-index-of else first-index-of

      prefix-index = string `first-index-of` prefix => return '' unless ..?
      suffix-index = string `index-of`       suffix => return '' unless ..?

      first-index = prefix-index + (string-size prefix)
      from-index = if use-last-for-suffix then void else first-index
      last-index = index-of string, suffix, from-index

      if use-last-for-suffix
        if last-index < first-index

          return ''

      return '' if first-index >= last-index

      string `string-interval` [ first-index, last-index ]

    #

    string-replace-segment = (haystack, [ pattern, replacement, use-regexp = no, regexp-flags ]) ->

      needle = if use-regexp
        create-regexp pattern, regexp-flags
      else
        pattern

      haystack.replace needle, replacement

    string-remove-segment = (string, [ pattern, use-regexp, regexp-flags ]) -> string `string-replace-segment` [ pattern, '', use-regexp, regexp-flags ]

    string-starts-with-segment = (haystack, prefix) -> (haystack `first-index-of` prefix) is 0

    string-ends-with-segment = (haystack, suffix) ->

      return no if (string-size suffix) > (string-size haystack)

      expected-index = (string-size haystack) - (string-size suffix)
      actual-index =   haystack `last-index-of` suffix

      actual-index is expected-index

    string-as-segments = (string, [ pattern, use-regexp = no ]) ->

      delimiter = if use-regexp

        create-regexp pattern, ''

      else

        pattern

      string.split delimiter

    {
      first-index-of
      last-index-of
      string-contains
      string-segment
      string-interval
      string-split-at-index
      string-segment-prefix-and-suffix
      string-split-by-segment
      string-split-by-first-segment
      string-split-by-last-segment
      string-between
      string-replace-segment
      string-remove-segment
      string-starts-with-segment
      string-ends-with-segment
      string-as-segments
    }