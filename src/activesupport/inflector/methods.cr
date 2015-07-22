require "../inflections"

module ActiveSupport
  module Inflector
    extend self

    # Returns the plural form of the word in the string.
    #
    # If passed an optional +locale+ parameter, the word will be
    # pluralized using rules defined for that language. By default,
    # this parameter is set to <tt>:en</tt>.
    #
    #   pluralize("post")             # => "posts"
    #   pluralize("octopus")          # => "octopi"
    #   pluralize("sheep")            # => "sheep"
    #   pluralize("words")            # => "words"
    #   pluralize("CamelOctopus")     # => "CamelOctopi"
    #   pluralize("ley", :es)         # => "leyes"
    def pluralize(word, locale = :en)
      apply_inflections(word, inflections(locale).plurals)
    end

    # The reverse of #pluralize, returns the singular form of a word in a
    # string.
    #
    # If passed an optional +locale+ parameter, the word will be
    # singularized using rules defined for that language. By default,
    # this parameter is set to <tt>:en</tt>.
    #
    #   singularize('posts')            # => "post"
    #   singularize('octopi')           # => "octopus"
    #   singularize('sheep')            # => "sheep"
    #   singularize('word')             # => "word"
    #   singularize('CamelOctopi')      # => "CamelOctopus"
    #   singularize('leyes', :es)       # => "ley"
    def singularize(word, locale = :en)
      apply_inflections(word, inflections(locale).singulars)
    end

    # Converts strings to UpperCamelCase.
    # If the +uppercase_first_letter+ parameter is set to false, then produces
    # lowerCamelCase.
    #
    # Also converts "/" to "::" which is useful for converting
    # paths to namespaces.
    #
    #   camelize("active_model")                # => "ActiveModel"
    #   camelize("active_model", false)         # => "activeModel"
    #   camelize("active_model/errors")         # => "ActiveModel::Errors"
    #   camelize("active_model/errors", false)  # => "activeModel::Errors"
    #
    # As a rule of thumb you can think of +camelize+ as the inverse of
    # #underscore, though there are cases where that does not hold:
    #
    #   camelize(underscore("SSLError"))        # => "SslError"
    def camelize(term, uppercase_first_letter = true)
      string = term.to_s
      if uppercase_first_letter
        string = string.gsub(/^[a-z\d]*/) { |s| inflections.acronyms[s]? || s.capitalize }
      else
        string = string.gsub(/^(?:#{inflections.acronym_regex}(?=\b|[A-Z_])|\w)/) { |s| s.downcase }
      end
      string
        .gsub(/(?:_|(\/))([a-z\d]*)/i) { |s, m| "#{m[1]?}#{inflections.acronyms[m[2]]? || m[2].capitalize}" }
        .gsub("/", "::")
    end

    # Makes an underscored, lowercase form from the expression in the string.
    #
    # Changes "::" to "/" to convert namespaces to paths.
    #
    #   underscore("ActiveModel")         # => "active_model"
    #   underscore("ActiveModel::Errors") # => "active_model/errors"
    #
    # As a rule of thumb you can think of +underscore+ as the inverse of
    # #camelize, though there are cases where that does not hold:
    #
    #   camelize(underscore("SSLError"))  # => "SslError"
    def underscore(camel_cased_word)
      return camel_cased_word unless camel_cased_word =~ /[A-Z-]|::/

      camel_cased_word
        .to_s
        .gsub("::", "/")
        #.gsub(/(?:(?<=([A-Za-z\d]))|\b)(#{inflections.acronym_regex})(?=\b|[^a-z])/) { |s, matches| "#{matches[1] && "_"}#{matches[2].downcase}" }
        .gsub(/([A-Z\d]+)([A-Z][a-z])/) { |s, matches| "#{matches[1]}_#{matches[2]}"}
        .gsub(/([a-z\d])([A-Z])/) { |s, matches| "#{matches[1]}_#{matches[2]}"}
        .tr("-", "_")
        .downcase
    end

    # Tweaks an attribute name for display to end users.
    #
    # Specifically, performs these transformations:
    #
    # * Applies human inflection rules to the argument.
    # * Deletes leading underscores, if any.
    # * Removes a "_id" suffix if present.
    # * Replaces underscores with spaces, if any.
    # * Downcases all words except acronyms.
    # * Capitalizes the first word.
    #
    # The capitalization of the first word can be turned off by setting the
    # +:capitalize+ option to false (default is true).
    #
    #   humanize("employee_salary")              # => "Employee salary"
    #   humanize("author_id")                    # => "Author"
    #   humanize("author_id", capitalize: false) # => "author"
    #   humanize("_id")                          # => "Id"
    #
    # If "SSL" was defined to be an acronym:
    #
    #   humanize("ssl_error") # => "SSL error"
    #
    def humanize(lower_case_and_underscored_word, options = {} of Symbol => Bool)
      result = lower_case_and_underscored_word.to_s

      inflections.humans.each do |rule_and_replacement|
        rule, replacement = rule_and_replacement
        if result[rule]?
          result = result.gsub(rule, replacement)
          break
        end
      end

      result = result.gsub(/\A_+/, "").gsub(/_id\z/, "").tr("_", " ")

      result = result.gsub(/([a-z\d]*)/i) do |match|
        inflections.acronyms.fetch(match, match.downcase)
      end

      if options.fetch(:capitalize, true)
        result = result.gsub(/\A\w/) { |match| match.upcase }
      end

      result
    end

    # Creates a class name from a plural table name like Rails does for table
    # names to models. Note that this returns a string and not a Class (To
    # convert to an actual class follow +classify+ with #constantize).
    #
    #   classify("egg_and_hams") # => "EggAndHam"
    #   classify("posts")        # => "Post"
    #
    # Singular names are not handled correctly:
    #
    #   classify("calculus")     # => "Calculu"
    def classify(table_name)
      # strip out any leading schema name
      camelize(singularize(table_name.to_s.gsub(/.*\./, "")))
    end

    # Replaces underscores with dashes in the string.
    #
    #   dasherize("puni_puni") # => "puni-puni"
    def dasherize(underscored_word)
      underscored_word.tr("_", "-")
    end

    # Returns the suffix that should be added to a number to denote the position
    # in an ordered sequence such as 1st, 2nd, 3rd, 4th.
    #
    #   ordinal(1)     # => "st"
    #   ordinal(2)     # => "nd"
    #   ordinal(1002)  # => "nd"
    #   ordinal(1003)  # => "rd"
    #   ordinal(-11)   # => "th"
    #   ordinal(-1021) # => "st"
    def ordinal(number)
      abs_number = number.to_i.abs

      if (11..13).includes?(abs_number % 100)
        "th"
      else
        case abs_number % 10
          when 1; "st"
          when 2; "nd"
          when 3; "rd"
          else    "th"
        end
      end
    end

    # Turns a number into an ordinal string used to denote the position in an
    # ordered sequence such as 1st, 2nd, 3rd, 4th.
    #
    #   ordinalize(1)     # => "1st"
    #   ordinalize(2)     # => "2nd"
    #   ordinalize(1002)  # => "1002nd"
    #   ordinalize(1003)  # => "1003rd"
    #   ordinalize(-11)   # => "-11th"
    #   ordinalize(-1021) # => "-1021st"
    def ordinalize(number)
      "#{number}#{ordinal(number)}"
    end

    # Applies inflection rules for +singularize+ and +pluralize+.
    #
    #  apply_inflections("post", inflections.plurals)    # => "posts"
    #  apply_inflections("posts", inflections.singulars) # => "post"
    private def apply_inflections(word, rules)
      result = word.to_s

      return result if result.empty? || inflections.uncountables.includes?(result.downcase[/\b\w+\Z/])

      rules.each do |rule_and_replacement|
        rule, replacement = rule_and_replacement
        if result =~ rule
          result = result.gsub(rule) do |s, match|
            replacement = replacement.gsub("\\1", match[1]?)
            replacement = replacement.gsub("\\2", match[2]?)
            replacement
          end
          break
        end
      end

      result
    end
  end
end