
  do ->

    { argument-type: argtype } = dependency 'value.reflection.Type'
    { create-argument-requirement-error: arg-error } = dependency 'value.error.ArgumentError'

    get-available-members = (obj) ->
      [ member for member of obj when obj[member] isnt void ]

    compose-single-source = (target, source, members, options = {}) ->
      
      conflict-strategy = options.on-conflict or 'overwrite'
      
      if members is void
        members = get-available-members source
      
      for member-name in members
        member-value = source[member-name]
        
        if member-value is void
          available = get-available-members source
          throw new Error "Member '#{member-name}' not found on source. Available: #{available * ', '}"
        
        # Handle conflicts
        if target[member-name] isnt void and conflict-strategy is 'skip'
          continue
        else if target[member-name] isnt void and conflict-strategy is 'error'
          throw new Error "Member '#{member-name}' already exists on target"
        
        if (typeof member-value) is 'function'
          target[member-name] = do (original-method = member-value) ->
            -> original-method.apply source, arguments
        else
          target[member-name] = member-value

    compose-with = (target-instance, source-or-specs, members-or-options, options) ->
      
      argtype '<Object>' {target-instance}
      
      # Handle multiple call signatures
      if arguments.length is 2
        # compose-with(target, [source, members]) - legacy format
        if source-or-specs.length is 2
          [ source, members ] = source-or-specs
          compose-single-source target-instance, source, members
        # compose-with(target, source) - all members
        else
          compose-single-source target-instance, source-or-specs
      
      else if arguments.length is 3
        # compose-with(target, source, members)
        # compose-with(target, source, options)
        if members-or-options.length?
          compose-single-source target-instance, source-or-specs, members-or-options
        else
          compose-single-source target-instance, source-or-specs, void, members-or-options
      
      else if arguments.length is 4
        # compose-with(target, source, members, options)
        compose-single-source target-instance, source-or-specs, members-or-options, options
      
      target-instance

    compose-multiple = (target-instance, composition-specs, global-options = {}) ->
      
      argtype '<Object>' {target-instance}
      argtype '[ *:Object ]' {composition-specs}
      
      for spec in composition-specs
        if spec.from
          # { from: source, members: [...], options: {...} }
          source = spec.from
          members = spec.members
          spec-options = spec.options or {}
          merged-options = {} <<< global-options <<< spec-options
          compose-single-source target-instance, source, members, merged-options
        else
          throw new Error "Composition spec must have 'from' property"
      
      target-instance

    uncompose-from = (target-instance, source-instance) ->
      
      argtype '<Object>' {target-instance}
      argtype '<Object>' {source-instance}
      
      for member-name of source-instance
        if target-instance[member-name]?
          delete target-instance[member-name]
      
      target-instance

    uncompose-members = (target-instance, member-names) ->
      
      argtype '<Object>' {target-instance}
      argtype '[ *:String ]' {member-names}
      
      for member-name in member-names
        if target-instance[member-name]?
          delete target-instance[member-name]
      
      target-instance

    get-composition-info = (target-instance) ->
      
      # Simple implementation - could be enhanced with tracking
      members = get-available-members target-instance
      
      {
        member-count: members.length
        members: members
      }

    {
      compose-with
      compose-multiple
      uncompose-from
      uncompose-members
      get-composition-info
    }