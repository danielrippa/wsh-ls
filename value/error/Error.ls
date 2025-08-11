
  do ->

    { create-hresult } = dependency 'os.win32.com.HResult'
    { value-is-function: is-function, value-is-number: is-number } = dependency 'value.Type'

    create-error = (message, type = Error, error-code) ->

      return null unless is-function type ; return null unless (is-number error-code) or (error-code is void)

      message-string = "#message"

      match error-code

        | is-number => new type (create-hresult error-code), message-string

        else new type message-string

    {
      create-error
    }