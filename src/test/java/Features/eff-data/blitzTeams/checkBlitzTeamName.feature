Feature: EFF Data - Check Blitz Team Name API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def checkBlitzTeamNameQuery = read('classpath:graphql/eff-data/blitzTeams/checkBlitzTeamName.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def extremePublicBlitzLeagueId = karate.get('signUpInfo.extremePublicBlitzLeagueId', null)
    * def buildTeamNameData =
      """
      function(teamName, leagueId, existingAccessToken, privateBlitzTeamName) {
        var nameValue = teamName;
        var idValue = leagueId;
        if (nameValue === 'privateBlitzTeamName') nameValue = privateBlitzTeamName;
        if (nameValue === 'null') nameValue = null;
        if (nameValue === 'true') nameValue = true;
        if (nameValue === 'false') nameValue = false;
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPublicBlitzLeagueId') idValue = extremePublicBlitzLeagueId;
        if (!isNaN(nameValue) && nameValue !== '' && nameValue !== null) {
          nameValue = Number(nameValue);
        }
        
        // Handle whitespace and case transformations
        if (privateBlitzTeamName) {
          if (nameValue === 'UPPER') nameValue = privateBlitzTeamName.toUpperCase();
          if (nameValue === 'LOWER') nameValue = privateBlitzTeamName.toLowerCase();
          if (nameValue === 'MIXED_SPACES') nameValue = '   ' + privateBlitzTeamName.replace(/ /g, '    ') + '   ';
          if (nameValue === 'NO_SPACES') nameValue = privateBlitzTeamName.replace(/ /g, '');
          if (nameValue === 'SPACED_LETTERS') nameValue = privateBlitzTeamName.split('').join(' ');
        }
        
        return { authToken: existingAccessToken, variables: { Team_Name: nameValue, League_ID: idValue } };
      }
      """

  @missing_authorization_header
  Scenario Outline: CheckBlitzTeamName fails when Authorization header is missing
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (extremePublicBlitzLeagueId == null) karate.abort()

    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * def variables = build.variables
    # Do not set Authorization header
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(variables)' }

    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName Missing Token Response:', response
    * match response.data.checkBlitzTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName       | leagueId                     | expectedStatus | expectedMessage           | expectedErrorCode   |
      | Valid Team     | existingPublicBlitzLeagueId  | 400            | Missing token in header   | MISSING_TOKEN       |

  @expired_token
  Scenario Outline: CheckBlitzTeamName fails with expired token
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (extremePublicBlitzLeagueId == null) karate.abort()

    * def expiredToken = '<expiredToken>'
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * def variables = build.variables
    * header Authorization = expiredToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName Expired Token Response:', response
    * match response.data.checkBlitzTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName       | leagueId                     | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage | expectedErrorCode   |
      | Valid Team     | existingPublicBlitzLeagueId  | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired         | EXPIRED_TOKEN       |

  @invalid_token
  Scenario Outline: CheckBlitzTeamName fails with invalid or corrupted token
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (extremePublicBlitzLeagueId == null) karate.abort()

    * def invalidToken = '<invalidToken>'
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * def variables = build.variables
    * header Authorization = invalidToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName Invalid Token Response:', response
    * match response.data.checkBlitzTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName       | leagueId                       | invalidToken                          | expectedStatus | expectedMessage   | expectedErrorCode   |
      | Valid Team     | existingPublicBlitzLeagueId    | invalid.token.string                  | 401            | Invalid token     | INVALID_TOKEN       |
      | Valid Team     | existingPublicBlitzLeagueId    | random_corrupted_string_12345         | 401            | Invalid token     | INVALID_TOKEN       |
      | Valid Team     | existingPublicBlitzLeagueId    | Bearer invalidtoken123                | 401            | Invalid token     | INVALID_TOKEN       |

  @league_not_found
  Scenario Outline: CheckBlitzTeamName fails when league ID does not exist
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName League Not Found Response:', response
    * match response.data.checkBlitzTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName       | leagueId     | expectedStatus  | expectedMessage                | expectedErrorCode   |
      | Valid Team     | 123456       | 404             | League not found or deleted.   | LEAGUE_NOT_FOUND    |

  @happy_path_available
  Scenario Outline: CheckBlitzTeamName succeeds when team name is available
    # PREREQUISITE CHECK: Ensure access token and public league exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremePublicBlitzLeagueId == null) karate.abort()

    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName Available Response:', response
    * match response.data.checkBlitzTeamName.statusCode == <expectedStatus>
    * match response.data.checkBlitzTeamName.message == '<expectedMessage>'
    * match response.data.checkBlitzTeamName.valid == <expectedValid>

    Examples:
      | teamName                    | leagueId                      | expectedStatus | expectedMessage            | expectedValid |
      | Available Team Name         | existingPublicBlitzLeagueId   | 200            | Team name is available.    | true          |

  @team_name_taken
  Scenario Outline: CheckBlitzTeamName fails when team name is already taken in the league
    # PREREQUISITE CHECK: Ensure access token and created team name exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (signUpInfo.privateBlitzTeamName == null) karate.fail('No created team name found. Run @happy_path scenario from createBlitzTeam.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken, signUpInfo.privateBlitzTeamName)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName Taken Response:', response
    * match response.data.checkBlitzTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName             | leagueId                      | expectedStatus | expectedMessage                                     | expectedErrorCode   |
      | privateBlitzTeamName | existingPublicBlitzLeagueId   | 409            | A team with this name already exists in this league.| TEAM_NAME_TAKEN     |

  @team_name_too_short
  Scenario Outline: CheckBlitzTeamName fails when team name is less than 3 characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremePublicBlitzLeagueId == null) karate.abort()

    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName Too Short Response:', response
    * match response.data.checkBlitzTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName | leagueId                      | expectedStatus | expectedMessage                           | expectedErrorCode   |
      | A        | existingPublicBlitzLeagueId   | 400            | Team name must be at least 3 characters.  | TEAM_NAME_TOO_SHORT |
      | AB       | existingPublicBlitzLeagueId   | 400            | Team name must be at least 3 characters.  | TEAM_NAME_TOO_SHORT |
      | 1        | existingPublicBlitzLeagueId   | 400            | Team name must be at least 3 characters.  | TEAM_NAME_TOO_SHORT |
      | 12       | existingPublicBlitzLeagueId   | 400            | Team name must be at least 3 characters.  | TEAM_NAME_TOO_SHORT |

  @team_name_too_long
  Scenario Outline: CheckBlitzTeamName fails when team name exceeds 50 characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremePublicBlitzLeagueId == null) karate.abort()

    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName Too Long Response:', response
    * match response.data.checkBlitzTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName                                               | leagueId                      | expectedStatus | expectedMessage                                                                               | expectedErrorCode   |
      | This is a very long team name that exceeds fifty chars | existingPublicBlitzLeagueId   | 400            | Team name cannot exceed 50 characters                                                         | TEAM_NAME_TOO_LONG  | 
      | !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot.  | INVALID_TEAM_NAME   |
      | ------------------------------------------------------ | existingPublicBlitzLeagueId   | 400            | Team name cannot exceed 50 characters                                                         | TEAM_NAME_TOO_LONG  |

  @invalid_team_name_characters
  Scenario Outline: CheckBlitzTeamName fails when team name contains invalid characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremePublicBlitzLeagueId == null) karate.abort()

    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName Invalid Characters Response:', response
    * match response.data.checkBlitzTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName        | leagueId                      | expectedStatus | expectedMessage                                                                              | expectedErrorCode   |
      | Team@Name       | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team#Name       | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team$Name       | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team%Name       | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team&Name       | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team*Name       | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team!Name       | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team(Name)      | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team[Name]      | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team{Name}      | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team/Name       | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team+Name       | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team=Name       | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team,Name       | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team;Name       | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team:Name       | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team"Name"      | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team<Name>      | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team?Name       | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team\\Name      | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team~Name       | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team`Name       | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |

  @team_name_without_letters
  Scenario Outline: CheckBlitzTeamName fails when team name contains no letters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremePublicBlitzLeagueId == null) karate.abort()

    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName No Letters Response:', response
    * match response.data.checkBlitzTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName | leagueId                       | expectedStatus | expectedMessage                             | expectedErrorCode   |
      | 123      | existingPublicBlitzLeagueId    | 400            | Team name must contain at least one letter. | TEAM_NAME_NO_LETTER |
      | ---      | existingPublicBlitzLeagueId    | 400            | Team name must contain at least one letter. | TEAM_NAME_NO_LETTER |
      | 123-456  | existingPublicBlitzLeagueId    | 400            | Team name must contain at least one letter. | TEAM_NAME_NO_LETTER |

  @whitespace_handling
  Scenario Outline: CheckBlitzTeamName with various whitespace scenarios
    # PREREQUISITE CHECK: Ensure access token and created team name exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (signUpInfo.privateBlitzTeamName == null) karate.fail('No created team name found. Run @happy_path scenario from createBlitzTeam.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken, signUpInfo.privateBlitzTeamName)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName Whitespace Response:', response
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
     | teamName       | leagueId                      | expectedStatus | expectedMessage                                         | expectedErrorCode   | 
     | UPPER          | existingPublicBlitzLeagueId   | 409            | A team with this name already exists in this league.    | TEAM_NAME_TAKEN     |
     | MIXED_SPACES   | existingPublicBlitzLeagueId   | 409            | A team with this name already exists in this league.    | TEAM_NAME_TAKEN     |
     | NO_SPACES      | existingPublicBlitzLeagueId   | 409            | A team with this name already exists in this league.    | TEAM_NAME_TAKEN     |
     | SPACED_LETTERS | existingPublicBlitzLeagueId   | 409            | A team with this name already exists in this league.    | TEAM_NAME_TAKEN     |

  @case_sensitive_handling
  Scenario Outline: CheckBlitzTeamName with case sensitivity scenarios
    # PREREQUISITE CHECK: Ensure access token and created team name exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (signUpInfo.privateBlitzTeamName == null) karate.fail('No created team name found. Run @happy_path scenario from createBlitzTeam.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken, signUpInfo.privateBlitzTeamName)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName Case Sensitivity Response:', response
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
     | teamName | leagueId                      | expectedStatus | expectedMessage                                       | expectedErrorCode   |
     | LOWER    | existingPublicBlitzLeagueId   | 409            | A team with this name already exists in this league.  | TEAM_NAME_TAKEN     |
     | UPPER    | existingPublicBlitzLeagueId   | 409            | A team with this name already exists in this league.  | TEAM_NAME_TAKEN     |
