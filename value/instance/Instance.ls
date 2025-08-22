
  do ->

    { create-error-context } = dependency 'value.error.ErrorContext'
    { compose-with } = dependency 'value.component.Composition'
    { capital-case } = dependency 'value.string.Case'
    { get-attribute-type-manager } = dependency 'value.instance.Attribute'
    { create-state } = dependency 'value.instance.State'
    { is-function } = dependency 'value.Type'

    { context } = create-error-context 'value.instance.Instance'

    attman = get-attribute-type-manager!

    apply = (member-descriptor, member-type, name, instance) ->

      attman.apply-attributes member-descriptor.attributes, member-descriptor[member-type], member-type, name, instance

    create-instance = (member-descriptors) ->

      { argtype, arg-error } = context 'create-instance'

      argtype '<Object>' {member-descriptors}

      instance = {}

      for name, member-descriptor of member-descriptors

        argtype '<Object>' {member-descriptor}

        match member-descriptor

          | (.member isnt void) =>

            instance[ name ] = member-descriptor.member

          | (.method isnt void) =>

            instance[ name ] = apply member-descriptor, 'method', name, instance

          | (.state isnt void) =>

            [ states, transitions ] = member-descriptor.state

            state-machine = create-state states, transitions, name

            instance `compose-with` [ state-machine ]

          | (.notifier isnt void) =>

            notifier = create-notifier member-descriptor.notifier

            instance `compose-with` [ notifier.notifications ]

          | (.getter isnt void) or (.setter isnt void) =>

            if member-descriptor.getter isnt void

              if is-function member-descriptor.getter

                getter = apply member-descriptor, 'getter', name, instance
                instance[ name ] = -> getter instance

              else

                throw arg-error {getter: member-descriptor.getter} "Getter must be a function"

            if member-descriptor.setter isnt void

              if is-function member-descriptor.setter

                setter = apply member-descriptor, 'setter', name, instance
                instance[ "set#{ capital-case name }" ] = (value) ->

                  setter.call instance, value

              else

                throw arg-error {getter: member-descriptor.getter} "Setter must be a function"
          else

            throw arg-error {member-descriptor} "Unknown member descriptor type for name '#name'. Expected member, method, notifier, getter or setter."

      instance

    {
      create-instance
    }