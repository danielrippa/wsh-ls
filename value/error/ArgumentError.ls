
  do ->

    { create-error } = dependency 'value.error.Error'
    { typed-value-as-display-string: typed } = dependency 'value.Display'
    { value-is-object } = dependency 'value.Type'
    { object-member-names } = dependency 'value.Object'

    argument-error-message = (argument-name, argument-value) ->

      "Invalid argument '#argument-name' with value #{ typed argument-value }"

    create-type-error = (message) -> create-error message, TypeError

    must-be = (argument, requirement) -> 
      keys = object-member-names argument ; argument-name = keys.0
      "Argument '#argument-name' must be #requirement"

    create-argument-error = (argument, message, error-type = TypeError) ->

      throw create-type-error 'argument' `must-be` 'Object' \
        unless value-is-object argument

      keys = object-member-names argument

      throw create-type-error "Argument object must have at least one member." \
        unless keys.length > 0

      argument-name = keys.0
      argument-value = argument[argument-name]
      create-error "#{ argument-error-message argument-name, argument-value }. #message", error-type

    create-argument-requirement-error = (argument, requirement) ->
      create-argument-error argument, (argument `must-be` requirement)

    create-argument-type-error = (argument, type-name) ->
      create-argument-requirement-error argument, type-name

    {
      create-argument-error
      create-argument-type-error
      create-argument-requirement-error
    }