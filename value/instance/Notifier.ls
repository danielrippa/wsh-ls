
  do ->

    { create-error-context } = dependency 'value.error.ErrorContext'
    { array-items-are-unique } = dependency 'value.Array'
    { camel-case } = dependency 'value.string.Case'
    { get-timestamp } = dependency 'value.Date'

    { context } = create-error-context 'value.instance.Notifier'

    create-subscription-id = -> "subscription-#{ get-timestamp! }"

    validate-notification-names = (notification-names, argtype, arg-error) ->

      argtype '[ *:String ]' {notification-names} ; argtype '[ String ... ]' {notification-names}

      unless array-items-are-unique notification-names
        throw arg-error {notification-names} "Notification names must be unique."

    validate-notification-name = (name, notification-names, arg-error) ->

      notification-name = camelCase name

      is-valid = no

      for name in notification-names

        existing-notification-name = camel-case name

        if existing-notification-name is notification-name

          is-valid = yes ; continue

      unless is-valid
        throw arg-error {notification-name} "Invalid notification name '#notification-name'. Valid notification names are: #{ notification-names * ', ' }"

    create-subscription = (name, handler, subscriptions, subscription-lookup) ->

      notification-name = camel-case name

      id = create-subscription-id!

      enabled = yes ; is-enabled = (-> enabled) ; enable = (-> enabled := yes) ; disable = (-> enabled := no)

      unsubscribe = ->

        delete subscriptions[ notification-name ][id]
        delete subscription-lookup[id]

      subscription = { id, handler, is-enabled, enable, disable, unsubscribe }

      subscriptions[ notification-name ][id] = subscription
      subscription-lookup[id] = { notification-name, subscription }

      subscription

    create-notifier = (notification-names) ->

      { argtype, arg-error, context: cn-context } = context 'create-notifier'

      validate-notification-names notification-names, argtype, arg-error

      subscriptions = { [ (camel-case name), {} ] for name in notification-names }
      subscription-lookup = {}

      subscribe = (name, callback) ->

        { argtype, arg-error } = cn-context 'subscribe'

        argtype '<String>' {name} ; argtype '<Function>' {callback}

        notification-name = camel-case name

        validate-notification-name notification-name, notification-names, arg-error

        create-subscription notification-name, callback, subscriptions, subscription-lookup

      notify = (names, ...notification-args) ->

        { argtype, arg-error } = cn-context 'notify'

        argtype '[ *:String ]' {names}

        for name in names

          notification-name = camel-case name

          validate-notification-name notification-name, notification-names, arg-error

          for subscription-id, subscription of subscriptions[ notification-name ]

            if subscription.is-enabled!

              subscription.handler.apply null, notification-args

      unsubscribe-by-id = (subscription-id) ->

        { argtype } = cn-context 'unsubscribe-by-id'

        argtype '<String>' {subscription-id}

        lookup = subscription-lookup[ subscription-id ]

        if lookup isnt void
          lookup.subscription.unsubscribe! ; return yes

        no

      get-subscription-by-id = (subscription-id) ->

        { argtype } = cn-context 'get-subscription-by-id'

        lookup = subscription-lookup[ subscription-id ]

        if lookup isnt void
          lookup.subscription
        else
          null

      notifications = {}

      for notification-name in notification-names

        name = camel-case notification-name

        notifications[ name ] = do (notification-name = name) ->

          (callback) ->

            argtype '<Function>' {callback}

            subscribe notification-name, callback

      {
        notifications, notify,
        subscribe, unsubscribe-by-id, get-subscription-by-id
      }

    {
      create-notifier
    }