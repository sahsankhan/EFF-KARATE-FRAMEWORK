Feature: Set or Reset Password API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('')
    * def setPasswordQuery = read('classpath:resources/graphql/auth/setpassword.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingEmail = signUpInfo.email
    * def existingResetKey = signUpInfo.resetKey
    * def testPassword = 'User@12345'
    * def buildSetPasswordData =
      """
      function(email, resetKey, password, existingEmail, existingResetKey, testPassword) {
        var emailValue = email;
        var resetKeyValue = resetKey;
        var passwordValue = password;
        var userEmail = emailValue == 'existing' ? existingEmail : (emailValue == '' ? '' : emailValue);
        var userResetKey = resetKeyValue == 'existing' ? existingResetKey : resetKeyValue;
        var userPassword = passwordValue == 'default' ? testPassword : (passwordValue == '' ? '' : passwordValue);
        var userData = {
          email: userEmail,
          resetKey: userResetKey,
          password: userPassword
        };
        return { userEmail: userEmail, userPassword: userPassword, userData: userData };
      }
      """

  @happy_path
  Scenario Outline: Set-Password succeeds with valid data
    * def build = buildSetPasswordData('<email>', '<resetKey>', '<password>', existingEmail, existingResetKey, testPassword)
    * def userEmail = build.userEmail
    * def userPassword = build.userPassword
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(setPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Password Reset API Response:', response
    * match response.data.setPassword.statusCode == <expectedStatus>
    * match response.data.setPassword.message contains '<expectedMessage>'
    * if (<expectedEmailCheck> == true) karate.match(response.data.setPassword.email, userEmail)
    * if (response.data.setPassword.statusCode == 200) karate.write({email: existingEmail, resetKey: existingResetKey, password: userPassword, isVerified: false, passwordSet: true}, 'target/info.txt')

    Examples:
      | email      | resetKey | password | expectedStatus | expectedMessage               | expectedEmailCheck |
      | existing   | existing | default  | 200            | Password set successfully.    | true               |

  @user_not_found
  Scenario Outline: Set-Password fails when user not found
    * def build = buildSetPasswordData('<email>', '<resetKey>', '<password>', existingEmail, existingResetKey, testPassword)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(setPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Password Reset API Response:', response
    * match response.data.setPassword == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'
    * if (<expectedEmailCheck> == true) karate.match(response.data.setPassword.email, userEmail)

    Examples:
      | email                   | resetKey | password | expectedStatus | expectedMessage               | expectedEmailCheck | expectedErrorCode   |
      | nouserexists@gmail.com  | existing | default  | 401            | Invalid or expired reset key! | false              | INVALID_RESET_KEY   |

  @missing_reset_key
  Scenario Outline: Set-Password fails when reset key invalid
    * def build = buildSetPasswordData('<email>', '<resetKey>', '<password>', existingEmail, existingResetKey, testPassword)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(setPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Password Reset API Response:', response
    * match response.data.setPassword == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'
    * if (<expectedEmailCheck> == true) karate.match(response.data.setPassword.email, userEmail)

    Examples:
      | email    | resetKey      | password | expectedStatus | expectedMessage           | expectedEmailCheck | expectedErrorCode   |
      | existing |               | default  | 400            | Reset key is required!    | false              | RESET_KEY_REQUIRED  |

  @invalid_reset_key
  Scenario Outline: Set-Password fails when reset key invalid
    * def build = buildSetPasswordData('<email>', '<resetKey>', '<password>', existingEmail, existingResetKey, testPassword)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(setPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Password Reset API Response:', response
    * match response.data.setPassword == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'
    * if (<expectedEmailCheck> == true) karate.match(response.data.setPassword.email, userEmail)

    Examples:
      | email    | resetKey          | password | expectedStatus | expectedMessage               |  expectedEmailCheck | expectedErrorCode   |
      | existing | invalid-reset-key | default  | 401            | Invalid or expired reset key! |  false              |  INVALID_RESET_KEY  |

  @missing_email
  Scenario Outline: Set-Password fails when email missing
    * def build = buildSetPasswordData('<email>', '<resetKey>', '<password>', existingEmail, existingResetKey, testPassword)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(setPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Password Reset API Response:', response
    * match response.data.setPassword == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'
    * if (<expectedEmailCheck> == true) karate.match(response.data.setPassword.email, userEmail)

    Examples:
      | email | resetKey | password | expectedStatus | expectedMessage       | expectedEmailCheck | expectedErrorCode   |
      |       | existing | default  | 400            | Email is required!    | false              | EMAIL_REQUIRED      |

  @missing_password
  Scenario Outline: Set-Password fails when password missing
    * def build = buildSetPasswordData('<email>', '<resetKey>', '<password>', existingEmail, existingResetKey, testPassword)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(setPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Password Reset API Response:', response
    * match response.data.setPassword == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'
    * if (<expectedEmailCheck> == true) karate.match(response.data.setPassword.email, userEmail)

    Examples:
      | email    | resetKey | password | expectedStatus | expectedMessage       | expectedEmailCheck | expectedErrorCode   |
      | existing | existing |          | 400            | Password is required! | false              | PASSWORD_REQUIRED   |

  @invalid_password
  Scenario Outline: Set-Password fails when password missing
    * def build = buildSetPasswordData('<email>', '<resetKey>', '<password>', existingEmail, existingResetKey, testPassword)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(setPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Password Reset API Response:', response
    * match response.data.setPassword == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'
    * if (<expectedEmailCheck> == true) karate.match(response.data.setPassword.email, userEmail)

    Examples:
      | email    | resetKey | password | expectedStatus | expectedMessage       | expectedEmailCheck | expectedErrorCode   |
      | existing | existing |          | 400            | Password is required! | false              | PASSWORD_REQUIRED   |

  @invalid_password
  Scenario Outline: Set-Password fails when password is invalid 
    * def build = buildSetPasswordData('<email>', '<resetKey>', '<password>', existingEmail, existingResetKey, testPassword)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(setPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Password Reset API Response:', response
    * match response.data.setPassword == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'
    * if (<expectedEmailCheck> == true) karate.match(response.data.setPassword.email, userEmail)

    Examples:
      | email    | resetKey | password   | expectedStatus | expectedMessage                                            | expectedEmailCheck | expectedErrorCode   |
      | existing | existing | abc        | 400            | Password must be at least 8 characters long.               | false              | PASSWORD_TOO_SHORT  |
      | existing | existing | abc12      | 400            | Password must be at least 8 characters long.               | false              | PASSWORD_TOO_SHORT  |
      | existing | existing | abc123456  | 400            | Password must contain at least one uppercase letter (A–Z). | false              | PASSWORD_NO_UPPER   |
      | existing | existing | ABC12345   | 400            | Password must contain at least one lowercase letter (a–z). | false              | PASSWORD_NO_LOWER   |
      | existing | existing | Abcdefgh   | 400            | Password must contain at least one number (0–9).           | false              | PASSWORD_NO_NUMBER  |
      | existing | existing | Abcd....   | 400            | Password must contain at least one number (0–9).           | false              | PASSWORD_NO_NUMBER  |
      | existing | existing | Abc12345   | 400            | Password must contain at least one special character       | false              | PASSWORD_NO_SPECIAL |
      | existing | existing | Abcde123   | 400            | Password must contain at least one special character       | false              | PASSWORD_NO_SPECIAL |

  @password_already_set
  Scenario Outline: Set-Password fails when password is already set
    * def build = buildSetPasswordData('<email>', '<resetKey>', '<password>', existingEmail, existingResetKey, testPassword)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(setPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Password Reset API Response:', response
    * match response.data.setPassword == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'
    * if (<expectedEmailCheck> == true) karate.match(response.data.setPassword.email, userEmail)

    Examples:
      | email    | resetKey | password | expectedStatus | expectedMessage                                                    | expectedEmailCheck | expectedErrorCode      |
      | existing | existing | default  | 409            | Password already set. Use Forgot Password if you want to reset it. | false              | PASSWORD_ALREADY_SET   |