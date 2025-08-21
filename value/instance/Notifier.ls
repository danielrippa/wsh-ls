do ->

    { create-error-context } = dependency 'value.error.ErrorContext'
    { array-item-indices } = dependency 'value.Array'
    { get-timestamp } = dependency 'value.Date'

    { context } = create-error-context 'value.instance.Notifier'

    create-subscription-id = -> "subscription-#{ get-timestamp! }"

    validate-notification-name = (notification-name, notification-names, arg-error) ->

      unless notification-name in notification-names
        throw arg-error {notification-name} "Valid notification names are: #{ notification-names * ', ' }"

    create-subscription = (name, handler, subscriptions, subscription-lookup) ->

      notification-name = name

      id = create-subscription-id!

      enabled = yes ; is-enabled = (-> enabled) ; enable = (-> enabled := yes) ; disable = (-> enabled := no)

      unsubscribe = ->

        delete subscriptions[notification-name][id]
        delete subscription-lookup[id]

      subscription = { id, handler, is-enabled, enable, disable, unsubscribe }

      subscriptions[notification-name][id] = subscription
      subscription-lookup[id] = { notification-name, subscription }

      subscription

    #

    create-notifier = (notification-names) ->

      { argtype, context: cn-context } = context 'create-notifier'

      argtype '[ *:String ]' {notification-names}

      subscriptions = { [ name, {} ] for name in notification-names }
      subscription-lookup = {}

      subscribe = (name, callback) ->

        { argtype, arg-error } = cn-context 'subscribe'

        argtype '<String>' {name} ; argtype '<Function>' {callback}

        notification-name = name

        validate-notification-name notification-name, notification-names, arg-error

        create-subscription notification-name, callback, subscriptions, subscription-lookup

      notify = (names, ...notification-args) ->

        { argtype, arg-error } = cn-context 'notify'

        argtype '[ *:String ]' {names}

        for name in names

          validate-notification-name name, notification-names, arg-error

          for subscription-id, subscription of subscriptions[name]

            if subscription.is-enabled!

              subscription.handler.apply null, notification-args

      # TODO: subscription-by-id friends must be DRY

      unsubscribe-by-id = (subscription-id) ->

        { argtype } = cn-context 'unsubscribe-by-id'

        argtype '<String>' {subscription-id}

        lookup = subscription-lookup[subscription-id]

        if lookup isnt void
          lookup.subscription.unsubscribe! ; return true

        false

      get-subscription-by-id = (subscription-id) ->

        { argtype } = cn-context 'get-subscription-by-id'

        lookup = subscription-lookup[subscription-id]

        if lookup isnt void
          lookup.subscription
        else
          null

      notifications = {}

      for name in notification-names

        notification-name = name

        notifications[ notification-name ] = do (notification-name = notification-name) ->

          (callback) ->

            argtype '<Function>' {callback}

            @subscribe notification-name, callback

      {
        subscribe, notifications, notify,
        unsubscribe-by-id, get-subscription-by-id
      }

    {
      create-notifier
    }