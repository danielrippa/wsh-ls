
  do ->

    { object-member-names } = dependency 'value.Object'

    create-error = (message, description, cause) ->

      new Error message => .. <<< { description } unless description is void ;  .. <<< { cause } if cause isnt void

    {
      create-error
    }