Feature: Sign-Up API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def signUpQuery = read('classpath:graphql/auth/signup.graphql')
    * def random = function() { return java.lang.Math.floor(java.lang.Math.random() * 100000); }
    * def buildSignUpData =
    """
    function(first_name, last_name, username, email, state, dob, phone, heard_about_us, profile_picture, test_bypass) {
      var dynamicEmail = email == 'random' ? 'userexample' + random() + '@gmail.com' : email;
      var dynamicUsername = username == 'random' ? String.fromCharCode(97 + Math.floor(Math.random() * 26)) + random() : username;
      var userData = {
        first_name: first_name,
        last_name: last_name,
        username: dynamicUsername,
        email: dynamicEmail,
        address: {
          state: state
        },
        dob: dob,
        phone: phone,
        heard_about_us: heard_about_us,
        profile_picture: profile_picture,
        test_bypass: test_bypass
      };
      return { dynamicEmail: dynamicEmail, dynamicUsername: dynamicUsername, userData: userData };
    }
    """

  @happy_path
  Scenario Outline: Sign-Up succeeds with valid data
    * def build = buildSignUpData('<first_name>', '<last_name>', '<username>', '<email>', '<state>', '<dob>', '<phone>', '<heard_about_us>', '<profile_picture>')
    * def dynamicEmail = build.dynamicEmail
    * def dynamicUsername = build.dynamicUsername
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == <expectedStatus>
    * match response.data.signUp.message contains <expectedMessage>
    * if ("<email>" == "random" && response.data.signUp.statusCode == 200) karate.write({email: dynamicEmail, username: dynamicUsername, resetKey: response.data.signUp.temporarySignupKey, isVerified: false, passwordSet: false}, 'target/info.txt')

    Examples:
      Examples:
    | first_name | last_name | username | email  | state | dob        | phone        | heard_about_us | profile_picture | expectedStatus | expectedMessage                                                                 |
    | J A        | Michael   | random   | random | TX    | 1990-05-21 | +19319332    | Google         | icon_bear       | 200            | 'Signup successful. Please verify your email and set your password in the app.' |

  @missing_first_name
  Scenario Outline: Sign-Up fails when first_name missing
    * def build = buildSignUpData('<first_name>', '<last_name>', '<username>', '<email>', '<state>', '<dob>', '<phone>', '<heard_about_us>', '<profile_picture>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | first_name | last_name | username | email                  | state | dob        | phone        | heard_about_us | profile_picture | expectedStatus | expectedMessage          | expectedErrorCode   |
      |            | Doe       | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | First name is required!  | FIRST_NAME_REQUIRED |

  @missing_email
  Scenario Outline: Sign-Up fails when email missing
    * def build = buildSignUpData('<first_name>', '<last_name>', '<username>', '<email>', '<state>', '<dob>', '<phone>', '<heard_about_us>', '<profile_picture>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | first_name | last_name | username | email | state | dob        | phone        | heard_about_us | profile_picture | expectedStatus | expectedMessage      | expectedErrorCode   |
      | User       | Doe       | random   |       | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Email is required!   | EMAIL_REQUIRED      |

  @missing_state
  Scenario Outline: Sign-Up fails when state missing
    * def build = buildSignUpData('<first_name>', '<last_name>', '<username>', '<email>', '<state>', '<dob>', '<phone>', '<heard_about_us>', '<profile_picture>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | first_name | last_name | username | email                  | state | dob        | phone        | heard_about_us | profile_picture | expectedStatus | expectedMessage    |  expectedErrorCode   |
      | User       | Doe       | random   | userexample9@gmail.com |       | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | State is required. |  STATE_REQUIRED      |

  @missing_dob
  Scenario Outline: Sign-Up fails when date of birth missing
    * def build = buildSignUpData('<first_name>', '<last_name>', '<username>', '<email>', '<state>', '<dob>', '<phone>', '<heard_about_us>', '<profile_picture>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | first_name | last_name | username | email                  | state | dob | phone        | heard_about_us | profile_picture | expectedStatus | expectedMessage            | expectedErrorCode       |
      | User       | Doe       | testuser | userexample9@gmail.com | NY    |     | +14191000000 | Google         | icon_bear       | 400            | Date of birth is required! | DATE_OF_BIRTH_REQUIRED  |

  @invalid_state
  Scenario Outline: Sign-Up fails when state invalid
    * def build = buildSignUpData('<first_name>', '<last_name>', '<username>', '<email>', '<state>', '<dob>', '<phone>', '<heard_about_us>', '<profile_picture>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | first_name | last_name | username | email                  | state         | dob        | phone        | heard_about_us | profile_picture | expectedStatus | expectedMessage                                                  | expectedErrorCode    |
      | User       | Doe       | random   | userexample9@gmail.com | "abc"         | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid U.S. state. Must be a valid state name or abbreviation.  | INVALID_STATE        |
      | User       | Doe       | random   | userexample9@gmail.com | 123           | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid U.S. state. Must be a valid state name or abbreviation.  | INVALID_STATE        |
      | User       | Doe       | random   | userexample9@gmail.com | "Puerto Rico" | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid U.S. state. Must be a valid state name or abbreviation.  | INVALID_STATE        |

  @invalid_heard_about_us
  Scenario Outline: Invalid heard_about_us value
    * def build = buildSignUpData('<first_name>', '<last_name>', '<username>', '<email>', '<state>', '<dob>', '<phone>', '<heard_about_us>', '<profile_picture>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | first_name | last_name | username | email  | state | dob        | phone        | heard_about_us | profile_picture | expectedStatus | expectedMessage              |  expectedErrorCode       |
      | User       | Doe       | random   | random | NY    | 1999-05-14 | +14191000000 | 123            | icon_bear       | 400            | Invalid heard_about_us value |  INVALID_HEARD_ABOUT_US  |

  @missing_last_name
  Scenario Outline: Sign-Up fails when last_name missing
    * def build = buildSignUpData('<first_name>', '<last_name>', '<username>', '<email>', '<state>', '<dob>', '<phone>', '<heard_about_us>', '<profile_picture>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | first_name | last_name | username | email                  | state | dob        | phone        | heard_about_us | profile_picture | expectedStatus | expectedMessage        | expectedErrorCode   |
      | John       |           | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Last name is required! | LAST_NAME_REQUIRED  |

  @missing_username
  Scenario Outline: Sign-Up fails when username missing
    * def build = buildSignUpData('<first_name>', '<last_name>', '<username>', '<email>', '<state>', '<dob>', '<phone>', '<heard_about_us>', '<profile_picture>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | first_name | last_name | username | email                  | state | dob        | phone        | heard_about_us | profile_picture | expectedStatus | expectedMessage       | expectedErrorCode   |
      | John       | Doe       |          | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Username is required! | USERNAME_REQUIRED   |

  @invalid_first_name
  Scenario Outline: Sign-Up fails when first_name invalid
    * def build = buildSignUpData('<first_name>', '<last_name>', '<username>', '<email>', '<state>', '<dob>', '<phone>', '<heard_about_us>', '<profile_picture>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | first_name                                              | last_name | username | email                  | state | dob        | phone        | heard_about_us | profile_picture | expectedStatus | expectedMessage                                                                           | expectedErrorCode     | 
      | --                                                      | Doe       | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | First name must contain at least one letter.                                              | FIRST_NAME_NO_LETTER  |
      | 12345                                                   | Doe       | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid first name! First name can only contain letters, spaces, hyphens or apostrophes.  | INVALID_FIRST_NAME    |
      | user123                                                 | Doe       | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid first name! First name can only contain letters, spaces, hyphens or apostrophes.  | INVALID_FIRST_NAME    |
      | A@                                                      | Doe       | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid first name! First name can only contain letters, spaces, hyphens or apostrophes.  | INVALID_FIRST_NAME    |
      | B!                                                      | Doe       | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid first name! First name can only contain letters, spaces, hyphens or apostrophes.  | INVALID_FIRST_NAME    |
      | Itisaverylongfirstnameofusertobeenteredinsignuppayl     | Doe       | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | First name cannot be more than 50 characters                                              | FIRST_NAME_TOO_LONG   |
      | Itisaverylongfirstnameofusertobeenteredinsignuppayload  | Doe       | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | First name cannot be more than 50 characters                                              | FIRST_NAME_TOO_LONG   |
      | !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!   | Doe       | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid first name! First name can only contain letters, spaces, hyphens or apostrophes.  | INVALID_FIRST_NAME    |

  @invalid_last_name
  Scenario Outline: Sign-Up fails when last_name invalid
    * def build = buildSignUpData('<first_name>', '<last_name>', '<username>', '<email>', '<state>', '<dob>', '<phone>', '<heard_about_us>', '<profile_picture>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | first_name | last_name                                                 | username | email                  | state | dob        | phone        | heard_about_us | profile_picture | expectedStatus | expectedMessage                                                                        | expectedErrorCode     | 
      | John       | --                                                        | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Last name must contain at least one letter.                                            | LAST_NAME_NO_LETTER   |
      | John       | 123                                                       | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid last name! Last name can only contain letters, spaces, hyphens or apostrophes. | INVALID_LAST_NAME     |
      | John       | example123                                                | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid last name! Last name can only contain letters, spaces, hyphens or apostrophes. | INVALID_LAST_NAME     |
      | John       | A@                                                        | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid last name! Last name can only contain letters, spaces, hyphens or apostrophes. | INVALID_LAST_NAME     |
      | John       | B!                                                        | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid last name! Last name can only contain letters, spaces, hyphens or apostrophes. | INVALID_LAST_NAME     |
      | John       | Itisaverylonglastnameofusertobeenteredinsignuppaylo       | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Last name cannot be more than 50 characters.                                           | LAST_NAME_TOO_LONG    |
      | John       | Itisaverylonglastnameofusertobeenteredinsignuppayload     | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Last name cannot be more than 50 characters.                                           | LAST_NAME_TOO_LONG    |
      | John       | !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!     | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid last name! Last name can only contain letters, spaces, hyphens or apostrophes. | INVALID_LAST_NAME     |

  @invalid_username
  Scenario Outline: Sign-Up fails when username invalid
    * def build = buildSignUpData('<first_name>', '<last_name>', '<username>', '<email>', '<state>', '<dob>', '<phone>', '<heard_about_us>', '<profile_picture>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | first_name | last_name | username                                        | email                  | state | dob        | phone        | heard_about_us | profile_picture | expectedStatus | expectedMessage                                                            | expectedErrorCode    | 
      | John       | Doe       | a                                               | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Username cannot be less than 3 characters.                                 | USERNAME_TOO_SHORT   |
      | John       | Doe       | rv                                              | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Username cannot be less than 3 characters.                                 | USERNAME_TOO_SHORT   |
      | John       | Doe       | 12                                              | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Username cannot be less than 3 characters.                                 | USERNAME_TOO_SHORT   |
      | John       | Doe       | 1234                                            | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Username must contain at least one letter.                                 | USERNAME_NO_LETTER   |
      | John       | Doe       | ----                                            | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Username must contain at least one letter.                                 | USERNAME_NO_LETTER   |
      | John       | Doe       | Abc@@                                           | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Username can only contain letters, numbers, underscores, hyphens and dots. | INVALID_USERNAME     |
      | John       | Doe       | Itisaverylongusernameforuser123                 | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Username cannot be more than 30 characters.                                | USERNAME_TOO_LONG    |
      | John       | Doe       | Itisaverylongusernameforausertobeselectedoneff  | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Username cannot be more than 30 characters.                                | USERNAME_TOO_LONG    |
      | John       | Doe       | !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Username can only contain letters, numbers, underscores, hyphens and dots. | INVALID_USERNAME     |
      | John       | Doe       | 1231231231231231231231231231231231231231231231  | userexample9@gmail.com | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Username cannot be more than 30 characters.                                | USERNAME_TOO_LONG    |

  @invalid_email_format
  Scenario Outline: Sign-Up fails when email format invalid
    * def build = buildSignUpData('<first_name>', '<last_name>', '<username>', '<email>', '<state>', '<dob>', '<phone>', '<heard_about_us>', '<profile_picture>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | first_name | last_name | username | email                 | state | dob        | phone        | heard_about_us | profile_picture | expectedStatus | expectedMessage       | expectedErrorCode     | 
      | User       | Doe       | random   | plainaddress          | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid email format! | INVALID_EMAIL_FORMAT  |
      | User       | Doe       | random   | missingatsign.com     | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid email format! | INVALID_EMAIL_FORMAT  |
      | User       | Doe       | random   | @domain.com           | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid email format! | INVALID_EMAIL_FORMAT  |
      | User       | Doe       | random   | user@                 | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid email format! | INVALID_EMAIL_FORMAT  |
      | User       | Doe       | random   | user@.com             | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid email format! | INVALID_EMAIL_FORMAT  |
      | User       | Doe       | random   | user@domain           | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid email format! | INVALID_EMAIL_FORMAT  |
      | User       | Doe       | random   | user name@domain.com  | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid email format! | INVALID_EMAIL_FORMAT  |
      | User       | Doe       | random   | user@@domain.com      | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid email format! | INVALID_EMAIL_FORMAT  |
      | User       | Doe       | random   | user@domain,com       | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid email format! | INVALID_EMAIL_FORMAT  |
 
  @invalid_phone
  Scenario Outline: Sign-Up fails when phone number invalid
    * def build = buildSignUpData('<first_name>', '<last_name>', '<username>', '<email>', '<state>', '<dob>', '<phone>', '<heard_about_us>', '<profile_picture>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | first_name | last_name | username | email                  | state | dob        | phone  | heard_about_us | profile_picture | expectedStatus | expectedMessage              | expectedErrorCode   |
      | User       | Doe       | random   | userexample9@gmail.com | NY    | 1999-05-14 | +14191 | Google         | icon_bear       | 400            | Invalid phone number format! | INVALID_PHONE       |

  @invalid_dob
  Scenario Outline: Sign-Up fails when date format invalid
    * def build = buildSignUpData('<first_name>', '<last_name>', '<username>', '<email>', '<state>', '<dob>', '<phone>', '<heard_about_us>', '<profile_picture>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | first_name | last_name | username | email                  | state | dob        | phone        | heard_about_us | profile_picture | expectedStatus | expectedMessage                                                          | expectedErrorCode    |
      | User       | Doe       | random   | userexample9@gmail.com | NY    | 1999/05/14 | +14191000000 | Google         | icon_bear       | 400            | Invalid date format. Use YYYY-MM-DD.                                     | INVALID_DATE_FORMAT  |
      | User       | Doe       | random   | userexample9@gmail.com | NY    | 0000-00-00 | +14191000000 | Google         | icon_bear       | 400            | Invalid calendar date. Input a valid date of birth in YYYY-MM-DD format. | INVALID_DATE_VALUE   |
      | User       | Doe       | random   | userexample9@gmail.com | NY    | 0000-05-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid calendar date. Input a valid date of birth in YYYY-MM-DD format. | INVALID_DATE_VALUE   |
      | User       | Doe       | random   | userexample9@gmail.com | NY    | 1993-00-14 | +14191000000 | Google         | icon_bear       | 400            | Invalid calendar date. Input a valid date of birth in YYYY-MM-DD format. | INVALID_DATE_VALUE   |
      | User       | Doe       | random   | userexample9@gmail.com | NY    | 1993-15-00 | +14191000000 | Google         | icon_bear       | 400            | Invalid calendar date. Input a valid date of birth in YYYY-MM-DD format. | INVALID_DATE_VALUE   |
      | User       | Doe       | random   | userexample9@gmail.com | NY    | 2030-05-14 | +14191000000 | Google         | icon_bear       | 400            | Date of birth cannot be in the future.                                   | INVALID_DATE_VALUE   |
      | User       | Doe       | random   | userexample9@gmail.com | NY    | 2010-05-14 | +14191000000 | Google         | icon_bear       | 400            | You must be at least 18 years old.                                       | UNDERAGE             |
      | User       | Doe       | random   | userexample9@gmail.com | NY    | 2025-05-14 | +14191000000 | Google         | icon_bear       | 400            | You must be at least 18 years old.                                       | UNDERAGE             |
      | User       | Doe       | random   | userexample9@gmail.com | NY    | 2000-02-30 | +14191000000 | Google         | icon_bear       | 400            | Invalid calendar date. Input a valid date of birth in YYYY-MM-DD format. | INVALID_DATE_VALUE   |
      | User       | Doe       | random   | userexample9@gmail.com | NY    | 2000-04-32 | +14191000000 | Google         | icon_bear       | 400            | Invalid calendar date. Input a valid date of birth in YYYY-MM-DD format. | INVALID_DATE_VALUE   |
      | User       | Doe       | random   | userexample9@gmail.com | NY    | 1999-13-30 | +14191000000 | Google         | icon_bear       | 400            | Invalid calendar date. Input a valid date of birth in YYYY-MM-DD format. | INVALID_DATE_VALUE   |
      | User       | Doe       | random   | userexample9@gmail.com | NY    | 13-1999-30 | +14191000000 | Google         | icon_bear       | 400            | Invalid date format. Use YYYY-MM-DD.                                     | INVALID_DATE_FORMAT  |
      | User       | Doe       | random   | userexample9@gmail.com | NY    | 13-30-1999 | +14191000000 | Google         | icon_bear       | 400            | Invalid date format. Use YYYY-MM-DD.                                     | INVALID_DATE_FORMAT  |
      | User       | Doe       | random   | userexample9@gmail.com | NY    | abcd-ef-gh | +14191000000 | Google         | icon_bear       | 400            | Invalid date format. Use YYYY-MM-DD.                                     | INVALID_DATE_FORMAT  |
      | User       | Doe       | random   | userexample9@gmail.com | NY    | 20199912   | +14191000000 | Google         | icon_bear       | 400            | Invalid date format. Use YYYY-MM-DD.                                     | INVALID_DATE_FORMAT  |
      | User       | Doe       | random   | userexample9@gmail.com | NY    | 20000222   | +14191000000 | Google         | icon_bear       | 400            | Invalid date format. Use YYYY-MM-DD.                                     | INVALID_DATE_FORMAT  |

  @unverified_email_exists
  Scenario Outline: Sign-Up fails when unverified email already exists
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingEmail = signUpInfo.email
    
    * def build = buildSignUpData('<first_name>', '<last_name>', '<username>', existingEmail, '<state>', '<dob>', '<phone>', '<heard_about_us>', '<profile_picture>')
    * def dynamicEmail = build.dynamicEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | first_name | last_name | username  | email          | state | dob        | phone        | heard_about_us | profile_picture | expectedStatus | expectedMessage                                         | expectedErrorCode       |
      | User       | Doe       | random    | existingEmail  | NY    | 1999-05-14 | +14191000000 | Google         | icon_bear       | 429            | Activation email already sent. Please check your inbox. | ACTIVATION_ALREADY_SENT |
