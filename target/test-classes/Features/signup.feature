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
    function(first_name, last_name, email, state, dob, phone, favorite_teams, heard_about_us, test_bypass) {
      var dynamicEmail = email == 'random' ? 'userexample' + random() + '@gmail.com' : email;
      var userData = {
        first_name: first_name,
        last_name: last_name,
        email: dynamicEmail,
        address: {
          state: state
        },
        dob: dob,
        phone: phone,
        favorite_teams: favorite_teams,
        heard_about_us: heard_about_us,
        test_bypass: test_bypass
      };
      return { dynamicEmail: dynamicEmail, userData: userData };
    }
    """

  @happy_path
  Scenario Outline: Sign-Up succeeds with valid data
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<state>', '<dob>', '<phone>', '<favorite_teams>', '<heard_about_us>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == <expectedStatus>
    * match response.data.signUp.message contains <expectedMessage>
    * if ("<email>" == "random" && response.data.signUp.statusCode == 200) karate.write({email: dynamicEmail, resetKey: response.data.signUp.temporarySignupKey, isVerified: false, passwordSet: false}, 'target/info.txt')

    Examples:
      Examples:
    | first_name | last_name | email  | state | dob        | phone        | favorite_teams | heard_about_us | expectedStatus | expectedMessage |
    | User       | Example   | random | NY    | 1999-05-14 | +14191000000 | ["DAL"]        | Google         | 200            | 'Signup successful. Please verify your email and set your password in the app.' |

  @missing_first_name
  Scenario Outline: Sign-Up fails when first name missing
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<state>', '<dob>', '<phone>', '<favorite_teams>', '<heard_about_us>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | first_name | last_name | email                 | state | dob        | phone        | favorite_teams | heard_about_us | expectedStatus | expectedMessage            |
      |            | Example   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | ["DAL"]        | Google         | 400        | 'Missing required fields!' |

  @missing_last_name
  Scenario Outline: Sign-Up fails when last name missing
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<state>', '<dob>', '<phone>', '<favorite_teams>', '<heard_about_us>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | first_name | last_name | email                 | state | dob        | phone        | favorite_teams | heard_about_us | expectedStatus | expectedMessage            |
      | User       |           | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | ["DAL"]        | Google         | 400        | 'Missing required fields!' |

  @missing_email
  Scenario Outline: Sign-Up fails when email missing
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<state>', '<dob>', '<phone>', '<favorite_teams>', '<heard_about_us>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | first_name | last_name | email | state | dob        | phone        | favorite_teams | heard_about_us  | expectedStatus | expectedMessage            |
      | User       | Example   |       | NY    | 1999-05-14 | +14191000000 | ["DAL"]        | Google          | 400            | 'Missing required fields!' |

  @missing_state
  Scenario Outline: Sign-Up fails when state missing
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<state>', '<dob>', '<phone>', '<favorite_teams>', '<heard_about_us>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | first_name | last_name | email                  | state | dob        | phone        | favorite_teams | heard_about_us | expectedStatus | expectedMessage            |
      | User       | Example   | userexample9@gmail.com |       | 1999-05-14 | +14191000000 | ["DAL"]        | Google        | 400            | 'State is required.' |

  @missing_dob
  Scenario Outline: Sign-Up fails when date of birth missing
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<state>', '<dob>', '<phone>', '<favorite_teams>', '<heard_about_us>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | first_name | last_name | email                 | state | dob | phone        | favorite_teams | heard_about_us | expectedStatus | expectedMessage            |
      | User       | Example   | userexample9@gmail.com | NY    |     | +14191000000 | ["DAL"]        | Google         | 400            | 'Missing required fields!' |

  @missing_heard_about_us
  Scenario Outline: Missing heard_about_us
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<state>', '<dob>', '<phone>', <favorite_teams>, '<heard_about_us>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | first_name | last_name | email  | state | dob        | phone        | favorite_teams | heard_about_us | expectedStatus | expectedMessage            |
      | User       | Example   | random | NY    | 1999-05-14 | +14191000000 | ["DAL"]        |                | 400            | 'Missing required fields!' |

  @missing_favorite_teams
  Scenario Outline: Missing favorite_teams
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<state>', '<dob>', '<phone>', <favorite_teams>, '<heard_about_us>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>


    Examples:
      | first_name | last_name | email  | state | dob        | phone        | favorite_teams | heard_about_us | expectedStatus | expectedMessage            |
      | User       | Example   | random | NY    | 1999-05-14 | +14191000000 | []        | "Google"            | 400            | 'Select at least one favorite team' |

  @invalid_state
  Scenario Outline: Sign-Up fails when state missing
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<state>', '<dob>', '<phone>', '<favorite_teams>', '<heard_about_us>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | first_name | last_name | email                  | state | dob        | phone        | favorite_teams | heard_about_us | expectedStatus | expectedMessage            |
      | User       | Example   | userexample9@gmail.com | "abc" | 1999-05-14 | +14191000000 | ["DAL"]        | Google        | 400            | 'Invalid U.S. state. Must be a valid state name or abbreviation.' |
      | User       | Example   | userexample9@gmail.com | 123 | 1999-05-14 | +14191000000 | ["DAL"]        | Google        | 400            | 'Invalid U.S. state. Must be a valid state name or abbreviation.' |
      | User       | Example   | userexample9@gmail.com | "Puerto Rico" | 1999-05-14 | +14191000000 | ["DAL"]        | Google        | 400            | 'Invalid U.S. state. Must be a valid state name or abbreviation.' |

  @invalid_heard_about_us
  Scenario Outline: Invalid heard_about_us value
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<state>', '<dob>', '<phone>', <favorite_teams>, '<heard_about_us>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200

    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | first_name | last_name | email  | state | dob        | phone        | favorite_teams | heard_about_us | expectedStatus | expectedMessage
      | User       | Example   | random | NY    | 1999-05-14 | +14191000000 | ["DAL"]        | 123        | 400            | 'Invalid heard_about_us value' |
  
  @invalid_first_name
  Scenario Outline: Sign-Up fails when first name invalid
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<state>', '<dob>', '<phone>', '<favorite_teams>', '<heard_about_us>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | first_name | last_name | email                 | state | dob        | phone        | favorite_teams | heard_about_us | expectedStatus | expectedMessage                                                                 |
      | -          | -         | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | ["DAL"]        | Google         | 400            | 'Invalid first name!' |

  @invalid_email_format
  Scenario Outline: Sign-Up fails when email format invalid
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<state>', '<dob>', '<phone>', '<favorite_teams>', '<heard_about_us>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | first_name | last_name | email | state | dob        | phone        | favorite_teams | heard_about_us | expectedStatus | expectedMessage         |
      | User       | Example   | a@b   | NY    | 1999-05-14 | +14191000000 | ["DAL"]        | Google         | 400            | 'Invalid email format!' |

  @invalid_phone
  Scenario Outline: Sign-Up fails when phone number invalid
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<state>', '<dob>', '<phone>', '<favorite_teams>', '<heard_about_us>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | first_name | last_name | email                 | state | dob        | phone    | favorite_teams | heard_about_us | expectedStatus | expectedMessage                 |
      | User       | Example   | userexample9@gmail.com | NY    | 1999-05-14 | +14191   | ["DAL"]        | Google         | 400            | 'Invalid phone number format!' |

  @invalid_date_format
  Scenario Outline: Sign-Up fails when date format invalid
    * def build = buildSignUpData('<first_name>', '<last_name>', '<email>', '<state>', '<dob>', '<phone>', '<favorite_teams>', '<heard_about_us>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | first_name | last_name | email                 | state | dob        | phone        | favorite_teams | heard_about_us | expectedStatus | expectedMessage                                         |
      | User       | Example   | userexample9@gmail.com | NY    | 1999/05/14 | +14191000000 | ["DAL"]        | Google         | 400            | 'Invalid date format!'       |

  @unverified_email_exists
  Scenario Outline: Sign-Up fails when unverified email already exists
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingEmail = signUpInfo.email
    
    * def build = buildSignUpData('<first_name>', '<last_name>', existingEmail, '<state>', '<dob>', '<phone>', '<favorite_teams>', '<heard_about_us>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | first_name | last_name | email         | state | dob        | phone        | favorite_teams | heard_about_us | expectedStatus | expectedMessage                             |
      | User       | Example   | existingEmail | NY    | 1999-05-14 | +14191000000 | ["DAL"]        | Google         | 403           | 'Activation email already sent. Please check your inbox.'          |
