
  do ->

    { argument-type: argtype } = dependency 'value.reflection.Type'
    { get-attribute-type-manager } = dependency 'value.instance.Attribute'
    { create-notifier } = dependency 'value.instance.Notifier'
    { create-state } = dependency 'value.instance.State'
    { compose-with } = dependency 'value.instance.Composition'
    { camel-case, capital-case } = dependency 'value.string.Case'

    attribute-type-manager = get-attribute-type-manager!

    apply = (member-descriptor, member-type, name, instance) ->

      attribute-type-manager.apply-attributes member-descriptor.attributes, member-descriptor[member-type], member-type, name, instance

    create-instance = (member-descriptors) ->

      argtype '<Object>' {member-descriptors}

      instance = {} ; notifiers = {}

      for name, member-descriptor of member-descriptors

        argtype '<Object>' {member-descriptor}

        match member-descriptor

          | (.member isnt void) =>

            instance[ name ] = member-descriptor.member

          | (.method isnt void) =>

            instance[name] = apply member-descriptor, 'method', name, instance

          | (.notifier isnt void) =>

            notifier-instance = create-notifier member-descriptor.notifier
            instance `compose-with` [ notifier-instance, <[ notify subscribe ]> ]
            notifiers[name] = notifier-instance

          | (.getter isnt void) or (.setter isnt void) =>

            if member-descriptor.getter isnt void
              getter = apply member-descriptor, 'getter', name, instance
              instance[name] = -> getter instance

            if member-descriptor.setter isnt void
              setter = apply member-descriptor, 'setter', name, instance
              instance["set#{ capital-case name }"] = (value) -> setter.call instance, value

          else # TODO

      instance

    {
      create-instance
    }