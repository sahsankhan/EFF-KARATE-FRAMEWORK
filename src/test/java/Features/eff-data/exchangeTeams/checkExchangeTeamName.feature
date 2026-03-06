Feature: EFF Data - Check Exchange Team Name API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def checkExchangeTeamNameQuery = read('classpath:graphql/eff-data/exchangeTeams/checkExchangeTeamName.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def extremePublicExchangeLeagueId = karate.get('signUpInfo.extremePublicExchangeLeagueId', null)
    * def buildTeamNameData =
      """
      function(teamName, leagueId, existingAccessToken, privateExchangeTeamName) {
        var nameValue = teamName;
        var idValue = leagueId;
        if (nameValue === 'privateExchangeTeamName') nameValue = privateExchangeTeamName;
        if (nameValue === 'null') nameValue = null;
        if (nameValue === 'true') nameValue = true;
        if (nameValue === 'false') nameValue = false;
        if (idValue === 'null') idValue = null;
        if (idValue === 'extremePublicExchangeLeagueId') idValue = extremePublicExchangeLeagueId;
        if (!isNaN(nameValue) && nameValue !== '' && nameValue !== null) {
          nameValue = Number(nameValue);
        }  
   
        // Handle whitespace and case transformations
        if (privateExchangeTeamName) {
          if (nameValue === 'UPPER') nameValue = privateExchangeTeamName.toUpperCase();
          if (nameValue === 'LOWER') nameValue = privateExchangeTeamName.toLowerCase();
          if (nameValue === 'MIXED_SPACES') nameValue = '   ' + privateExchangeTeamName.replace(/ /g, '    ') + '   ';
          if (nameValue === 'NO_SPACES') nameValue = privateExchangeTeamName.replace(/ /g, '');
          if (nameValue === 'SPACED_LETTERS') nameValue = privateExchangeTeamName.split('').join(' ');
        }   
        
        return { authToken: existingAccessToken, variables: { Team_Name: nameValue, League_ID: idValue } };
      }
      """

  @missing_authorization_header
  Scenario Outline: CheckExchangeTeamName fails when Authorization header is missing
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * def variables = build.variables
    # Do not set Authorization header
    * def payload = { query: '#(checkExchangeTeamNameQuery)', variables: '#(variables)' }

    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeTeamName Missing Token Response:', response
    * match response.data.checkExchangeTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName       | leagueId                       | expectedStatus | expectedMessage           | expectedErrorCode   |
      | Valid Team     | extremePublicExchangeLeagueId  | 400            | Missing token in header   | MISSING_TOKEN       |

  @expired_token
  Scenario Outline: CheckExchangeTeamName fails with expired token
    * def expiredToken = '<expiredToken>'
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * def variables = build.variables
    * header Authorization = expiredToken
    * def payload = { query: '#(checkExchangeTeamNameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeTeamName Expired Token Response:', response
    * match response.data.checkExchangeTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName       | leagueId                      | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage | expectedErrorCode   |
      | Valid Team     | extremePublicExchangeLeagueId | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired         | EXPIRED_TOKEN       |

  @invalid_token
  Scenario Outline: CheckExchangeTeamName fails with invalid or corrupted token
    * def invalidToken = '<invalidToken>'
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * def variables = build.variables
    * header Authorization = invalidToken
    * def payload = { query: '#(checkExchangeTeamNameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeTeamName Invalid Token Response:', response
    * match response.data.checkExchangeTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName       | leagueId                        | invalidToken                          | expectedStatus | expectedMessage   | expectedErrorCode   |
      | Valid Team     | extremePublicExchangeLeagueId   | invalid.token.string                  | 401            | Invalid token     | INVALID_TOKEN       |
      | Valid Team     | extremePublicExchangeLeagueId   | random_corrupted_string_12345         | 401            | Invalid token     | INVALID_TOKEN       |
      | Valid Team     | extremePublicExchangeLeagueId   | Bearer invalidtoken123                | 401            | Invalid token     | INVALID_TOKEN       |

  @league_not_found
  Scenario Outline: CheckExchangeTeamName fails when league ID does not exist
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkExchangeTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeTeamName League Not Found Response:', response
    * match response.data.checkExchangeTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName       | leagueId     | expectedStatus  | expectedMessage              | expectedErrorCode   |
      | Valid Team     | 123456       | 404             | League not found or deleted. | LEAGUE_NOT_FOUND    |

  @happy_path_available
  Scenario Outline: CheckExchangeTeamName succeeds when team name is available
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkExchangeTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeTeamName Available Response:', response
    * match response.data.checkExchangeTeamName.statusCode == <expectedStatus>
    * match response.data.checkExchangeTeamName.message == '<expectedMessage>'
    * match response.data.checkExchangeTeamName.valid == <expectedValid>

    Examples:
      | teamName                    | leagueId                       | expectedStatus | expectedMessage            | expectedValid |
      | Available Team Name         | extremePublicExchangeLeagueId  | 200            | Team name is available.    | true          |

  @team_name_taken
  Scenario Outline: CheckExchangeTeamName fails when team name is already taken in the league
    # PREREQUISITE CHECK: Ensure access token and created team name exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (signUpInfo.privateExchangeTeamName == null) karate.fail('No created team name found. Run @happy_path scenario from createBlitzTeam.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken, signUpInfo.privateExchangeTeamName)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkExchangeTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeTeamName Taken Response:', response
    * match response.data.checkExchangeTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName                | leagueId                        | expectedStatus | expectedMessage                                     | expectedErrorCode   |
      | privateExchangeTeamName | extremePublicExchangeLeagueId   | 409            | A team with this name already exists in this league.| TEAM_NAME_TAKEN     |

  @team_name_too_short
  Scenario Outline: CheckExchangeTeamName fails when team name is less than 3 characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkExchangeTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeTeamName Too Short Response:', response
    * match response.data.checkExchangeTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName | leagueId                        | expectedStatus | expectedMessage                           | expectedErrorCode   |
      | A        | extremePublicExchangeLeagueId   | 400            | Team name must be at least 3 characters.  | TEAM_NAME_TOO_SHORT |
      | AB       | extremePublicExchangeLeagueId   | 400            | Team name must be at least 3 characters.  | TEAM_NAME_TOO_SHORT |
      | 1        | extremePublicExchangeLeagueId   | 400            | Team name must be at least 3 characters.  | TEAM_NAME_TOO_SHORT |
      | 12       | extremePublicExchangeLeagueId   | 400            | Team name must be at least 3 characters.  | TEAM_NAME_TOO_SHORT |

  @team_name_too_long
  Scenario Outline: CheckExchangeTeamName fails when team name exceeds 50 characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkExchangeTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeTeamName Too Long Response:', response
    * match response.data.checkExchangeTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName                                               | leagueId                      | expectedStatus | expectedMessage                                                                               | expectedErrorCode   |
      | This is a very long team name that exceeds fifty chars | extremePublicExchangeLeagueId | 400            | Team name cannot exceed 50 characters                                                         | TEAM_NAME_TOO_LONG  | 
      | !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! | extremePublicExchangeLeagueId | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot.  | INVALID_TEAM_NAME   |
      | ------------------------------------------------------ | extremePublicExchangeLeagueId | 400            | Team name cannot exceed 50 characters                                                         | TEAM_NAME_TOO_LONG  |

  @invalid_team_name_characters
  Scenario Outline: CheckExchangeTeamName fails when team name contains invalid characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkExchangeTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeTeamName Invalid Characters Response:', response
    * match response.data.checkExchangeTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName        | leagueId                       | expectedStatus | expectedMessage                                                                              | expectedErrorCode   |
      | Team@Name       | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team#Name       | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team$Name       | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team%Name       | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team&Name       | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team*Name       | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team!Name       | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team(Name)      | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team[Name]      | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team{Name}      | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team/Name       | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team+Name       | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team=Name       | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team,Name       | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team;Name       | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team:Name       | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team"Name"      | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team<Name>      | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team?Name       | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team\\Name      | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team~Name       | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |
      | Team`Name       | extremePublicExchangeLeagueId  | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_TEAM_NAME   |

  @team_name_without_letters
  Scenario Outline: CheckExchangeTeamName fails when team name contains no letters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkExchangeTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeTeamName No Letters Response:', response
    * match response.data.checkExchangeTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName | leagueId                       | expectedStatus | expectedMessage                             | expectedErrorCode    |
      | 123      | extremePublicExchangeLeagueId  | 400            | Team name must contain at least one letter. | TEAM_NAME_NO_LETTER  |
      | ---      | extremePublicExchangeLeagueId  | 400            | Team name must contain at least one letter. | TEAM_NAME_NO_LETTER  |
      | 123-456  | extremePublicExchangeLeagueId  | 400            | Team name must contain at least one letter. | TEAM_NAME_NO_LETTER  |

 @whitespace_handling
  Scenario Outline: CheckExchangeTeamName with various whitespace scenarios
    # PREREQUISITE CHECK: Ensure access to
    ken and created team name exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (signUpInfo.privateExchangeTeamName == null) karate.fail('No created team name found. Run @happy_path scenario from createBlitzTeam.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken, signUpInfo.privateExchangeTeamName)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkExchangeTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeTeamName Whitespace Response:', response
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
     | teamName       | leagueId                        | expectedStatus | expectedMessage                                         | expectedErrorCode   | 
     | UPPER          | extremePublicExchangeLeagueId   | 409            | A team with this name already exists in this league.    | TEAM_NAME_TAKEN     |
     | MIXED_SPACES   | extremePublicExchangeLeagueId   | 409            | A team with this name already exists in this league.    | TEAM_NAME_TAKEN     |
     | NO_SPACES      | extremePublicExchangeLeagueId   | 409            | A team with this name already exists in this league.    | TEAM_NAME_TAKEN     |
     | SPACED_LETTERS | extremePublicExchangeLeagueId   | 409            | A team with this name already exists in this league.    | TEAM_NAME_TAKEN     |

  @case_sensitive_handling
  Scenario Outline: CheckExchangeTeamName with case sensitivity scenarios
    # PREREQUISITE CHECK: Ensure access token and created team name exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (signUpInfo.privateExchangeTeamName == null) karate.fail('No created team name found. Run @happy_path scenario from createBlitzTeam.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken, signUpInfo.privateExchangeTeamName)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkExchangeTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeTeamName Case Sensitivity Response:', response
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
     | teamName | leagueId                        | expectedStatus | expectedMessage                                       | expectedErrorCode   |
     | LOWER    | extremePublicExchangeLeagueId   | 409            | A team with this name already exists in this league.  | TEAM_NAME_TAKEN     |
     | UPPER    | extremePublicExchangeLeagueId   | 409            | A team with this name already exists in this league.  | TEAM_NAME_TAKEN     |
