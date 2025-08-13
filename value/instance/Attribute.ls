
  do ->

    { argument-type: argtype } = dependency 'value.reflection.Type'
    { object-member-names } = dependency 'value.Object'

    create-attribute-type-manager = ->

      WScript.Echo 'crea el attman'

      attribute-types = {}

      register-attribute-type = (attribute-name, handler) ->

        argtype '<String>' {attribute-name} ; argtype '<Function>' {handler}

        attribute-types[ attribute-name ] := handler

      apply-attributes = (attributes, member-value, member-type, member-name, instance, parameters) ->

        WScript.Echo attributes, member-value, member-type, member-name, instance, parameters

        argtype '[ *:Object ]' {attributes}

        transformed-value = member-value

        for attribute in attributes

          argtype '<Object>' {attribute}

          attribute-type-names = object-member-names attribute

          switch attribute-type-names.length

            | 0 => throw new Error "Empty attribute declaration"
            | 1 => attribute-type-name = attribute-type-names.0

            else throw new Error "Too many attributes in the same declaration" # TODO: improve

          parameters = attribute[attribute-type-name]

          attribute-type = attribute-types[attribute-type-name]

          if attribute-type isnt void

            transformed-value = attribute-type member-value, member-type, member-name, instance, parameters

          else

            throw new Error "Unknown attribute type '#attribute-type-name'"

        transformed-value

      { register-attribute-type, apply-attributes }

    attribute-type-manager = create-attribute-type-manager!

    get-attribute-type-manager = -> attribute-type-manager

    {
      get-attribute-type-manager
    }