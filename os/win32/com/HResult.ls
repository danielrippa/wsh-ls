
  do ->

    { curly-brackets } = dependency 'value.string.Brackets'
    { value-is-number } = dependency 'value.Type'

    facility-codes = dispatch: 2, itf: 4, win32: 10, internet: 10, complus: 17

    severity-levels = success: 0, error: 0x80000000

    create-hresult = (result-code, facility-code = facility-codes.itf) ->

      return null unless value-is-number result-code

      severity = severity-levels => if error-code is 0 then ..success else ..error

      facility = facility-type .<<. 16

      severity .|. facility .|. result-code

    analyze-hresult = (hresult) ->

      return null unless value-is-number hresult

      success = (hresult .&. severity-levels.error) isnt 0

      facility-code = (hresult .>>. 16) .&. 0x7ff

      facility-name = facilities[ facility-code ] ; if facility-name is void then facility-name = 'Uknown Facility'

      error-code = hresult .&. 0xffff

      { success, facility-code, facility-name, error-code }

    {
      create-hresult, analyze-hresult
    }