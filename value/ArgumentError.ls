
  do ->

    { create-error } = dependency 'value.Error'
    { object-member-names } = dependency 'value.Object'
    { is-object } = dependency 'value.Type'
    { typed-value-as-string } = dependency 'value.Value'

    invalid-argument = (argument-name, argument-value) ->

      "Invalid argument '#argument-name' with value #{ typed-value-as-string argument-value }."

    argument-name-and-value = (argument) ->

      throw create-error (invalid-argument 'argument', argument), "Argument must be an Object." \
        unless is-object argument

      keys = object-member-names argument ; throw create-error  (invalid-argument 'argument', argument), "Argument object must have one key." \
        unless keys.length is 1

      argument-name = keys.0 ; argument-value = argument[ argument-name ]

      { argument-name, argument-value }

    create-argument-error = (argument, message, description, cause) ->

      { argument-name, argument-value } = argument-name-and-value argument

      create-error "#{ invalid-argument argument-name, argument-value } #message", description, cause

    {
      create-argument-error
    }