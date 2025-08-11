
  do ->

    { camel-case } = dependency 'value.string.Case'
    { create-notifier } = dependency 'value.instance.Notifier'

    # Create state with clean syntax
    create-state = (states, transitions, instance-context = {}) ->

      # Initial state is first in states array
      current-state = states[0]

      # Build transition map from object format: { poweron: ['poweredoff', 'idle'], ... }
      transition-map = {}
      for transition-name, [from-state, to-state] of transitions
        transition-map[transition-name] = { from: from-state, to: to-state }

      # Create transition event names
      transition-events = []
      for transition-name of transition-map
        transition-events.push "before-#{transition-name}"
        transition-events.push "after-#{transition-name}"

      # Create notifier for transition events
      notifier = create-notifier transition-events

      # Helper to create transition event
      create-transition-event = (transition-name, from-state, to-state, extra = {}) ->
        {
          transition: transition-name,
          from-state: from-state,
          to-state: to-state,
          timestamp: new Date!
        } <<< extra

      # Helper to fire transition events and execute transition
      execute-transition = (transition-name, from-state, to-state) ->
        if current-state isnt from-state
          throw "Cannot #{transition-name}: expected state '#{from-state}', but current state is '#{current-state}'"

        old-state = current-state

        # Fire before event
        before-event = create-transition-event transition-name, old-state, to-state
        notifier.notify ["before-#{transition-name}"], before-event

        # Call hook if it exists in instance context
        hook-name = camel-case "on-#{transition-name}"
        if instance-context[hook-name]
          instance-context[hook-name] old-state, to-state

        # Change state
        current-state := to-state

        # Fire after event
        after-event = create-transition-event transition-name, old-state, current-state, { success: true }
        notifier.notify ["after-#{transition-name}"], after-event

        current-state

      # Create instance interface that can be merged directly
      interface = {}

      # Create transition methods
      for transition-name, { from: from-state, to: to-state } of transition-map
        do (transition-name = transition-name, from-state = from-state, to-state = to-state) ->
          interface[camel-case transition-name] = ->
            execute-transition transition-name, from-state, to-state

      # Add event subscription methods
      for transition-name of transition-map
        before-event = camel-case "before-#{transition-name}"
        after-event = camel-case "after-#{transition-name}"

        interface[before-event] = notifier.events[before-event]
        interface[after-event] = notifier.events[after-event]

      interface

    {
      create-state
    }