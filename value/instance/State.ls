
  do ->

    { camel-case } = dependency 'value.string.Case'
    { create-notifier } = dependency 'value.instance.Notifier'
    { argument-type: argtype } = dependency 'value.reflection.Type'
    { array-item-indices } = dependency 'value.Array'
    { create-error-context } = dependency 'value.error.ErrorContext'
    { value-as-string } = dependency 'value.AsString'

    { context } = create-error-context 'value.instance.State'

    create-transition-event = (transition, from-state, to-state) ->

      { transition, from-state, to-state, timestamp: new Date! }

    validate-state-machine = (states, transitions) ->

      { argtype, arg-error } = context 'validate-state-machine'

      argtype '[ *:String ]' {states} ; argtype '<Object>' {transitions}

      if states.length < 2
        throw arg-error {states}, "A state machine must have at least two states."

      for state in states
        if (array-item-indices states, state) .length > 1
          throw arg-error {states}, "State is duplicated."

      for transition-name, states-pair of transitions

        try argtype '[ String String ]' {states-pair}
        catch => throw arg-error {states-pair}, "Invalid transition '#transition-name'. Transitions must declare a source and a target state."

        [ source-state, target-state ] = states-pair

        if source-state is target-state
          throw arg-error {states-pair}, "Cannot transition to itself."

        if source-state not in states
          throw arg-error {source-state}, "Must be one of #{ states * ', ' }."

        if target-state not in states
          throw arg-error {target-state}, "Must be one of #{ states * ', ' }."

    get-state-events = (states) ->
      events = []
      for state in states
        events.push "enter-#{state}"
        events.push "leave-#{state}"
      events

    get-transition-events = (transitions) ->
      events = []
      for transition-name of transitions
        events.push "before-#{transition-name}"
        events.push "after-#{transition-name}"
      events

    attach-event-handlers = (instance, notifier, event-names) ->
      for event-name in event-names
        handler-name = camel-case event-name
        instance[handler-name] = notifier.notifications[handler-name]

    create-state = (states, transitions, initial-state) ->

      { argtype, arg-error } = context 'create-state'

      argtype '<String|Undefined>' {initial-state}

      if initial-state is void
        initial-state = states.0

      if initial-state not in states
        throw arg-errror {initial-state} "Initial state must be any of #{ states * ', ' }."

      current-state = initial-state

      validate-state-machine states, transitions

      state-notifier = create-notifier get-state-events states
      transition-notifier = create-notifier get-transition-events transitions

      instance = {}

      instance.state = -> current-state

      instance.transition-to = (target-state) ->

        for transition-name, { source-state, target-state: transition-target-state } of transitions

          if source-state is current-state and target-state is transition-target-state

            from-state = current-state

            transition-notifier.notify ["before-#{transition-name}"], from-state, target-state
            state-notifier.notify ["leave-#{from-state}"], from-state, target-state

            current-state = target-state

            state-notifier.notify ["enter-#{target-state}"], from-state, target-state
            transition-notifier.notify ["after-#{transition-name}"], from-state, target-state

            return # transition successful

        throw arg-error {target-state}, "No valid transition from '#current-state' to '#target-state'."

      for name, transition of transitions
        do (transition-name = name, { source-state, target-state } = transition) ->
          instance[camel-case transition-name] = ->
            if current-state isnt source-state
              throw arg-error { current-state }, "Transition '#{transition-name}' not available from state '#{current-state}'."

            from-state = current-state

            transition-notifier.notify ["before-#{transition-name}"], from-state, target-state
            state-notifier.notify ["leave-#{from-state}"], from-state, target-state

            current-state = target-state

            state-notifier.notify ["enter-#{target-state}"], from-state, target-state
            transition-notifier.notify ["after-#{transition-name}"], from-state, target-state

      attach-event-handlers instance, transition-notifier, get-transition-events transitions
      attach-event-handlers instance, state-notifier, get-state-events states

      instance

    {
      validate-state-machine,
      create-state
    }