Feature: Verify Reset Code API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:resources/common/error-codes.json')
    * def verifyResetCodeQuery = read('classpath:resources/graphql/auth/verifyResetCode.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
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
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | email                             | code   | expectedStatus | expectedMessage                         | expectedErrorCode       |
      | testing.automation.4127@gmail.com | 000000 | 401            | Invalid or expired verification code    | INVALID_OR_EXPIRED_CODE |
      | testing.automation.4127@gmail.com | 999999 | 401            | Invalid or expired verification code    | INVALID_OR_EXPIRED_CODE |

  @happy_path
  Scenario Outline: Verify reset code success using Gmail
    * java.lang.Thread.sleep(360000)
    # STEP 2 — Fetch OTP from Gmail
    * def otpResponse = call read('classpath:helpers/gmailhelper.feature')
    * def resetCode = otpResponse.result.code
    * print 'Fetched OTP Code:', resetCode

    * def verifyData = { email: '<email>', code: '#(resetCode)' } 
    * def verifyPayload = { query: '#(verifyResetCodeQuery)', variables: '#(verifyData)' }

    Given request verifyPayload
    When method post
    Then status 200

    * print response
    * match response.data.verifyResetCode.statusCode == <expectedStatus>
    * match response.data.verifyResetCode.message == '<expectedMessage>'

      Examples:
        | email                             | expectedStatus | expectedMessage            | 
        | testing.automation.4127@gmail.com | 200            | Code verified successfully |

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
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | email                 | code   | expectedStatus | expectedMessage         | expectedErrorCode     |
      | plainaddress          | code   | 400            | Invalid email format!   | INVALID_EMAIL_FORMAT  |
      | missingatsign.com     | 806456 | 400            | Invalid email format!   | INVALID_EMAIL_FORMAT  |
      | @domain.com           | 806456 | 400            | Invalid email format!   | INVALID_EMAIL_FORMAT  |
      | user@                 | 806456 | 400            | Invalid email format!   | INVALID_EMAIL_FORMAT  |
      | user@.com             | 806456 | 400            | Invalid email format!   | INVALID_EMAIL_FORMAT  |
      | user@domain           | 806456 | 400            | Invalid email format!   | INVALID_EMAIL_FORMAT  |
      | user name@domain.com  | 806456 | 400            | Invalid email format!   | INVALID_EMAIL_FORMAT  |
      | user@domain,com       | 806456 | 400            | Invalid email format!   | INVALID_EMAIL_FORMAT  |

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
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | email | code   | expectedStatus | expectedMessage     | expectedErrorCode   |
      |       | 806456 | 400            | Email is required   | EMAIL_REQUIRED      |

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
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | email    | code | expectedStatus | expectedMessage   | expectedErrorCode          |
      | existing |      | 400            | Code is required  | VERIFICATION_CODE_REQUIRED |

  @invalid_code_format
  Scenario Outline: Verify reset code for invalid code format
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
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | email    | code   | expectedStatus | expectedMessage                                      | expectedErrorCode                 |
      | existing | 1      | 400            | Invalid code format. Code must be a 6-digit number.  | INVALID_VERIFICATION_CODE_FORMAT  |
      | existing | 12     | 400            | Invalid code format. Code must be a 6-digit number.  | INVALID_VERIFICATION_CODE_FORMAT  |
      | existing | 123    | 400            | Invalid code format. Code must be a 6-digit number.  | INVALID_VERIFICATION_CODE_FORMAT  |
      | existing | 1234   | 400            | Invalid code format. Code must be a 6-digit number.  | INVALID_VERIFICATION_CODE_FORMAT  |
      | existing | 12345  | 400            | Invalid code format. Code must be a 6-digit number.  | INVALID_VERIFICATION_CODE_FORMAT  |
      | existing | abc    | 400            | Invalid code format. Code must be a 6-digit number.  | INVALID_VERIFICATION_CODE_FORMAT  |
      | existing | ------ | 400            | Invalid code format. Code must be a 6-digit number.  | INVALID_VERIFICATION_CODE_FORMAT  |

  @non_existing_user
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
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | email                   | code   | expectedStatus | expectedMessage                       | expectedErrorCode       |
      | nonexisting@example.com | 806456 | 401            | Invalid or expired verification code  | INVALID_OR_EXPIRED_CODE |

  

