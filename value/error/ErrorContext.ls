
  do ->

    { argument-type: argtype } = dependency 'value.reflection.Type'
    { create-error } = dependency 'value.error.Error'

    create-context-object = (qualified-namespace, parent-contexts = []) ->

      current-context-chain = parent-contexts

      attach-current-context-to-error = (error) ->

        error <<< { namespace: qualified-namespace, contexts: current-context-chain.slice() }

      context-function = (context-name) ->

        new-chain = current-context-chain ++ [ context-name ]
        create-context-object qualified-namespace, new-chain

      contextualized-argtype = (value, type) ->

        try result = argtype value, type
        catch error => attach-current-context-to-error error ; throw error
        result

      contextualized-arg-error = (message, description, cause) ->

        error = create-error message, description, cause ; attach-current-context-to-error error
        error

      context: context-function
      argtype: contextualized-argtype
      arg-error: contextualized-arg-error

    create-error-context = (qualified-namespace) ->

      context: (context-name) ->
        create-context-object qualified-namespace, [ context-name ]

    {
      create-error-context
    }
