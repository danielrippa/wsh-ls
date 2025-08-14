
  do ->

    { argument-type: argtype } = dependency 'value.reflection.Type'
    { create-argument-error: arg-error } = dependency 'value.ArgumentError'
    { object-member-names } = dependency 'value.Object'

    create-attribute-type-manager = ->

      attribute-types = {}
      disabled-attributes = {}

      register-attribute-type = (attribute-name, handler) ->

        argtype '<String>' {attribute-name} ; argtype '<Function>' {handler}

        attribute-types[ attribute-name ] := handler

      enable-attribute-type = (attribute-name) ->

        argtype '<String>' {attribute-name}

        delete disabled-attributes[attribute-name]

      disable-attribute-type = (attribute-name) ->

        argtype '<String>' {attribute-name}

        disabled-attributes[attribute-name] := true

      is-attribute-type-enabled = (attribute-name) ->

        argtype '<String>' {attribute-name}

        disabled-attributes[attribute-name] isnt true

      apply-attributes = (attributes, member-value, member-type, member-name, instance) ->

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

      argtype '[ *:Object ]' {attributes} ; argtype '<Function>' {func}
      attribute-type-manager.apply-attributes attributes, func, 'method', 'function', null

    {
      get-attribute-type-manager, fn
    }