
  do ->

    { get-attribute-type-manager } = dependency 'value.instance.Attribute'
    { create-notifier } = dependency 'value.instance.Notifier'
    { create-state } = dependency 'value.instance.State'
    { compose-with } = dependency 'value.component.Composition'
    { camel-case, capital-case } = dependency 'value.string.Case'
    { create-error-context } = dependency 'value.error.ErrorContext'
    { value-as-string } = dependency 'value.AsString'

    { context } = create-error-context 'value.instance.Instance'

    attribute-type-manager = get-attribute-type-manager!

    apply = (member-descriptor, member-type, name, instance) ->

      attribute-type-manager.apply-attributes member-descriptor.attributes, member-descriptor[member-type], member-type, name, instance

    create-instance = (member-descriptors) ->

      { argtype, arg-error } = context 'create-instance'

      argtype '<Object>' {member-descriptors}

      instance = {}

      for name, member-descriptor of member-descriptors

        WScript.Echo name, value-as-string member-descriptor

        argtype '<Object>' {member-descriptor}

        match member-descriptor

          | (.member isnt void) =>

            instance[ name ] = member-descriptor.member

          | (.method isnt void) =>

            instance[name] = apply member-descriptor, 'method', name, instance

          | (.state isnt void) =>

            WScript.Echo 'state'

            [ states, transitions, initial-state-name ] = member-descriptor.state

            state-machine = create-state states, transitions, initial-state-name

            WScript.Echo value-as-string state-machine

            instance `compose-with` [ state-machine ] # TODO: aft

          | (.notifier isnt void) =>

            notifier-instance = create-notifier member-descriptor.notifier
            instance `compose-with` [ notifier-instance.notifications ]
            instance[name] = notifier-instance

          | (.getter isnt void) or (.setter isnt void) =>

            if member-descriptor.getter isnt void
              getter = apply member-descriptor, 'getter', name, instance
              instance[name] = -> getter instance

            if member-descriptor.setter isnt void
              setter = apply member-descriptor, 'setter', name, instance
              instance["set#{ capital-case name }"] = (value) -> setter.call instance, value

          else

            WScript.Echo 'unknown member'

            throw arg-error {member-descriptor} "Unknown member descriptor type for '#name'. Expected member, method, notifier, getter, or setter."

      instance

    {
      create-instance
    }