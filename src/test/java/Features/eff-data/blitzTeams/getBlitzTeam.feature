Feature: EFF Data - Get Blitz Team API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def getBlitzTeamQuery = read('classpath:graphql/eff-data/blitzTeams/getBlitzTeam.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def privateBlitzTeamId = karate.get('signUpInfo.privateBlitzTeamId', null)
    * def privateBlitzTeamName = karate.get('signUpInfo.privateBlitzTeamName', null)
    * def extremePublicBlitzLeagueId = karate.get('signUpInfo.extremePublicBlitzLeagueId', null)

    * def buildTeamData =
      """
      function(teamId, existingAccessToken) {
        var idValue = teamId;
        
        // Handle special keywords for dynamic values
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPrivateBlitzTeamId') idValue = privateBlitzTeamId;
        
        // Convert numeric strings to numbers
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        
        return { authToken: existingAccessToken, variables: { Team_ID: idValue } };
      }
      """

  @missing_authorization_header
  Scenario Outline: GetBlitzTeam fails when Authorization header is missing
    # PREREQUISITE CHECK: Ensure team ID exists
    * if (privateBlitzTeamId == null) karate.abort()

    * def build = buildTeamData('<teamId>', existingAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(getBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeam Missing Token Response:', response
    * match response.data.getBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamId                       | expectedStatus | expectedMessage         | expectedErrorCode   |
      | existingPrivateBlitzTeamId   | 400            | Missing token in header | MISSING_TOKEN       |

  @expired_token
  Scenario Outline: GetBlitzTeam fails with expired token
    # PREREQUISITE CHECK: Ensure team ID exists
    * if (privateBlitzTeamId == null) karate.abort()

    * def expiredToken = '<expiredToken>'
    * def build = buildTeamData('<teamId>', existingAccessToken)
    * header Authorization = expiredToken
    * def payload = { query: '#(getBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeam Expired Token Response:', response
    * match response.data.getBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamId                      | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage | expectedErrorCode   |
      | existingPrivateBlitzTeamId  | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   | EXPIRED_TOKEN       |

  @invalid_token
  Scenario Outline: GetBlitzTeam fails with invalid or corrupted token
    # PREREQUISITE CHECK: Ensure team ID exists
    * if (privateBlitzTeamId == null) karate.abort()

    * def invalidToken = '<invalidToken>'
    * def build = buildTeamData('<teamId>', existingAccessToken)
    * header Authorization = invalidToken
    * def payload = { query: '#(getBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeam Invalid Token Response:', response
    * match response.data.getBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamId                      | invalidToken                      | expectedStatus | expectedMessage | expectedErrorCode   |
      | existingPrivateBlitzTeamId  | invalid.token.string              | 401            | Invalid token   | INVALID_TOKEN       |  
      | existingPrivateBlitzTeamId  | random_corrupted_string_12345     | 401            | Invalid token   | INVALID_TOKEN       |
      | existingPrivateBlitzTeamId  | Bearer invalidtoken123            | 401            | Invalid token   | INVALID_TOKEN       |

  @happy_path
  Scenario Outline: GetBlitzTeam succeeds when owner retrieves their own team
    # PREREQUISITE CHECK: Ensure access token and team ID exist and season is preseason
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')
    * if (privateBlitzTeamId == null) karate.abort()
    
    * def build = buildTeamData('<teamId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeam Success Response:', response
    * match response.data.getBlitzTeam.statusCode == <expectedStatus>
    * match response.data.getBlitzTeam.teams == '#array'
    * match response.data.getBlitzTeam.teams[0] == '#present'
    
    # Validate team data
    * def team = response.data.getBlitzTeam.teams[0]
    * match team._id == privateBlitzTeamId + ''
    * match team.Team_Name == privateBlitzTeamName
    * match team.League_ID == extremePublicBlitzLeagueId
    * match team.Owner_Email == signUpInfo.email
    
    # Validate league details
    * match team.league_details == '#present'
    * match team.league_details.Game_Type == 'EXTREME'
    * match team.league_details.League_Type == 'BLITZ'
    * match team.league_details.Public == true
    
    Examples:
      | teamId                      | expectedStatus  | 
      | existingPrivateBlitzTeamId  | 200             | 

  @team_not_found
  Scenario Outline: GetBlitzTeam fails when team ID does not exist
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamData('<teamId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeam Team Not Found Response:', response
    * match response.data.getBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamId  | expectedStatus | expectedMessage             | expectedErrorCode   |
      | 999999  | 404            | Team not found or deleted   | TEAM_NOT_FOUND      |
      | 100000  | 404            | Team not found or deleted   | TEAM_NOT_FOUND      |
      | 888888  | 404            | Team not found or deleted   | TEAM_NOT_FOUND      |

  @invalid_team_id
  Scenario Outline: GetBlitzTeam fails with invalid team ID format
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamData('<teamId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeam Invalid Team ID Response:', response
    * match response.data.getBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamId     | expectedStatus | expectedMessage                | expectedErrorCode   |
      | invalid    | 400            | Team_ID must be a numeric ID   | INVALID_TEAM_ID     |
      | abc123     | 400            | Team_ID must be a numeric ID   | INVALID_TEAM_ID     |
      | team_id    | 400            | Team_ID must be a numeric ID   | INVALID_TEAM_ID     |
      | 0          | 400            | Invalid Team_ID format         | INVALID_TEAM_ID     |
      | -100000    | 400            | Invalid Team_ID format         | INVALID_TEAM_ID     |
      | -999999    | 400            | Invalid Team_ID format         | INVALID_TEAM_ID     |