
  do ->

    { argument-type: argtype } = dependency 'value.reflection.Type'
    { create-argument-error: arg-error } = dependency 'value.ArgumentError'
    { camel-case } = dependency 'value.string.Case'
    { get-timestamp } = dependency 'value.Date'

    create-subscription-id = -> "subscription-#{ get-timestamp! }"

    create-subscription = (notification-name, handler, subscriptions, subscription-lookup) ->

      id = create-subscription-id!
      enabled = true ; is-enabled = (-> enabled) ; enable = (-> enabled := yes) ; disable = (-> enabled := no)

      unsubscribe = ->
        delete subscriptions[notification-name][id]
        delete subscription-lookup[id]

      subscription = { id, handler, is-enabled, enable, disable, unsubscribe }

      subscriptions[notification-name][id] = subscription
      subscription-lookup[id] = { notification-name, subscription }

      subscription

    create-notifier = (notification-names) ->

      argtype '[ *:String ]' {notification-names}

      subscriptions = { [ name, {} ] for name in notification-names }
      subscription-lookup = {}

      notifier =

        subscribe: (notification-name, callback) ->
          argtype '<String>' {notification-name} ; argtype '<Function>' {callback}

          unless notification-name in notification-names
            throw arg-error {notification-name} "Valid notification names: #{ notification-names * ', '}"

          create-subscription notification-name, callback, subscriptions, subscription-lookup

        notify: (names, ...notification-args) ->

          argtype '[ *:String ]' {names}

          for name in names

            unless name in notification-names
              throw arg-error {names} "Valid notification names: #{ notification-names * ', '}"

            for subscription-id, subscription of subscriptions[name]
              if subscription.is-enabled!

                subscription.handler.apply null, notification-args

        unsubscribe-by-id: (subscription-id) ->
          argtype '<String>' {subscription-id}

          lookup = subscription-lookup[subscription-id]

          if lookup isnt void
            lookup.subscription.unsubscribe! ; return true

          false

        get-subscription-by-id: (subscription-id) ->
          argtype '<String>' {subscription-id}

          lookup = subscription-lookup[subscription-id]

          if lookup isnt void
            lookup.subscription
          else
            null

      notifier.notifications = {}

      for name in notification-names
        notifier.notifications[ camel-case name ] = do (notification-name = name) ->
          (callback) -> notifier.subscribe notification-name, callback

      notifier

    {
      create-notifier
    }