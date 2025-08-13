
  do ->

    { camel-case } = dependency 'value.string.Case'
    { create-notifier } = dependency 'value.instance.Notifier'
    { argument-type: argtype } = dependency 'value.reflection.Type'
    { create-argument-requirement-error: arg-error } = dependency 'value.error.ArgumentError'

    create-transition-event = (transition, from-state, to-state, extra = {}) ->

      { transition, from-state, to-state, timestamp: new Date! } <<< extra

    states-pair-as-transition = (transition-name, states-pair) ->

      [ source-state, target-state ] = states-pair

      { from: source-state, to: target-state }

    create-state = (states, transitions, instance-context = {}) ->

      argtype '[ *:String ]' {states} ; argtype '<Object>' {transitions}

      if states.length < 2
        arg-error {states}, "a state machine must have at least two states"

      current-state = states.0

      for transition-name, states-pair of transitions

        try argtype '[ String String ]' {states-pair}
        catch => arg-error {states-pair}, "Invalid transition '#transition-name'. Transitions must declare a source and a target state."

        [ source-state, target-state ] = states-pair

        if source-state is target-state
          throw arg-error {states-pair}, "cannot transition to itself."

        unless source-state in states
          throw arg-error {source-state}, "must be one of #{ states * ', ' }."

        unless target-state in states
          throw arg-error {target-state}, "must be one of #{ states * ', ' }."

      transition-map = { [ transition-name, states-pair-as-transition transition-name, states-pair ] for transition-name, states-pair of transitions }

      transition-events = []

      for transition-name of transition-map
        transition-events.push "before-#{transition-name}"
        transition-events.push "after-#{transition-name}"

      notifier = create-notifier transition-events

      execute-transition = (transition-name, source-state, target-state) ->
        if current-state isnt source-state
          throw new Error "Cannot #{transition-name}: expected state '#{source-state}', but current state is '#{current-state}'"

        previous-state = current-state

        before-event = create-transition-event transition-name, previous-state, target-state
        notifier.notify ["before-#{transition-name}"], before-event

        hook-name = camel-case "on-#{transition-name}"
        if instance-context[hook-name]
          instance-context[hook-name] previous-state, target-state

        current-state := target-state

        after-event = create-transition-event transition-name, previous-state, current-state, { success: true }
        notifier.notify ["after-#{transition-name}"], after-event

        current-state

      instance = {}

      # Expose current state
      instance.state = -> current-state

      # Allow direct state transition if valid transition exists
      instance.transition-to = (target-state) ->
        # Find a transition from current state to target state
        for transition-name, transition of transition-map
          if transition.from is current-state and transition.to is target-state
            return execute-transition transition-name, current-state, target-state
        
        throw new Error "No valid transition from '#{current-state}' to '#{target-state}'"

      for name, transition of transition-map

        { from: source, to: target } = transition

        do (transition-name = name, source-state = source, target-state = target) ->
          instance[camel-case transition-name] = ->
            execute-transition transition-name, source-state, target-state

      for transition-name of transition-map
        before-event = camel-case "before-#{transition-name}"
        after-event = camel-case "after-#{transition-name}"

        instance[before-event] = notifier.notifications[before-event]
        instance[after-event] = notifier.notifications[after-event]

      instance

    {
      create-state
    }