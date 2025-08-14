
  do ->

    { argument-type: argtype } = dependency 'value.reflection.Type'
    { create-argument-error: arg-error } = dependency 'value.ArgumentError'
    { is-function } = dependency 'value.Type'

    compose-with = (target-instance, source-tuple) ->

      argtype '<Object>' {target-instance}
      
      [ source-instance, member-names ] = source-tuple
      
      argtype '<Object>' {source-instance}

      if member-names is void
        member-names = [ member-name for member-name of source-instance ]
      else
        argtype '[ *:String ]' {member-names}

      for member-name in member-names
        member-value = source-instance[member-name]

        if member-value isnt void
          if is-function member-value
            target-instance[member-name] = do (original-method = member-value) ->
              -> original-method.apply source-instance, arguments
          else
            target-instance[member-name] = member-value
        else
          available = [ name for name of source-instance when source-instance[name] isnt void ]
          throw arg-error {member-name} "Member '#{member-name}' not found. Available: #{ available * ', ' }"

      target-instance

    {
      compose-with
    }