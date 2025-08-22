
  do ->

    { create-error-context } = dependency 'value.error.ErrorContext'
    { array-item-indices } = dependency 'value.Array'
    { object-member-names } = dependency 'value.Object'
    { create-notifier } = dependency 'value.instance.Notifier'
    { map-array-items } = dependency 'value.Array'
    { camel-case } = dependency 'value.string.Case'

    { value-as-string } = dependency 'value.AsString'

    { context } = create-error-context 'value.instance.State'

    validate-state-machine = (states, transitions) ->

      { argtype, arg-error } = context 'validate-state-machine'

      argtype '[ *:String ]' {states} ; argtype '<Object>' {transitions}

      states-list = states * ', '

      if states.length < 2
        throw arg-error {states}, "A state machine must have at least two states."

      for state in states

        if (array-item-indices states, state .length) > 1
          throw arg-error {state}, "State '#state' appears more than once in #states-list"

      for transition-name, states-pair of transitions

        try argtype '[ String String ]' {states-pair}
        catch error => throw arg-error {states-pair} "Invalid transition '#transition-name'. Transitions must declare a source and a target state."

        [ source-state, target-state ] = states-pair

        if source-state is target-state
          throw arg-error {states-pair} "Cannot transition to itself."

        unless source-state in states
          throw arg-error {source-state} "Must be one of #states-list."

        unless target-state in states
          throw arg-error {target-state} "Must be one of #states-list."

    validate-initial-state = (states, initial-state) ->

      { arg-error } = context 'validate-initial-state'

      unless initial-state in states
        throw arg-error {initial-state} "Initial state '#initial-state' must be any of #{ states * ', ' }"

    get-state-events = (states) ->

      events = [] ; for state in states => events => ..push camel-case "enter-#state" ; ..push camel-case "leave-#state"
      events

    get-transition-events = (transitions) ->

      events = [] ; for transition-name of transitions => events => ..push camel-case "before-#transition-name" ; ..push camel-case "after-#transition-name"
      events

    attach-event-handlers = (instance, notifier, event-names) ->

      for event-name in event-names

        instance[ event-name ] = notifier.notifications[ event-name ]

    #

    create-state = (states, transitions, name = 'state') ->

      { argtype, arg-error, context: cs-context } = context 'create-state'

      member-name = camel-case name

      validate-state-machine states, transitions

      current-state = states.0

      state-notifier = create-notifier get-state-events states
      transition-notifier = create-notifier get-transition-events transitions

      instance = {} ; states-lookup = {}

      attach-event-handlers instance, transition-notifier, get-transition-events transitions
      attach-event-handlers instance, state-notifier, get-state-events states

      for name, transition of transitions

        [ source, target ] = transition

        do (transition-name = name, source-state = source, target-state = target) ->

          lookup = states-lookup[ source-state ]

          if lookup is void
            states-lookup[ source-state ] := transition-name

          states-lookup[ source-state ][ target-state ] := yes

          instance[ transition-name ] = ->

            { arg-error } = cs-context transition-name

            if current-state isnt source-state

              throw arg-error {current-state} "Transition '#transition-name' not possible from state '#current-state'."

            transition-notifier.notify [ "before-#transition-name" ], source-state, target-state
            state-notifier.notify [ "leave-#source-state" ], source-state, target-state

            current-state := target-state

            state-notifier.notify [ "enter-#target-state" ], source-state, target-state
            transition-notifier.notify [ "after-#transition-name" ], source-state, target-state

      transition.transition-to = (target-state) ->

        { arg-error } = cs-context 'transition-to'

        transition-name = states-lookup[ current-state ][ target-state ]

        if transition-name isnt void

          instance[transition-name]!

        else

          throw arg-error {target-state}, "No transitions found from '#current-state' to '#target-state'."

      member-names = object-member-names instance

      if member-name in member-names

        throw arg-error {member-name} "Member name '#member-name' collides with existing member names #{ member-names * ', ' }"

      instance[ member-name ] = -> current-state

      instance

    {
      create-state,
      validate-state-machine
    }
