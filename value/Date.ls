
  do ->

    { map-array-items } = dependency 'value.Array'

    now = -> new Date!get-time!

    date-tuple = (date) ->
      * date.get-full-year!
        date.get-month! + 1
        date.get-date!

    time-tuple = (date) ->
      * date.get-hours!
        date.get-minutes!
        date.get-seconds!

    date-as-tuples = (date) ->
      * date-tuple date
        time-tuple date

    pad = (n) -> if n < 10 then "0#n" else String n

    tuple-as-string = (tuple) -> tuple |> map-array-items _ , pad |> (* '-')

    tuples-as-string = ([ date-tuple, time-tuple ]) ->

      "#{ tuple-as-string date-tuple }T#{ tuple-as-string time-tuple }"

    get-timestamp = (date = new Date!) -> date |> date-as-tuples |> tuples-as-string

    get-datestamp = (date = new Date!) -> 
      date |> date-tuple |> tuple-as-string

    {
      now,
      get-timestamp, get-datestamp
    }