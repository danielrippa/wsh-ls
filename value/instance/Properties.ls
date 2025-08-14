
  do ->

    { create-instance } = dependency 'value.instance.Instance'
    { argument-type: argtype } = dependency 'value.reflection.Type'

    create-property-change = (model, property-name, old-property-value, new-property-value) ->

      { model, property-name, old-property-value, new-property-value }

    create-properties-model = (properties) ->

      argtype '<Object>' {properties}

      state-synchronized = yes

      create-instance do

        is-synchronized: getter: -> state-synchronized

        lifecycle: notifier: <[
          on-access
          before-change after-change
          before-changes after-changes
          state-updated state-synchronized
        ]>

        get: method: (property-name) ->

          argtype '<String>' {property-name}
          property-value = properties[ property-name ]
          @lifecycle.notify <[ on-access ]>, { property-name, property-value }

          property-value

        set: method: (property-name, new-property-value) ->

          old-property-value = properties[ property-name ]

          return no if new-property-value is old-property-value

          change = create-property-change @, property-name, old-property-value, new-property-value

          @lifecycle.notify <[ before-change ]>, change

          properties[ property-name ] := new-property-value

          state-synchronized := no

          @lifecycle.notify <[ after-change ]>, change
          @lifecycle.notify <[ state-updated ]>, @

          yes

        update: method: (property-values) ->

          changes = []

          for property-name, new-property-value of property-values

            current-property-value = properties[ property-name ]

            continue if new-property-value is current-property-value

            changes.push create-property-change @, property-name, current-property-value, new-property-value

          return if changes.length is 0

          @lifecycle.notify <[ before-changes ]>, changes

          for property-name, new-property-value of property-values

            properties[ property-name ] := new-property-value

          state-synchronized := no

          @lifecycle.notify <[ after-changes ]>, changes
          @lifecycle.notify <[ state-updated ]>, @

        synchronize: method: -> state-synchronized := yes ; @lifecycle.notify <[ state-synchronized ]>, @

    {
      create-properties-model
    }