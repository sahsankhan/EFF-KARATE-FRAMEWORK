Feature: EFF Data - Check Blitz Team Name API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def checkBlitzTeamNameQuery = read('classpath:resources/graphql/eff-data/blitzTeams/checkBlitzTeamName.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def buildTeamNameData =
      """
      function(teamName, leagueId, existingAccessToken) {
        var nameValue = teamName;
        var idValue = leagueId;
        if (nameValue === 'null') nameValue = null;
        if (nameValue === 'true') nameValue = true;
        if (nameValue === 'false') nameValue = false;
        if (idValue === 'null') idValue = null;
        if (!isNaN(nameValue) && nameValue !== '' && nameValue !== null) {
          nameValue = Number(nameValue);
        }     
        return { authToken: existingAccessToken, variables: { Team_Name: nameValue, League_ID: idValue } };
      }
      """

  @missing_authorization_header
  Scenario Outline: CheckBlitzTeamName fails when Authorization header is missing
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
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName       | leagueId      | expectedStatus | expectedMessage           |
      | Valid Team     | 1             | 400            | Missing token in header   |

  @expired_token
  Scenario Outline: CheckBlitzTeamName fails with expired token
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
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName       | leagueId      | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage |
      | Valid Team     | 1             | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired         |

  @invalid_token
  Scenario Outline: CheckBlitzTeamName fails with invalid or corrupted token
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
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName       | leagueId      | invalidToken                          | expectedStatus | expectedMessage   |
      | Valid Team     | 1             | invalid.token.string                  | 401            | Invalid token     |
      | Valid Team     | 1             | random_corrupted_string_12345         | 401            | Invalid token     |
      | Valid Team     | 1             | Bearer invalidtoken123                | 401            | Invalid token     |

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
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | teamName       | leagueId     | expectedStatus  | expectedMessage                |
      | Valid Team     | 123456       | 404             | League not found or deleted.   |

  @happy_path_available
  Scenario Outline: CheckBlitzTeamName succeeds when team name is available
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
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
      | teamName                    | leagueId      | expectedStatus | expectedMessage            | expectedValid |
      | Available Team Name         | 1             | 200            | Team name is available.    | true          |

  @team_name_taken
  Scenario Outline: CheckBlitzTeamName fails when team name is already taken in the league
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName Taken Response:', response
    * match response.data.checkBlitzTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | teamName              | leagueId      | expectedStatus | expectedMessage                                     |
      | EFF Blitz Team        | 1             | 409            | A team with this name already exists in this league.|

  @team_name_too_short
  Scenario Outline: CheckBlitzTeamName fails when team name is less than 3 characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName Too Short Response:', response
    * match response.data.checkBlitzTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName | leagueId      | expectedStatus | expectedMessage                           |
      | A        | 1             | 400            | Team name must be at least 3 characters.  |
      | AB       | 1             | 400            | Team name must be at least 3 characters.  |
      | 1        | 1             | 400            | Team name must be at least 3 characters.  |
      | 12       | 1             | 400            | Team name must be at least 3 characters.  |

  @team_name_too_long
  Scenario Outline: CheckBlitzTeamName fails when team name exceeds 50 characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName Too Long Response:', response
    * match response.data.checkBlitzTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName                                               | leagueId      | expectedStatus | expectedMessage                                                                               |
      | This is a very long team name that exceeds fifty chars | 1             | 400            | Team name cannot exceed 50 characters                                                         |
      | !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot.  |
      | ------------------------------------------------------ | 1             | 400            | Team name cannot exceed 50 characters                                                         |

  @invalid_team_name_characters
  Scenario Outline: CheckBlitzTeamName fails when team name contains invalid characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName Invalid Characters Response:', response
    * match response.data.checkBlitzTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | teamName        | leagueId      | expectedStatus | expectedMessage                                                                              |
      | Team@Name       | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team#Name       | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team$Name       | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team%Name       | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team&Name       | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team*Name       | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team!Name       | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team(Name)      | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team[Name]      | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team{Name}      | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team/Name       | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team+Name       | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team=Name       | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team,Name       | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team;Name       | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team:Name       | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team"Name"      | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team<Name>      | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team?Name       | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team\\Name      | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team~Name       | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | Team`Name       | 1             | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |

  @team_name_without_letters
  Scenario Outline: CheckBlitzTeamName fails when team name contains no letters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName No Letters Response:', response
    * match response.data.checkBlitzTeamName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName | leagueId      | expectedStatus | expectedMessage                             |
      | 123      | 1             | 400            | Team name must contain at least one letter. |
      | ---      | 1             | 400            | Team name must contain at least one letter. |
      | 123-456  | 1             | 400            | Team name must contain at least one letter. |

  @whitespace_handling
  Scenario Outline: CheckBlitzTeamName with various whitespace scenarios
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName Whitespace Response:', response
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
     | teamName                  | leagueId      | expectedStatus | expectedMessage                                         | 
     | EFF    Blitz     Team     | 1             | 409            | A team with this name already exists in this league.    |
     | E F F B l i t z T e a m   | 1             | 409            | A team with this name already exists in this league.    |

  @case_sensitive_handling
  Scenario Outline: CheckBlitzTeamName with case sensitivity scenarios
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamNameData('<teamName>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzTeamNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzTeamName Case Sensitivity Response:', response
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
     | teamName         | leagueId      | expectedStatus | expectedMessage                                       |
     | eff blitz team   | 1             | 409            | A team with this name already exists in this league.  |
     | EFF BLITZ TEAM   | 1             | 409            | A team with this name already exists in this league.  |
