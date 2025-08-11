
  do ->

    { argument-type: argtype } = dependency 'value.reflection.Argument'

    create-attribute-type-manager = ->

      attribute-types = {}

      register-attribute-type = (attribute-name, handler) ->

        argtype '<String>' {attribute-name} ; argtype '<Function>' {handler}

        attribute-types[ attribute-name ] := handler

      apply-attributes = (attributes, member-value, member-type, member-name, instance) ->

        transformed-value = member-value

        for attr-name, attr-spec of attributes

          transformer = attribute-types[attr-name]

          if transformer isnt void
            transformed-value = transformer transformed-value, member-type, member-name, instance, parameters
          else
            throw new Error "Unknown attribute type: #attr-name."

        transformed-value

    {
      create-attribute-type-manager
    }