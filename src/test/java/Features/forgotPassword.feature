Feature: Forgot Password API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def forgotPasswordQuery = read('classpath:resources/graphql/forgotPassword.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/email.txt')
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
      | email    | expectedStatus | expectedMessage                                    |
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
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | email | expectedStatus | expectedMessage     |
      |       | 400            | Email is required   |

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
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | email      | expectedStatus | expectedMessage         |
      | invalid     | 400            | Invalid email format!   |
      | a@b         | 400            | Invalid email format!   |
      | test@       | 400            | Invalid email format!   |

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
    * match response.data.forgotPassword == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | email                      | expectedStatus | expectedMessage   |
      | nonexisting@example.com   | 404            | User not found   |

