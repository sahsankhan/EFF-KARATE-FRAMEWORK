Feature: Set or Reset Password API Automation
  Purpose: Validate password set/reset functionality including successful password updates, invalid tokens, and missing field validations.

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def setPasswordQuery = read('classpath:resources/graphql/setpassword.graphql')
    * def existingEmail = karate.read('file:target/target/email.txt')
    * print 'Loaded existing user email:', existingEmail
    * def buildSetPasswordData =
      """
      function(email, resetKey, password, test_bypass, existingEmail) {
        var emailValue = email;
        var userEmail = emailValue == 'existing' ? existingEmail : (emailValue == '' ? '' : emailValue);
        var userData = {
          email: userEmail,
          resetKey: resetKey,
          password: password,
          test_bypass: test_bypass
        };
        return { userEmail: userEmail, userData: userData };
      }
      """

  @happy_path
  Scenario Outline: Set-Password succeeds with valid data
    * def build = buildSetPasswordData('<email>', '<resetKey>', '<password>', <test_bypass>, existingEmail)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(setPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Password Reset API Response:', response
    * match response.data.setPassword.statusCode == <expectedStatus>
    * match response.data.setPassword.message contains <expectedMessage>
    * if (<expectedEmailCheck> == true) karate.match(response.data.setPassword.email, userEmail)

    Examples:
      | email      | resetKey         | password   | test_bypass | expectedStatus | expectedMessage                 | expectedEmailCheck |
      | existing   | fake-key-for-dev | User@12345 | true        | 200            | 'Password updated successfully.' | true               |

  @user_not_found
  Scenario Outline: Set-Password fails when user not found
    * def build = buildSetPasswordData('<email>', '<resetKey>', '<password>', <test_bypass>, existingEmail)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(setPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Password Reset API Response:', response
    * match response.data.setPassword.statusCode == <expectedStatus>
    * match response.data.setPassword.message contains <expectedMessage>
    * if (<expectedEmailCheck> == true) karate.match(response.data.setPassword.email, userEmail)

    Examples:
      | email                 | resetKey         | password   | test_bypass | expectedStatus | expectedMessage   | expectedEmailCheck |
      | nouserexists@gmail.com| fake-key-for-dev | User@12345 | true        | 404            | 'User not found!' | false              |

  @invalid_reset_key
  Scenario Outline: Set-Password fails when reset key invalid
    * def build = buildSetPasswordData('<email>', '<resetKey>', '<password>', <test_bypass>, existingEmail)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(setPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Password Reset API Response:', response
    * match response.data.setPassword.statusCode == <expectedStatus>
    * match response.data.setPassword.message contains <expectedMessage>
    * if (<expectedEmailCheck> == true) karate.match(response.data.setPassword.email, userEmail)

    Examples:
      | email    | resetKey          | password   | test_bypass | expectedStatus | expectedMessage                      | expectedEmailCheck |
      | existing | invalid-reset-key  | User@12345 | false       | 401            | 'Invalid or expired reset key!'      | false              |

  @missing_email
  Scenario Outline: Set-Password fails when email missing
    * def build = buildSetPasswordData('<email>', '<resetKey>', '<password>', <test_bypass>, existingEmail)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(setPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Password Reset API Response:', response
    * match response.data.setPassword.statusCode == <expectedStatus>
    * match response.data.setPassword.message contains <expectedMessage>
    * if (<expectedEmailCheck> == true) karate.match(response.data.setPassword.email, userEmail)

    Examples:
      | email | resetKey         | password   | test_bypass | expectedStatus | expectedMessage         | expectedEmailCheck |
      |       | fake-key-for-dev  | User@12345 | true        | 400            | 'Missing required fields!' | false              |

  @missing_password
  Scenario Outline: Set-Password fails when password missing
    * def build = buildSetPasswordData('<email>', '<resetKey>', '<password>', <test_bypass>, existingEmail)
    * def userEmail = build.userEmail
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(setPasswordQuery)', variables: '#(userData)' }

    Given request payload
    When method post
    Then status 200
    * print 'Password Reset API Response:', response
    * match response.data.setPassword.statusCode == <expectedStatus>
    * match response.data.setPassword.message contains <expectedMessage>
    * if (<expectedEmailCheck> == true) karate.match(response.data.setPassword.email, userEmail)

    Examples:
      | email    | resetKey         | password | test_bypass | expectedStatus | expectedMessage         | expectedEmailCheck |
      | existing | fake-key-for-dev |          | true        | 400            | 'Missing required fields!' | false              |
