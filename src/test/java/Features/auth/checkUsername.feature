Feature: Check Username API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
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
    * match response.data.checkUsername.statusCode == 200
    * match response.data.checkUsername.valid == true

    Examples:
      | username           |
      | availableUsername  |

  @username_taken_verified_user
  Scenario Outline: CheckUsername fails when username is taken by verified user
    * def variables = buildCheckUsernameData('<username>')
    * def payload = { query: '#(checkUsernameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckUsername Taken Response:', response
    * match response.data.checkUsername == null
    * match response.errors[0].errorInfo.statusCode == 409
    * match response.errors[0].message contains 'Username is already taken.'

    Examples:
      | username  |
      | username  |

  @missing_username
  Scenario Outline: CheckUsername fails when username is missing or empty
    * def variables = buildCheckUsernameData('<username>')
    * def payload = { query: '#(checkUsernameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckUsername Missing Username Response:', response
    * match response.data.checkUsername == null
    * match response.errors[0].errorInfo.statusCode == 400
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | username | expectedMessage |
      |          | Username        |
      | null     | Username        |

  @username_too_short
  Scenario Outline: CheckUsername fails when username is less than 2 characters
    * def variables = buildCheckUsernameData('<username>')
    * def payload = { query: '#(checkUsernameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckUsername Too Short Response:', response
    * match response.data.checkUsername == null
    * match response.errors[0].errorInfo.statusCode == 400
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | username | expectedMessage                         |
      | a        | Username must be at least 2 characters. |
      | 1        | Username must be at least 2 characters. |

  @invalid_username_characters
  Scenario Outline: CheckUsername fails when username contains invalid characters
    * def variables = buildCheckUsernameData('<username>')
    * def payload = { query: '#(checkUsernameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckUsername Invalid Characters Response:', response
    * match response.data.checkUsername == null
    * match response.errors[0].errorInfo.statusCode == 400
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | username      | expectedMessage                                                  |
      | user name     | can only contain letters, numbers, underscores, hyphens and dots |
      | user@name     | can only contain letters, numbers, underscores, hyphens and dots |
      | user#name     | can only contain letters, numbers, underscores, hyphens and dots |
      | user$name     | can only contain letters, numbers, underscores, hyphens and dots |
      | user%name     | can only contain letters, numbers, underscores, hyphens and dots |
      | user&name     | can only contain letters, numbers, underscores, hyphens and dots |
      | user*name     | can only contain letters, numbers, underscores, hyphens and dots |
      | user!name     | can only contain letters, numbers, underscores, hyphens and dots |
      | user(name)    | can only contain letters, numbers, underscores, hyphens and dots |
      | user[name]    | can only contain letters, numbers, underscores, hyphens and dots |
      | user{name}    | can only contain letters, numbers, underscores, hyphens and dots |
      | user/name     | can only contain letters, numbers, underscores, hyphens and dots |
      | user+name     | can only contain letters, numbers, underscores, hyphens and dots |
      | user=name     | can only contain letters, numbers, underscores, hyphens and dots |
      | user,name     | can only contain letters, numbers, underscores, hyphens and dots |

  @invalid_username_format
  Scenario Outline: CheckUsername fails when username contains invalid characters
    * def variables = buildCheckUsernameData('<username>')
    * def payload = { query: '#(checkUsernameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckUsername Invalid Characters Response:', response
    * match response.data.checkUsername == null
    * match response.errors[0].errorInfo.statusCode == 400
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | username  | expectedMessage                                                  |
      | 1234      | can only contain letters, numbers, underscores, hyphens and dots |
      | true      | can only contain letters, numbers, underscores, hyphens and dots |
      | false     | can only contain letters, numbers, underscores, hyphens and dots |
      | --        | can only contain letters, numbers, underscores, hyphens and dots |