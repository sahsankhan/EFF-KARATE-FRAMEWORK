Feature: EFF Data - Get Exchange Team API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def getExchangeTeamQuery = read('classpath:graphql/eff-data/exchangeTeams/getExchangeTeam.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def privateExchangeTeamId = karate.get('signUpInfo.privateExchangeTeamId', null)
    * def privateExchangeTeamName = karate.get('signUpInfo.privateExchangeTeamName', null)
    * def extremePublicExchangeLeagueId = karate.get('signUpInfo.extremePublicExchangeLeagueId', null)

    * def buildTeamData =
      """
      function(teamId, existingAccessToken) {
        var idValue = teamId;
        
        // Handle special keywords for dynamic values
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPrivateExchangeTeamId') idValue = privateExchangeTeamId;
        
        // Convert numeric strings to numbers
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        
        return { authToken: existingAccessToken, variables: { Team_ID: idValue } };
      }
      """

  @missing_authorization_header
  Scenario Outline: GetExchangeTeam fails when Authorization header is missing
    # PREREQUISITE CHECK: Ensure team ID exists
    * if (privateExchangeTeamId == null) karate.abort()

    * def build = buildTeamData('<teamId>', existingAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(getExchangeTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeam Missing Token Response:', response
    * match response.data.getExchangeTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamId                          | expectedStatus | expectedMessage         | expectedErrorCode   |
      | existingPrivateExchangeTeamId   | 400            | Missing token in header | MISSING_TOKEN       |

  @expired_token
  Scenario Outline: GetExchangeTeam fails with expired token
    # PREREQUISITE CHECK: Ensure team ID exists
    * if (privateExchangeTeamId == null) karate.abort()

    * def expiredToken = '<expiredToken>'
    * def build = buildTeamData('<teamId>', existingAccessToken)
    * header Authorization = expiredToken
    * def payload = { query: '#(getExchangeTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeam Expired Token Response:', response
    * match response.data.getExchangeTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamId                         | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage | expectedErrorCode   |
      | existingPrivateExchangeTeamId  | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   | EXPIRED_TOKEN       |

  @invalid_token
  Scenario Outline: GetExchangeTeam fails with invalid or corrupted token
    # PREREQUISITE CHECK: Ensure team ID exists
    * if (privateExchangeTeamId == null) karate.abort()

    * def invalidToken = '<invalidToken>'
    * def build = buildTeamData('<teamId>', existingAccessToken)
    * header Authorization = invalidToken
    * def payload = { query: '#(getExchangeTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeam Invalid Token Response:', response
    * match response.data.getExchangeTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamId                         | invalidToken                      | expectedStatus | expectedMessage | expectedErrorCode   |
      | existingPrivateExchangeTeamId  | invalid.token.string              | 401            | Invalid token   | INVALID_TOKEN       |  
      | existingPrivateExchangeTeamId  | random_corrupted_string_12345     | 401            | Invalid token   | INVALID_TOKEN       |
      | existingPrivateExchangeTeamId  | Bearer invalidtoken123            | 401            | Invalid token   | INVALID_TOKEN       |

  @happy_path
  Scenario Outline: GetExchangeTeam succeeds when owner retrieves their own team
    # PREREQUISITE CHECK: Ensure access token and team ID exist and season is preseason
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (privateExchangeTeamId == null) karate.abort()
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')
    
    * def build = buildTeamData('<teamId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getExchangeTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeam Success Response:', response
    * match response.data.getExchangeTeam.statusCode == <expectedStatus>
    * match response.data.getExchangeTeam.teams == '#array'
    * match response.data.getExchangeTeam.teams[0] == '#present'
    
    # Validate team data
    * def team = response.data.getExchangeTeam.teams[0]
    * match team._id == privateExchangeTeamId + ''
    * match team.Team_Name == privateExchangeTeamName
    * match team.League_ID == extremePublicExchangeLeagueId
    * match team.Owner_Email == signUpInfo.email
    
    # Validate league details
    * match team.league_details == '#present'
    * match team.league_details.Game_Type == 'EXTREME'
    * match team.league_details.League_Type == 'EXCHANGE'
    * match team.league_details.Public == true
    
    Examples:
      | teamId                         | expectedStatus  | 
      | existingPrivateExchangeTeamId  | 200             | 

  @team_not_found
  Scenario Outline: GetExchangeTeam fails when team ID does not exist
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamData('<teamId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getExchangeTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeam Team Not Found Response:', response
    * match response.data.getExchangeTeam == null
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
  Scenario Outline: GetExchangeTeam fails with invalid team ID format
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamData('<teamId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getExchangeTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeam Invalid Team ID Response:', response
    * match response.data.getExchangeTeam == null
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