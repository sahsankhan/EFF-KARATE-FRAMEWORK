Feature: Login API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def loginQuery = read('classpath:graphql/auth/login.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingEmail = signUpInfo.email
    * def existingPassword = signUpInfo.password
    * def isVerified = signUpInfo.isVerified
    * def passwordSet = signUpInfo.passwordSet
    * def buildLoginData =
      """
      function(email, password, existingEmail, existingPassword) {
        var emailValue = email;
        var passwordValue = password;
        var userEmail = emailValue == 'existing' ? existingEmail : (emailValue == '' ? '' : emailValue);
        // existingPassword comes from setPassword endpoint (saved after password is set)
        var userPassword = passwordValue == 'existing' ? (existingPassword || '') : (passwordValue == '' ? '' : passwordValue);
        var userData = {
          email: userEmail,
          password: userPassword
        };
        return { userEmail: userEmail, userData: userData };
      }
      """

  @happy_path
  Scenario Outline: Login succeeds with valid credentials
    # PREREQUISITE CHECK: Ensure email is verified and password is set
    * if (!isVerified || !passwordSet) karate.fail('Test data not ready: Run signup.feature, setpassword.feature, and verifyEmail.feature first')
    
    * def build = buildLoginData('<email>', '<password>', existingEmail, existingPassword)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(loginQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Login API Response:', response
    * match response.data.login.statusCode == <expectedStatus>
    * match response.data.login.accessToken == '#present'
    * match response.data.login.refreshToken == '#present'
    * match response.data.login.user.email == userEmail
    * if (response.data.login.statusCode == 200) karate.write({email: existingEmail, resetKey: signUpInfo.resetKey, password: existingPassword, isVerified: signUpInfo.isVerified, passwordSet: signUpInfo.passwordSet, refreshToken: response.data.login.refreshToken, accessToken: response.data.login.accessToken}, 'target/info.txt')

    Examples:
      | email    | password | expectedStatus |
      | existing | existing | 200            |

  @wrong_password
  Scenario Outline: Login fails with incorrect password
    # PREREQUISITE CHECK: Ensure email is verified and password is set
    * if (!isVerified || !passwordSet) karate.fail('Test data not ready: Run signup.feature, setpassword.feature, and verifyEmail.feature first')
    
    * def build = buildLoginData('<email>', '<password>', existingEmail, existingPassword)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(loginQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Login API Response:', response
    * match response.data.login == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | email    | password       | expectedStatus | expectedMessage            | expectedErrorCode   |
      | existing | WrongPass@1234 | 401            | Invalid email or password! | INVALID_CREDENTIALS |

  @unverified_email
  Scenario Outline: Login fails with unverified email
    # NOTE: DO NOT verify email here - testing unverified email scenario
    * def build = buildLoginData('<email>', '<password>', existingEmail, existingPassword)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(loginQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Login API Response:', response
    * match response.data.login == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | email                        | password   | expectedStatus | expectedMessage            | expectedErrorCode   |                     
      | unverified@example.com       | User@12345 | 401            | Invalid email or password! | INVALID_CREDENTIALS |

  @non_existing_email
  Scenario Outline: Login fails with non-existing email
    * def build = buildLoginData('<email>', '<password>', existingEmail, existingPassword)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(loginQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Login API Response:', response
    * match response.data.login == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | email                      | password | expectedStatus | expectedMessage               | expectedErrorCode   | 
      | nonexisting@example.com    | existing | 401            | Invalid email or password!    | INVALID_CREDENTIALS |

  @missing_email
  Scenario Outline: Login fails when email is missing
    * def build = buildLoginData('<email>', '<password>', existingEmail, existingPassword)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(loginQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Login API Response:', response
    * match response.data.login == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | email | password | expectedStatus | expectedMessage       | expectedErrorCode   | 
      |       | existing | 400            | Email is required!    | EMAIL_REQUIRED      |

  @missing_password
  Scenario Outline: Login fails when password is missing
    * def build = buildLoginData('<email>', '<password>', existingEmail, existingPassword)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(loginQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Login API Response:', response
    * match response.data.login == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | email    | password | expectedStatus | expectedMessage          | expectedErrorCode   | 
      | existing |          | 400            | Password is required!    | PASSWORD_REQUIRED   |

