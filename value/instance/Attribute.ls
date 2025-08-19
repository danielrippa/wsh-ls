
  do ->

    { object-member-names } = dependency 'value.Object'
    { create-error-context } = dependency 'value.error.ErrorContext'

    { context } = create-error-context 'value.instance.Attribute'

    create-attribute-type-manager = ->

      { context: atm-context } = context 'create-attribute-type-manager'

      attribute-types = {}
      disabled-attributes = {}

      register-attribute-type = (attribute-name, handler) ->

        { argtype } = atm-context 'register-attribute-type'

        argtype '<String>' {attribute-name} ; argtype '<Function>' {handler}

        attribute-types[ attribute-name ] := handler

      enable-attribute-type = (attribute-name) ->

        { argtype } = atm-context 'enable-attribute-type'

        argtype '<String>' {attribute-name}

        delete disabled-attributes[attribute-name]

      disable-attribute-type = (attribute-name) ->

        { argtype } = atm-context 'disable-attribute-type'

        argtype '<String>' {attribute-name}

        disabled-attributes[attribute-name] := true

      is-attribute-type-enabled = (attribute-name) ->

        { argtype } = atm-context 'is-attribute-type-enabled'

        argtype '<String>' {attribute-name}

        disabled-attributes[attribute-name] isnt true

      apply-attributes = (attributes, member-value, member-type, member-name, instance) ->

        { argtype, arg-error } = atm-context 'apply-attributes'

        argtype '<Array|Undefined>' {attributes} ; return member-value if attributes is void

        argtype '[ *:Object ]' {attributes}

        transformed-value = member-value

        for attribute in attributes

          argtype '<Object>' {attribute}

          attribute-type-names = object-member-names attribute

          attribute-type-name = switch attribute-type-names.length

            | 0 => throw arg-error {attributes} "Empty attribute declaration."
            | 1 => attribute-type-names.0

            else throw arg-error {attributes}, "Too many attributes in the same declaration."

          continue unless is-attribute-type-enabled attribute-type-name

          parameters = attribute[attribute-type-name]

          attribute-type = attribute-types[attribute-type-name]

          if attribute-type isnt void
            transformed-value = attribute-type transformed-value, member-type, member-name, instance, parameters
          else
            throw arg-error {attribute-type-name}, "Unknown attribute type '#attribute-type-name'."

        transformed-value

      { register-attribute-type, enable-attribute-type, disable-attribute-type, is-attribute-type-enabled, apply-attributes }

    attribute-type-manager = create-attribute-type-manager!

    get-attribute-type-manager = -> attribute-type-manager

    fn = (attributes, func) ->

      { argtype } = context 'fn'

      argtype '[ *:Object ]' {attributes} ; argtype '<Function>' {func}
      attribute-type-manager.apply-attributes attributes, func, 'method', 'function', null

    {
      get-attribute-type-manager, fn
    }