Feature: Check Username API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:resources/common/error-codes.json')
    * def checkUsernameQuery = read('classpath:resources/graphql/auth/checkUsername.graphql')
    * def random = function() { return java.lang.Math.floor(java.lang.Math.random() * 100000); }
    * def buildCheckUsernameData =
      """
      function(username) {
        var usernameValue = username;
        if (usernameValue === 'null') usernameValue = null;
        if (usernameValue === '') return { username: '' };
        if (usernameValue === 'true') usernameValue = true;
        if (usernameValue === 'false') usernameValue = false;
        if (!isNaN(usernameValue) && usernameValue !== '') {
          usernameValue = Number(usernameValue);
        }
        
        return { username: usernameValue };
      }
      """

  @happy_path_available
  Scenario Outline: CheckUsername succeeds when username is available
    * def variables = buildCheckUsernameData('<username>')
    * def payload = { query: '#(checkUsernameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckUsername Available Response:', response
    * match response.data.checkUsername.statusCode == <expectedStatus>
    * match response.data.checkUsername.message contains <expectedMessage>

    Examples:
      | username           | expectedStatus | expectedMessage       |
      | availableUsername  | 200            | 'Username is valid!'  |

  @username_taken_verified_user
  Scenario Outline: CheckUsername fails when username is taken by verified user
    * def variables = buildCheckUsernameData('<username>')
    * def payload = { query: '#(checkUsernameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckUsername Taken Response:', response
    * match response.data.checkUsername == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | username | expectedStatus | expectedMessage              | expectedErrorCode |
      | test     | 409            | Username is already taken.   | USERNAME_TAKEN    |

  @missing_username
  Scenario Outline: CheckUsername fails when username is missing or empty
    * def variables = buildCheckUsernameData('<username>')
    * def payload = { query: '#(checkUsernameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckUsername Missing Username Response:', response
    * match response.data.checkUsername == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | username | expectedStatus | expectedMessage       | expectedErrorCode   |
      |          | 400            | Username is required! | USERNAME_REQUIRED   |

  @username_too_short
  Scenario Outline: CheckUsername fails when username is less than 3 characters
    * def variables = buildCheckUsernameData('<username>')
    * def payload = { query: '#(checkUsernameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckUsername Too Short Response:', response
    * match response.data.checkUsername == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | username | expectedStatus | expectedMessage                            | expectedErrorCode   |
      | a        | 400            | Username cannot be less than 3 characters. | USERNAME_TOO_SHORT  |
      | 1        | 400            | Username cannot be less than 3 characters. | USERNAME_TOO_SHORT  |
      | rv       | 400            | Username cannot be less than 3 characters. | USERNAME_TOO_SHORT  |
      | 12       | 400            | Username cannot be less than 3 characters. | USERNAME_TOO_SHORT  |

  @invalid_username_characters
  Scenario Outline: CheckUsername fails when username contains invalid characters
    * def variables = buildCheckUsernameData('<username>')
    * def payload = { query: '#(checkUsernameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckUsername Invalid Characters Response:', response
    * match response.data.checkUsername == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | username   | expectedStatus | expectedMessage                                                  | expectedErrorCode |
      | user name  | 400            | can only contain letters, numbers, underscores, hyphens and dots | INVALID_USERNAME  |
      | user@name  | 400            | can only contain letters, numbers, underscores, hyphens and dots | INVALID_USERNAME  |
      | user#name  | 400            | can only contain letters, numbers, underscores, hyphens and dots | INVALID_USERNAME  |
      | user$name  | 400            | can only contain letters, numbers, underscores, hyphens and dots | INVALID_USERNAME  |
      | user%name  | 400            | can only contain letters, numbers, underscores, hyphens and dots | INVALID_USERNAME  |
      | user&name  | 400            | can only contain letters, numbers, underscores, hyphens and dots | INVALID_USERNAME  |
      | user*name  | 400            | can only contain letters, numbers, underscores, hyphens and dots | INVALID_USERNAME  |
      | user!name  | 400            | can only contain letters, numbers, underscores, hyphens and dots | INVALID_USERNAME  |
      | user(name) | 400            | can only contain letters, numbers, underscores, hyphens and dots | INVALID_USERNAME  |
      | user[name] | 400            | can only contain letters, numbers, underscores, hyphens and dots | INVALID_USERNAME  |
      | user{name} | 400            | can only contain letters, numbers, underscores, hyphens and dots | INVALID_USERNAME  |
      | user/name  | 400            | can only contain letters, numbers, underscores, hyphens and dots | INVALID_USERNAME  |
      | user+name  | 400            | can only contain letters, numbers, underscores, hyphens and dots | INVALID_USERNAME  |
      | user=name  | 400            | can only contain letters, numbers, underscores, hyphens and dots | INVALID_USERNAME  |
      | user,name  | 400            | can only contain letters, numbers, underscores, hyphens and dots | INVALID_USERNAME  |

  @username_without_letters
  Scenario Outline: CheckUsername fails when username contains invalid characters
    * def variables = buildCheckUsernameData('<username>')
    * def payload = { query: '#(checkUsernameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckUsername Invalid Characters Response:', response
    * match response.data.checkUsername == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | username  | expectedStatus |  expectedMessage                           | expectedErrorCode  |
      | ___       | 400            | Username must contain at least one letter. | USERNAME_NO_LETTER |
      | ---       | 400            | Username must contain at least one letter. | USERNAME_NO_LETTER |
      | ...       | 400            | Username must contain at least one letter. | USERNAME_NO_LETTER |
      | 123       | 400            | Username must contain at least one letter. | USERNAME_NO_LETTER |
      | 1--       | 400            | Username must contain at least one letter. | USERNAME_NO_LETTER |

   @username_exceeding_max_characters
   Scenario Outline: CheckUsername fails when username exceeding maximum characters allowed
    * def variables = buildCheckUsernameData('<username>')
    * def payload = { query: '#(checkUsernameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckUsername Invalid Characters Response:', response
    * match response.data.checkUsername == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | username                                        | expectedStatus | expectedMessage                                                  | expectedErrorCode  |
      | Itisaverylongusernameforuser123                 | 400            | Username cannot be more than 30 characters.                      | USERNAME_TOO_LONG  |
      | Itisaverylongusernameforausertobeselectedoneff  | 400            | Username cannot be more than 30 characters.                      | USERNAME_TOO_LONG  |
      | !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  | 400            | can only contain letters, numbers, underscores, hyphens and dots | INVALID_USERNAME   |
      | ..............................................  | 400            | Username cannot be more than 30 characters.                      | USERNAME_TOO_LONG  |
      | ----------------------------------------------  | 400            | Username cannot be more than 30 characters.                      | USERNAME_TOO_LONG  |