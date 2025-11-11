Feature: Sign-Up API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def signUpQuery = read('classpath:resources/graphql/signup.graphql')
    * def random = function() { return java.lang.Math.floor(java.lang.Math.random() * 100000); }
    * def buildSignUpData =
      """
      function(first_name, last_name, email, street, suite, city, state, postal_code, dob, phone, test_bypass) {
        var dynamicEmail = email == 'random' ? 'userexample' + random() + '@gmail.com' : email;
        var userData = {
          first_name: first_name,
          last_name: last_name,
          email: dynamicEmail,
          address: {
            street: street,
            suite: suite,
            city: city,
            state: state,
            postal_code: postal_code
          },
          dob: dob,
          phone: phone,
          test_bypass: test_bypass
        };
        return { dynamicEmail: dynamicEmail, userData: userData };
      }
      """

  @happy_path
  Scenario Outline: Sign-Up succeeds with valid data
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<street>', '<suite>', '<city>', '<state>', '<postal_code>', '<dob>', '<phone>', <test_bypass>)
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == <expectedStatus>
    * match response.data.signUp.message contains <expectedMessage>
    * if ("<email>" == "random" && response.data.signUp.statusCode == 200) karate.write(dynamicEmail, 'target/email.txt')

    Examples:
      | first_name | last_name | email  | street          | suite | city     | state | postal_code | dob        | phone        | test_bypass | expectedStatus | expectedMessage                                                                  |
      | User       | Example   | random | 123 Main Street | 3A    | New York | NY    | 103044      | 1999-05-14 | +14191000000 | true        | 200            | 'Signup successful. Please check your email to set your password.'             |

  @duplicate_email
  Scenario Outline: Sign-Up rejects duplicate email
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<street>', '<suite>', '<city>', '<state>', '<postal_code>', '<dob>', '<phone>', <test_bypass>)
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == <expectedStatus>
    * match response.data.signUp.message contains <expectedMessage>
    * if ("<email>" == "random" && response.data.signUp.statusCode == 200) karate.write(dynamicEmail, 'target/email.txt')

    Examples:
      | first_name | last_name | email                 | street          | suite | city     | state | postal_code | dob        | phone        | test_bypass | expectedStatus | expectedMessage            |
      | User       | Example   | userexample9@gmail.com | 123 Main Street | 3A    | New York | NY    | 103044      | 1999-05-14 | +14191000000 | true        | 409            | 'Email already exists!'    |

  @missing_first_name
  Scenario Outline: Sign-Up fails when first name missing
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<street>', '<suite>', '<city>', '<state>', '<postal_code>', '<dob>', '<phone>', <test_bypass>)
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == <expectedStatus>
    * match response.data.signUp.message contains <expectedMessage>
    * if ("<email>" == "random" && response.data.signUp.statusCode == 200) karate.write(dynamicEmail, 'target/email.txt')

    Examples:
      | first_name | last_name | email                 | street          | suite | city     | state | postal_code | dob        | phone        | test_bypass | expectedStatus | expectedMessage            |
      |            | Example   | userexample9@gmail.com | 123 Main Street | 3A    | New York | NY    | 103044      | 1999-05-14 | +14191000000 | true        | 400            | 'Missing required fields!' |

  @missing_last_name
  Scenario Outline: Sign-Up fails when last name missing
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<street>', '<suite>', '<city>', '<state>', '<postal_code>', '<dob>', '<phone>', <test_bypass>)
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == <expectedStatus>
    * match response.data.signUp.message contains <expectedMessage>
    * if ("<email>" == "random" && response.data.signUp.statusCode == 200) karate.write(dynamicEmail, 'target/email.txt')

    Examples:
      | first_name | last_name | email                 | street          | suite | city     | state | postal_code | dob        | phone        | test_bypass | expectedStatus | expectedMessage            |
      | User       |           | userexample9@gmail.com | 123 Main Street | 3A    | New York | NY    | 103044      | 1999-05-14 | +14191000000 | true        | 400            | 'Missing required fields!' |

  @missing_email
  Scenario Outline: Sign-Up fails when email missing
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<street>', '<suite>', '<city>', '<state>', '<postal_code>', '<dob>', '<phone>', <test_bypass>)
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == <expectedStatus>
    * match response.data.signUp.message contains <expectedMessage>
    * if ("<email>" == "random" && response.data.signUp.statusCode == 200) karate.write(dynamicEmail, 'target/email.txt')

    Examples:
      | first_name | last_name | email | street          | suite | city     | state | postal_code | dob        | phone        | test_bypass | expectedStatus | expectedMessage            |
      | User       | Example   |       | 123 Main Street | 3A    | New York | NY    | 103044      | 1999-05-14 | +14191000000 | true        | 400            | 'Missing required fields!' |

  @missing_street
  Scenario Outline: Sign-Up fails when street missing
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<street>', '<suite>', '<city>', '<state>', '<postal_code>', '<dob>', '<phone>', <test_bypass>)
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == <expectedStatus>
    * match response.data.signUp.message contains <expectedMessage>
    * if ("<email>" == "random" && response.data.signUp.statusCode == 200) karate.write(dynamicEmail, 'target/email.txt')

    Examples:
      | first_name | last_name | email                 | street | suite | city     | state | postal_code | dob        | phone        | test_bypass | expectedStatus | expectedMessage            |
      | User       | Example   | userexample9@gmail.com |        | 3A    | New York | NY    | 103044      | 1999-05-14 | +14191000000 | true        | 400            | 'Missing required fields!' |

  @missing_dob
  Scenario Outline: Sign-Up fails when date of birth missing
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<street>', '<suite>', '<city>', '<state>', '<postal_code>', '<dob>', '<phone>', <test_bypass>)
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == <expectedStatus>
    * match response.data.signUp.message contains <expectedMessage>
    * if ("<email>" == "random" && response.data.signUp.statusCode == 200) karate.write(dynamicEmail, 'target/email.txt')

    Examples:
      | first_name | last_name | email                 | street          | suite | city     | state | postal_code | dob | phone        | test_bypass | expectedStatus | expectedMessage            |
      | User       | Example   | userexample9@gmail.com | 123 Main Street | 3A    | New York | NY    | 103044      |     | +14191000000 | true        | 400            | 'Missing required fields!' |

  @invalid_first_name
  Scenario Outline: Sign-Up fails when first name invalid
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<street>', '<suite>', '<city>', '<state>', '<postal_code>', '<dob>', '<phone>', <test_bypass>)
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == <expectedStatus>
    * match response.data.signUp.message contains <expectedMessage>
    * if ("<email>" == "random" && response.data.signUp.statusCode == 200) karate.write(dynamicEmail, 'target/email.txt')

    Examples:
      | first_name | last_name | email                 | street          | suite | city     | state | postal_code | dob        | phone        | test_bypass | expectedStatus | expectedMessage                                                                 |
      | -          | -         | userexample9@gmail.com | 123 Main Street | 3A    | New York | NY    | 103044      | 1999-05-14 | +14191000000 | true        | 400            | 'Invalid first name! Must contain at least 2 letters and may include spaces or hyphens.' |

  @invalid_email_format
  Scenario Outline: Sign-Up fails when email format invalid
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<street>', '<suite>', '<city>', '<state>', '<postal_code>', '<dob>', '<phone>', <test_bypass>)
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == <expectedStatus>
    * match response.data.signUp.message contains <expectedMessage>
    * if ("<email>" == "random" && response.data.signUp.statusCode == 200) karate.write(dynamicEmail, 'target/email.txt')

    Examples:
      | first_name | last_name | email | street          | suite | city     | state | postal_code | dob        | phone        | test_bypass | expectedStatus | expectedMessage         |
      | User       | Example   | a@b   | 123 Main Street | 3A    | New York | NY    | 103044      | 1999-05-14 | +14191000000 | true        | 400            | 'Invalid email format!' |

  @invalid_phone
  Scenario Outline: Sign-Up fails when phone number invalid
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<street>', '<suite>', '<city>', '<state>', '<postal_code>', '<dob>', '<phone>', <test_bypass>)
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == <expectedStatus>
    * match response.data.signUp.message contains <expectedMessage>
    * if ("<email>" == "random" && response.data.signUp.statusCode == 200) karate.write(dynamicEmail, 'target/email.txt')

    Examples:
      | first_name | last_name | email                 | street          | suite | city     | state | postal_code | dob        | phone    | test_bypass | expectedStatus | expectedMessage                 |
      | User       | Example   | userexample9@gmail.com | 123 Main Street | 3A    | New York | NY    | 103044      | 1999-05-14 | +14191   | true        | 400            | 'Invalid phone number format!' |

  @invalid_postal_code
  Scenario Outline: Sign-Up fails when postal code invalid
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<street>', '<suite>', '<city>', '<state>', '<postal_code>', '<dob>', '<phone>', <test_bypass>)
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == <expectedStatus>
    * match response.data.signUp.message contains <expectedMessage>
    * if ("<email>" == "random" && response.data.signUp.statusCode == 200) karate.write(dynamicEmail, 'target/email.txt')

    Examples:
      | first_name | last_name | email                 | street          | suite | city     | state | postal_code | dob        | phone        | test_bypass | expectedStatus | expectedMessage         |
      | User       | Example   | userexample9@gmail.com | 123 Main Street | 3A    | New York | NY    | abc         | 1999-05-14 | +14191000000 | true        | 400            | 'Invalid postal code!'  |

  @invalid_date_format
  Scenario Outline: Sign-Up fails when date format invalid
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<street>', '<suite>', '<city>', '<state>', '<postal_code>', '<dob>', '<phone>', <test_bypass>)
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == <expectedStatus>
    * match response.data.signUp.message contains <expectedMessage>
    * if ("<email>" == "random" && response.data.signUp.statusCode == 200) karate.write(dynamicEmail, 'target/email.txt')

    Examples:
      | first_name | last_name | email                 | street          | suite | city     | state | postal_code | dob        | phone        | test_bypass | expectedStatus | expectedMessage                                         |
      | User       | Example   | userexample9@gmail.com | 123 Main Street | 3A    | New York | NY    | 103044      | 1999/05/14 | +14191000000 | true        | 400            | 'Invalid date format! Expected YYYY-MM-DD format'       |

  @invalid_city
  Scenario Outline: Sign-Up fails when city invalid
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<street>', '<suite>', '<city>', '<state>', '<postal_code>', '<dob>', '<phone>', <test_bypass>)
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == <expectedStatus>
    * match response.data.signUp.message contains <expectedMessage>
    * if ("<email>" == "random" && response.data.signUp.statusCode == 200) karate.write(dynamicEmail, 'target/email.txt')

    Examples:
      | first_name | last_name | email                 | street          | suite | city  | state | postal_code | dob        | phone        | test_bypass | expectedStatus | expectedMessage                                                              |
      | User       | Example   | userexample9@gmail.com | 123 Main Street | 3A    | 12345 | NY    | 103044      | 1999-05-14 | +14191000000 | true        | 400            | 'Invalid city! Only alphabetic characters, spaces, and hyphens are allowed.' |
