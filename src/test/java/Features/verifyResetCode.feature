Feature: Verify Reset Code API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def verifyResetCodeQuery = read('classpath:resources/graphql/verifyResetCode.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/email.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingEmail = signUpInfo.email
    * def buildVerifyResetCodeData =
      """
      function(email, code, existingEmail) {
        var emailValue = email;
        var userEmail = emailValue == 'existing' ? existingEmail : (emailValue == '' ? '' : emailValue);
        var userData = {
          email: userEmail,
          code: code == '' ? '' : code
        };
        return { userEmail: userEmail, userData: userData };
      }
      """
  
  @invalid_email
  Scenario Outline: Verify reset code for invalid email
    * def build = buildVerifyResetCodeData('<email>', '<code>', existingEmail)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(verifyResetCodeQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'VerifyResetCode API Response:', response
    * match response.data.verifyResetCode == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | email   | code   | expectedStatus | expectedMessage         |
      | invalid | 806456 | 400            | Invalid email format!   |
      | a@b     | 806456 | 400            | Invalid email format!   |
      | test@   | 806456 | 400            | Invalid email format!   |

  @missing_email
  Scenario Outline: Verify reset code for missing email
    * def build = buildVerifyResetCodeData('<email>', '<code>', existingEmail)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(verifyResetCodeQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'VerifyResetCode API Response:', response
    * match response.data.verifyResetCode == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | email | code   | expectedStatus | expectedMessage     |
      |       | 806456 | 400            | Email is required   |

  @missing_code
  Scenario Outline: Verify reset code for missing code
    * def build = buildVerifyResetCodeData('<email>', '<code>', existingEmail)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(verifyResetCodeQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'VerifyResetCode API Response:', response
    * match response.data.verifyResetCode == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | email    | code | expectedStatus | expectedMessage   |
      | existing |      | 400            | Code is required  |

  @user_not_found
  Scenario Outline: Verify reset code for non existing email
    * def build = buildVerifyResetCodeData('<email>', '<code>', existingEmail)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(verifyResetCodeQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'VerifyResetCode API Response:', response
    * match response.data.verifyResetCode == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | email                   | code   | expectedStatus | expectedMessage |
      | nonexisting@example.com | 806456 | 404            | User not found  |

  @wrong_code
  Scenario Outline: Verify wrong reset code
    * def build = buildVerifyResetCodeData('<email>', '<code>', existingEmail)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(verifyResetCodeQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'VerifyResetCode API Response:', response
    * match response.data.verifyResetCode == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | email    | code   | expectedStatus | expectedMessage            |
      | existing | 000000 | 401            | Wrong verification code    |
      | existing | 999999 | 401            | Wrong verification code    |

