
  do ->

    { control-chars: { rs: record-separator }, crlf, lf } = dependency 'value.string.Ascii'
    { string-replace-segment } = dependency 'value.string.Segment'

    string-as-lines = (string) ->

      string

        |> _ `string-replace-segment` [ crlf, record-separator, yes ]
        |> _ `string-replace-segment` [ lf,   record-separator, yes ]

        |> (/ "#record-separator")

    lines-as-string = (lines, separator = lf) -> lines * "#separator"

    {
      string-as-lines, lines-as-string
    }