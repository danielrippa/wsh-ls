
  do ->

    regexp-flags = global: 'g'

    create-regexp = (expression, flags = regexp-flags.global) -> new RegExp expression, flags

    {
      regexp-flags,
      create-regexp
    }