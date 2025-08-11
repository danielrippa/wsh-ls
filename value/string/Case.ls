
  do ->

    { create-regexp } = dependency 'value.string.RegExp'
    { punctuation-chars: { backslash } } = dependency 'value.string.Ascii'
    { code-unit-as-string: char } = dependency 'value.string.CodeUnit'

    lower-case = (.to-lower-case!)

    upper-case = (.to-upper-case!)

    #

    hyphen-or-underscore = '[-_]+'
    optional-single-char = '(.)?'

    find-separator = create-regexp "#hyphen-or-underscore#optional-single-char"

    remove-separator-capitalize-next-char = -> upper-case &1 ? ''

    camel-case = (.replace find-separator, remove-separator-capitalize-next-char)

    #

    neither-capital-nor-hyphen = '[^-A-Z]'
    capitals                   = '[A-Z]+'

    transition-before-capitals = create-regexp "(#neither-capital-nor-hyphen)(#capitals)"

    leading-capitals = create-regexp "^(#capitals)", ''

    format-word = (, lower, upper) -> "#{ lower }-#{ if upper.length > 1 then upper else lower-case upper }"

    format-leading-word = (, upper) -> if upper.length > 1 then "#upper-" else lower-case upper

    split-into-words = (.replace transition-before-capitals, format-word)

    replace-leading-word = (.replace leading-capitals, format-leading-word)

    kebab-case = -> it |> split-into-words |> replace-leading-word

    #

    slash = -> "#backslash#it"

    transition-from-non-word-to-word = slash 'b'
    each-word = slash 'w'

    initial-capitals = create-regexp "#transition-from-non-word-to-word#each-word"

    capital-case = -> it |> (.replace initial-capitals, upper-case)

    {
      lower-case, upper-case,
      camel-case, kebab-case,
      capital-case
    }