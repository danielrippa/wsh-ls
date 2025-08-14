
  do ->

    { string-between, first-index-of, string-contains, string-interval } = dependency 'value.string.Segment'
    { string-as-lines } = dependency 'value.string.Text'
    { trimmed-string } = dependency 'value.string.Whitespace'
    { keep-array-items, map-array-items } = dependency 'value.Array'
    { value-is-function } = dependency 'value.Type'

    comma = ', '

    contains-comma = -> it `string-contains` comma

    is-comment-line = -> it |> trimmed-string |> string-interval _ , [ 0, 2 ] |> (== '//')

    as-comments = (lines) -> map-array-items lines, (line) -> line |> trimmed-string |> string-interval _ , [ 3 ]

    decompose-function = (fn) ->

      fn |> (.to-string!)

        name  = string-between .. , [ ' ' '(' ]

        param = string-between .. , <[ ( ) ]>
        code  = string-between .. , <[ { } ]>, yes

        comments = .. |> string-as-lines |> keep-array-items _ , is-comment-line |> as-comments

      parameter-names = match param

        | (== '') => []
        | contains-comma => param / "#comma"

        else [ param ]

      { name, parameter-names, code, comments }

    function-name = -> decompose-function it .name
    function-code = -> decompose-function it .code

    function-comments = -> decompose-function it .comments

    function-parameter-names = -> decompose-function it .parameter-names

    function-execute-with-args = (fn, args, context = null) -> fn.apply context, args
    
    function-execute-with-call = (fn, context, args-object) -> fn.apply context, arguments-as-array args-object

    arguments-as-array = (arguments-value) -> Array.prototype.slice.call arguments-value

    {
      function-name, function-code, function-parameter-names, function-comments
      function-execute-with-args, function-execute-with-call,
      arguments-as-array
    }
