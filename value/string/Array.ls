  do ->

    # ES3-compatible fold implementation
    # fold(array, initial, function)
    fold = (array, initial, fn) ->
      acc = initial
      for element, i in array
        acc = fn acc, element, i
      acc

    {
      fold
    }