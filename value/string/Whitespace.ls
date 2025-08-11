
  do ->

    { punctuation-chars: { backslash } } = dependency 'value.string.Ascii'
    { string-remove-segment, string-replace-segment, string-as-segments } = dependency 'value.string.Segment'

    whitespace = "#{backslash}s+"

    at-start = caret = '^'
    at-end = dollar-sign = '$'

    leading-whitespace = "#at-start#whitespace"
    trailing-whitespace = "#whitespace#at-end"

    trimmed-string = (string) -> string `string-remove-segment` [ "#leading-whitespace|#trailing-whitespace", yes ]

    whitespace-as-separator = (string, separator = '_') -> string `string-replace-segment` [ whitespace, yes ]

    string-as-words = (string) -> string |> trimmed-string |> string-as-segments _ , [ whitespace, yes ]

    {
      trimmed-string, whitespace-as-separator, string-as-words
    }
