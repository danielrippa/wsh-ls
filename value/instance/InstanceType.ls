do ->

    { create-error-context } = dependency 'value.error.ErrorContext'
    { create-notifier } = dependency 'value.instance.Notifier'
    { create-instance } = dependency 'value.instance.Instance'
    { create-state, validate-state-machine } = dependency 'value.instance.State'
    { array-item-indices } = dependency 'value.Array'
    { object-member-names } = dependency 'value.Object'

    { context } = create-error-context 'value.component.InstanceType'

    create-instance-type-manager = ->

      { context: tm-context } = context 'create-instance-type-manager'

      instance-types = {}

      behavior-types = {}
      state-machines = {}
      property-types = {}

      state-machine-to-instance-types = {}

      lifecycle = create-notifier <[ instance-type-created instance-type-behavior-set instance-type-property-set instance-type-state-machine-set ]>

      get-behavior-type = (name) -> behavior-types[ name ]

      get-existing-behavior-type = (name) ->

        { arg-error } = tm-context 'get-existing-behavior-type'

        behavior-type = get-behavior-type name

        throw arg-error {name} "Behavior type does not exist." if behavior-type is void

        behavior-type

      set-behavior-type = (name, behavior-kind, behavior) ->

        { argtype, arg-error } = tm-context 'set-behavior-type'

        argtype '<String>' {kind} ; argtype '<Function>' {behavior}

        throw arg-error {name}, "Behavior type is already registered." if (get-behavior-type name) isnt void

        behavior-types[ name ] := { behavior-kind, behavior, required: false }

      set-behavior-type-required = (name, required) ->

        { argtype, arg-error } = tm-context 'set-behavior-type-required'

        argtype '<String>' {name} ; argtype '<Boolean>' {required}

        behavior-type = get-existing-behavior-type name
        behavior-type.required = required

      get-instance-type = (name) -> instance-types[ name ]

      get-existing-instance-type = (name) ->

        { arg-error } = tm-context 'get-existing-instance-type'

        instance-type = get-instance-type name

        throw arg-error {name} "Instance type does not exist." if instance-type is void

        instance-type

      create-instance-type = (name) ->

        { arg-error } = tm-context 'create-instance-type'

        if (get-instance-type name) isnt void => throw arg-error {name} "Instance type is already registered."

        instance-types[ name ] = { behaviors: {}, states: {}, properties: {} }

        lifecycle.notify <[ instance-type-created ]>, instance-types[ name ]

      set-instance-type-behavior = (instance-type-name, behavior-type-name, member-name) ->

        { argtype } = tm-context 'set-instance-type-behavior'

        argtype '<String>' {instance-type-name} ; argtype '<String>' {behavior-type-name} ; argtype '<String>' {member-name}

        instance-type = get-existing-instance-type instance-type-name
        behavior-type = get-existing-behavior-type behavior-type-name

        instance-type.behaviors[member-name] = behavior-type-name

        lifecycle.notify <[ instance-type-behavior-set ]>, { instance-type-name, instance-type, member-name, behavior-type-name }

      get-state-machine = (name) -> state-machines[ name ]

      get-existing-state-machine = (name) ->

        { arg-error } = tm-context 'get-existing-state-machine'

        state-machine = get-state-machine name

        throw arg-error {name} "State machine does not exist." if state-machine is void

        state-machine

      create-state-machine = (name, ...initial-state-names) ->

        { argtype, arg-error } = tm-context 'create-state-machine'

        argtype '<String>' {name} ; argtype '[ *:String ]' {initial-state-names} ; argtype '[ String String ... ]' {initial-state-names}

        throw arg-error {name}, "State machine is already registered." if (get-state-machine name) isnt void

        state-machines[ name ] := { state-names: initial-state-names, initial-state: initial-state-names[0], transitions: [] }

      set-state-machine-initial-state = (state-machine-name, initial-state-name) ->

        { argtype, arg-error } = tm-context 'set-state-machine-initial-state'

        argtype '<String>' {state-machine-name} ; argtype '<String>' {initial-state-name}

        state-machine = get-existing-state-machine state-machine-name

        if initial-state-name not in state-machine.state-names
          throw arg-error {initial-state-name}, "Initial state must be one of #{ state-machine.state-names * ', ' }."

        state-machine.initial-state = initial-state-name

      transitions-array-to-object = (object-array) ->

        transitions-object = {}

        { argtype, arg-error } = tm-context 'transitions-array-to-object'

        argtype '[ *:Object ]' {object-array}

        for transition-object, transition-index in object-array

          argtype '{ ? }' {transition-object}

          object-property-names = object-member-names transition-object

          [ transition-name ] = object-property-names

          existing-transition-property-value = transitions-object[ transition-name ]

          if existing-transition-property-value isnt void

            throw arg-error {transition-object}, "State machine type has duplicate transition names."

          current-transition-object-property-value = transition-object[ transition-name ]

          argtype '[ String String ]' {current-transition-object-property-value}

          [ source-state, target-state ] = current-transition-object-property-value

          transitions-object[ transition-name ] = [ source-state, target-state ]

        transitions-object

      validate-states-and-transitions = (states, transition-objects) ->

        validate-state-machine states, transitions-array-to-object transition-objects

      add-state-machine-state = (state-machine-name, state-name) ->

        { argtype } = tm-context 'add-state-machine-state'

        argtype '<String>' {state-machine-name} ; argtype '<String>' {state-name}

        state-machine = get-existing-state-machine state-machine-name

        new-state-names = state-machine.state-names.slice!
        new-state-names.push state-name

        validate-states-and-transitions new-state-names, state-machine.transitions

        state-machine.state-names = new-state-names

        for instance-type-name in state-machine-to-instance-types[state-machine-name] or []
          instance-type = get-existing-instance-type instance-type-name
          for member-name, state of instance-type.states
            if state.name is state-machine-name
              lifecycle.notify <[ instance-type-state-machine-set ]>, { instance-type-name, instance-type, state-machine-name, member-name }

      add-state-machine-transition = (state-machine-name, transition-name, source-state, target-state) ->

        { argtype } = tm-context 'add-state-machine-transition'

        argtype '<String>' {state-machine-name} ; argtype '<String>' {transition-name} ; argtype '<String>' {source-state} ; argtype '<String>' {target-state}

        state-machine = get-existing-state-machine state-machine-name

        new-transition = {}
        new-transition[transition-name] = [source-state, target-state]

        new-transitions = state-machine.transitions.slice!
        new-transitions.push new-transition

        validate-states-and-transitions state-machine.state-names, new-transitions

        state-machine.transitions = new-transitions

        for instance-type-name in state-machine-to-instance-types[state-machine-name] or []
          instance-type = get-existing-instance-type instance-type-name
          for member-name, state of instance-type.states
            if state.name is state-machine-name
              lifecycle.notify <[ instance-type-state-machine-set ]>, { instance-type-name, instance-type, state-machine-name, member-name }

      set-instance-type-state-machine = (instance-type-name, state-machine-name, member-name, initial-state-name = void) ->

        { argtype, arg-error } = tm-context 'set-instance-type-state-machine'

        argtype '<String>' {instance-type-name } ; argtype '<String>' {state-machine-name} ; argtype '<String>' {member-name} ; argtype '<String|Undefined>' {initial-state-name}

        instance-type = get-existing-instance-type instance-type-name
        state-machine = get-existing-state-machine state-machine-name

        if initial-state-name isnt void and initial-state-name not in state-machine.state-names
          throw arg-error {initial-state-name}, "Initial state must be one of #{ state-machine.state-names * ', ' }."

        instance-type.states[member-name] = { name: state-machine-name, initial-state: initial-state-name }

        if state-machine-to-instance-types[state-machine-name] is void
          state-machine-to-instance-types[state-machine-name] = []
        state-machine-to-instance-types[state-machine-name].push instance-type-name

        lifecycle.notify <[ instance-type-state-machine-set ]>, { instance-type-name, instance-type, state-machine-name, member-name }

      get-property-type = (name) -> property-types[ name ]

      get-existing-property-type = (name) ->

        { arg-error } = tm-context 'get-existing-property-type'

        property-type = get-property-type name ; throw arg-error {name} "Property type does not exist." if property-type is void

        property-type

      set-property-type = (name, type, kind, default-value = void) ->

        { argtype, arg-error } = tm-context 'set-property-type'

        argtype '<String>' {name} ; argtype '<String>' {type} ; argtype '<String>' {kind}

        throw arg-error {name}, "Property type is already registered." if (get-property-type name) isnt void

        property-types[ name ] := { type, default-value, read-only: true, required: false, kind }

      set-property-type-writable = (name) ->

        { argtype } = tm-context 'set-property-type-writable'

        argtype '<String>' {name}

        property-type = get-existing-property-type name
        property-type.read-only = false

      set-property-type-required = (name, required) ->

        { argtype, arg-error } = tm-context 'set-property-type-required'

        argtype '<String>' {name} ; argtype '<Boolean>' {required}

        property-type = get-existing-property-type name
        property-type.required = required

      set-instance-type-property = (instance-type-name, property-type-name, member-name) ->

        { argtype } = tm-context 'set-instance-type-property'

        argtype '<String>' {instance-type-name} ; argtype '<String>' {property-type-name} ; argtype '<String>' {member-name}

        instance-type = get-existing-instance-type instance-type-name
        property-type = get-existing-property-type property-type-name

        instance-type.properties[member-name] = property-type-name

        lifecycle.notify <[ instance-type-property-set ]>, { instance-type-name, instance-type, member-name, property-type-name }

      build-instance-type = (name) ->

        { argtype } = tm-context 'build-instance-type'

        argtype '<String>' {name}

        instance-type = get-existing-instance-type name

        behaviors = {}
        for member-name, behavior-type-name of instance-type.behaviors
          { behavior-kind, behavior: behavior-function, required } = get-existing-behavior-type behavior-type-name
          behaviors[member-name] = { behavior-kind, behavior-function, required }

        state-machines = {}
        for member-name, state-machine-desc of instance-type.states
          { name: state-machine-name, initial-state } = state-machine-desc
          state-machine = get-existing-state-machine state-machine-name
          initial-state = if initial-state isnt void then initial-state else state-machine.initial-state
          state-machines[member-name] = {
            state-names: state-machine.state-names.slice!
            transitions: state-machine.transitions.slice!
            initial-state: initial-state
          }

        properties = {}
        for member-name, property-type-name of instance-type.properties
          { type, default-value, read-only, required, kind } = get-existing-property-type property-type-name
          properties[member-name] = { type, default-value, read-only, required, kind }

        { name, behaviors, state-machines, properties }

      {
        set-behavior-type,
        set-property-type,
        set-property-type-writable,
        set-property-type-required,
        set-behavior-type-required,
        create-state-machine,
        add-state-machine-state,
        add-state-machine-transition,
        set-state-machine-initial-state,

        create-instance-type,
        build-instance-type,

        get-instance-type: get-existing-instance-type,
        get-behavior-type: get-existing-behavior-type,
        get-property-type: get-existing-property-type,
        get-state-machine: get-existing-state-machine,

        set-instance-type-behavior,
        set-instance-type-property,
        set-instance-type-state-machine,

        lifecycle
      }

    instance-type-manager = create-instance-type-manager!

    get-instance-type-manager = -> instance-type-manager

    build-property-descriptor = (property) ->
      property-value = property.default-value
      getter = -> property-value
      setter = if property.read-only then void else (value) -> property-value := value
      descriptor = { getter, attributes: [] }
      if setter then descriptor.setter = setter
      descriptor

    build-state-descriptor = (state-machine) ->
      { state-names, transitions: state-machine-transitions, initial-state } = state-machine
      transitions = {}
      for transition in state-machine-transitions
        for transition-name, states-pair of transition
          transitions[transition-name] = states-pair
      { state: [state-names, transitions, initial-state], attributes: [] }

    build-behavior-descriptor = (behavior-function) ->
      { method: behavior-function, attributes: [] }

    create-instance-builder = ->

      { context: ib-context } = context 'create-instance-builder'

      instance-type-manager = get-instance-type-manager!

      create-instance-from-instance-type = (instance-type-name) ->

        { argtype } = ib-context 'create-instance-from-instance-type'

        argtype '<String>' {instance-type-name}

        instance-type = instance-type-manager.build-instance-type instance-type-name

        { behaviors, state-machines, properties } = instance-type

        member-descriptors = {}

        for member-name, { behavior-function } of behaviors
          member-descriptors[member-name] = build-behavior-descriptor behavior-function

        for member-name, state-machine of state-machines
          member-descriptors[member-name] = build-state-descriptor state-machine

        for member-name, property of properties
          member-descriptors[member-name] = build-property-descriptor property

        create-instance member-descriptors

      create-instance: create-instance-from-instance-type

    instance-builder = create-instance-builder!

    get-instance-builder = -> instance-builder

    {
      get-instance-type-manager, get-instance-builder,
      build-property-descriptor, build-state-descriptor, build-behavior-descriptor
    }