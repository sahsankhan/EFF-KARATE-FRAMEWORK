Feature: Verify Email API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def verifyEmailQuery = read('classpath:resources/graphql/verifyEmail.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingEmail = signUpInfo.email
    * def existingResetKey = signUpInfo.resetKey
    # Password may or may not exist depending on whether setPassword has run
    * def existingPassword = karate.get('signUpInfo.password', null)
    * def passwordSet = signUpInfo.passwordSet
    * def buildVerifyKey =
      """
      function(verifyKey, existingEmail) {
        var key = verifyKey == 'existing' ? 'TEST_BYPASS::' + existingEmail : verifyKey;
        return key;
      }
      """

  @happy_path
  Scenario Outline: Email verification succeeds with valid verification key
    * def verifyKey = buildVerifyKey('<verifyKey>', existingEmail)
    * def verifyData = { verifyKey: '#(verifyKey)' }
    * def payload = { query: '#(verifyEmailQuery)', variables: '#(verifyData)' }

    Given request payload
    When method post
    Then status 200
    * print 'VerifyEmail API Response:', response
    * match response.data.verifyEmail.statusCode == <expectedStatus>
    * match response.data.verifyEmail.message == '<expectedMessage>'
    # Update test data file to mark email as verified (preserve password if it exists)
    * def dataToSave = existingPassword != null ? {email: existingEmail, resetKey: existingResetKey, password: existingPassword, isVerified: true, passwordSet: passwordSet} : {email: existingEmail, resetKey: existingResetKey, isVerified: true, passwordSet: passwordSet}
    * if (response.data.verifyEmail.statusCode == 200) karate.write(dataToSave, 'target/info.txt')

    Examples:
      | verifyKey | expectedStatus | expectedMessage              |
      | existing  | 200            | Email successfully verified. |

  @missing_key
  Scenario Outline: Email verification fails when verification key is missing
    * def verifyKey = buildVerifyKey('<verifyKey>', existingEmail)
    * def verifyData = { verifyKey: '#(verifyKey)' }
    * def payload = { query: '#(verifyEmailQuery)', variables: '#(verifyData)' }

    Given request payload
    When method post
    Then status 200
    * print 'VerifyEmail API Response:', response
    * match response.data.verifyEmail == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | verifyKey | expectedStatus | expectedMessage             |
      |           | 400            | Missing verification key.   |

  @already_verified
  Scenario Outline: Email verification fails when user is already verified
    * def verifyKey = buildVerifyKey('<verifyKey>', existingEmail)
    * def verifyData = { verifyKey: '#(verifyKey)' }
    * def payload = { query: '#(verifyEmailQuery)', variables: '#(verifyData)' }

    Given request payload
    When method post
    Then status 200
    * print 'VerifyEmail API Response:', response
    * match response.data.verifyEmail == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | verifyKey                                | expectedStatus | expectedMessage                    |
      | TEST_BYPASS::alreadyverified@example.com | 404            | User not found or already verified.|

  @user_not_found
  Scenario Outline: Email verification fails when user is not found
    * def verifyKey = buildVerifyKey('<verifyKey>', existingEmail)
    * def verifyData = { verifyKey: '#(verifyKey)' }
    * def payload = { query: '#(verifyEmailQuery)', variables: '#(verifyData)' }

    Given request payload
    When method post
    Then status 200
    * print 'VerifyEmail API Response:', response
    * match response.data.verifyEmail == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | verifyKey                                | expectedStatus | expectedMessage                    |
      | TEST_BYPASS::nonexistinguser@example.com | 404            | User not found or already verified.|

