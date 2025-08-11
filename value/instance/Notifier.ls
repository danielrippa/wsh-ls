
  do ->

    { type } = dependency 'value.reflection.Type'
    { camel-case } = dependency 'value.string.Case'
    { get-timestamp } = dependency 'value.Date'

    create-subscription-id = -> "subscription-#{ get-timestamp! }"

    create-subscription = (notification-name, handler, subscriptions, subscription-lookup) ->

      id = create-subscription-id!
      enabled = true ; is-enabled = (-> enabled) ; enable = (-> enabled := yes) ; disable = (-> enabled := no)

      unsubscribe = ->
        delete subscriptions[notification-name][subscription-id]
        delete subscription-lookup[subscription-id]

      subscription = { id, handler, is-enabled, enable, disable, unsubscribe }

      subscriptions[notification-name][subscription-id] = subscription
      subscription-lookup[subscription-id] = { notification-name, subscription }

      subscription

    create-notifier = (notification-names) ->

      type '[ *:String ]' notification-names

      subscriptions = { [ name, {} ] for name in notification-names }
      subscription-lookup = {}

      notifier =

        subscribe: (notification-name, callback) ->
          argtype '<String>' {notification-name} ; argtype '<Function>' callback

          unless notification-name in notification-names
            throw new Error "Invalid notification name: #{notification-name}. Valid names: #{notification-names.join ', '}"

          create-subscription notification-name, callback, subscriptions, subscription-lookup

        notify: (names, ...notification-args) ->

          argtype '[ *:String ]' names

          for name in names

            unless name in notification-names
              throw new Error "Invalid notification name: #{name}. Valid names: #{notification-names.join ', '}"

            for subscription-id, subscription of subscriptions[name]
              if subscription.enabled!
                subscription.handler notification

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

      notifier.events = {}

      for name in notification-names
        notifier.events[ camel-case name ] = do (notification-name = name) ->
          (callback) -> notifier.subscribe notification-name, callback

      notifier

    {
      create-notifier
    }