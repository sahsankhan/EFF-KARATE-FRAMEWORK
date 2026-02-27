Feature: Forgot Password API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def forgotPasswordQuery = read('classpath:graphql/auth/forgotPassword.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingEmail = signUpInfo.email
    * def buildForgotPasswordData =
      """
      function(email, existingEmail) {
        var emailValue = email;
        var userEmail = emailValue == 'existing' ? existingEmail : (emailValue == '' ? '' : emailValue);
        var userData = {
          email: userEmail
        };
        return { userEmail: userEmail, userData: userData };
      }
      """

  @happy_path
  Scenario Outline: Verify forgot password success
    * java.lang.Thread.sleep(60000)
    * def build = buildForgotPasswordData('<email>', existingEmail)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(forgotPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'ForgotPassword API Response:', response
    * match response.data.forgotPassword.statusCode == <expectedStatus>
    * match response.data.forgotPassword.message == '<expectedMessage>'
    * match response.data.forgotPassword.email == userEmail

    Examples:
      | email    | expectedStatus | expectedMessage                                  |
      | existing | 200            | A verification code has been sent to your email. |

  @missing_email
  Scenario Outline: Verify forgot password with missing email
    * def build = buildForgotPasswordData('<email>', existingEmail)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(forgotPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'ForgotPassword API Response:', response
    * match response.data.forgotPassword == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | email | expectedStatus | expectedMessage     | expectedErrorCode   |
      |       | 400            | Email is required   | EMAIL_REQUIRED      |

  @invalid_email
  Scenario Outline: Verify forgot password with invalid email
    * def build = buildForgotPasswordData('<email>', existingEmail)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(forgotPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'ForgotPassword API Response:', response
    * match response.data.forgotPassword == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | email                 | expectedStatus | expectedMessage         | expectedErrorCode     |
      | plainaddress          | 400            | Invalid email format!   | INVALID_EMAIL_FORMAT  |
      | missingatsign.com     | 400            | Invalid email format!   | INVALID_EMAIL_FORMAT  |
      | @domain.com           | 400            | Invalid email format!   | INVALID_EMAIL_FORMAT  |
      | user@                 | 400            | Invalid email format!   | INVALID_EMAIL_FORMAT  |
      | user@.com             | 400            | Invalid email format!   | INVALID_EMAIL_FORMAT  |
      | user@domain           | 400            | Invalid email format!   | INVALID_EMAIL_FORMAT  |
      | user name@domain.com  | 400            | Invalid email format!   | INVALID_EMAIL_FORMAT  |
      | user@domain,com       | 400            | Invalid email format!   | INVALID_EMAIL_FORMAT  |
     
  @user_not_found
  Scenario Outline: Verify forgot password user not found
    * def build = buildForgotPasswordData('<email>', existingEmail)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(forgotPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'ForgotPassword API Response:', response
    * match response.data.forgotPassword.statusCode == <expectedStatus>
    * match response.data.forgotPassword.message == '<expectedMessage>'

    Examples:
      | email                     | expectedStatus | expectedMessage                                     |
      | nonexisting@example.com   | 200            | A verification code has been sent to your email.    |

