Feature: EFF Data - Get Blitz Teams by League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def getBlitzTeamsByLeagueQuery = read('classpath:graphql/eff-data/blitzTeams/getBlitzTeamsByLeague.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def extremePublicBlitzLeagueId = karate.get('signUpInfo.extremePublicBlitzLeagueId', null)
    * def privateBlitzTeamId = karate.get('signUpInfo.privateBlitzTeamId', null)
    * def privateBlitzTeamName = karate.get('signUpInfo.privateBlitzTeamName', null)
    * def buildLeagueData =
      """
      function(leagueId, existingAccessToken) {
        var idValue = leagueId;
        
        // Handle special keywords for dynamic values
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPublicBlitzLeagueId') idValue = extremePublicBlitzLeagueId;
        
        // Convert numeric strings to numbers
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        
        return { authToken: existingAccessToken, variables: { League_ID: idValue } };
      }
      """

  @missing_authorization_header
  Scenario Outline: GetBlitzTeamsByLeague fails when Authorization header is missing
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (extremePublicBlitzLeagueId == null) karate.abort()

    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(getBlitzTeamsByLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeamsByLeague Missing Token Response:', response
    * match response.data.getBlitzTeamsByLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                     | expectedStatus | expectedMessage         | expectedErrorCode   |
      | existingPublicBlitzLeagueId  | 400            | Missing token in header | MISSING_TOKEN       |

  @expired_token
  Scenario Outline: GetBlitzTeamsByLeague fails with expired token
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (extremePublicBlitzLeagueId == null) karate.abort()
    * if (privateBlitzTeamId == null) karate.abort()

    * def expiredToken = '<expiredToken>'
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = expiredToken
    * def payload = { query: '#(getBlitzTeamsByLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeamsByLeague Expired Token Response:', response
    * match response.data.getBlitzTeamsByLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                    | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage | expectedErrorCode   |
      | existingPublicBlitzLeagueId | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   | EXPIRED_TOKEN       |

  @invalid_token
  Scenario Outline: GetBlitzTeamsByLeague fails with invalid or corrupted token
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (extremePublicBlitzLeagueId == null) karate.abort()
    * if(privateBlitzTeamId == null) karate.abort()

    * def invalidToken = '<invalidToken>'
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = invalidToken
    * def payload = { query: '#(getBlitzTeamsByLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeamsByLeague Invalid Token Response:', response
    * match response.data.getBlitzTeamsByLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                     | invalidToken                      | expectedStatus | expectedMessage | expectedErrorCode   |
      | existingPublicBlitzLeagueId  | invalid.token.string              | 401            | Invalid token   | INVALID_TOKEN       |
      | existingPublicBlitzLeagueId  | random_corrupted_string_12345     | 401            | Invalid token   | INVALID_TOKEN       |
      | existingPublicBlitzLeagueId  | Bearer invalidtoken123            | 401            | Invalid token   | INVALID_TOKEN       |

  @happy_path
  Scenario Outline: GetBlitzTeamsByLeague successfully retrieves all teams in the league
    # PREREQUISITE CHECK: Ensure access token, league ID, and team ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremePublicBlitzLeagueId == null) karate.abort()
    * if (privateBlitzTeamId == null) karate.abort()
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getBlitzTeamsByLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeamsByLeague Success Response:', response
    * match response.data.getBlitzTeamsByLeague.statusCode == <expectedStatus>
    * match response.data.getBlitzTeamsByLeague.teams == '#array'
    * match response.data.getBlitzTeamsByLeague.teams == '#notnull'
    
    # Validate that teams array is not empty
    * def teamsCount = response.data.getBlitzTeamsByLeague.teams.length
    * assert teamsCount > 0
    * print 'Total Teams in League:', teamsCount
    
    # Find the user's created team in the league results
    * def userTeam = karate.filter(response.data.getBlitzTeamsByLeague.teams, function(team){ return team._id == privateBlitzTeamId + '' })
    * assert userTeam.length == 1
    * print 'Found User Created Team in League:', userTeam[0]
    
    # Validate the user's team data
    * def team = userTeam[0]
    * match team._id == privateBlitzTeamId + ''
    * match team.Team_Name == privateBlitzTeamName
    * match team.League_ID == extremePublicBlitzLeagueId
    * match team.Owner_Email == signUpInfo.email
    
    # Validate league details
    * match team.league_details == '#present'
    * match team.league_details.Game_Type == 'EXTREME'
    * match team.league_details.League_Type == 'BLITZ'

    Examples:
      | leagueId                     | expectedStatus | 
      | existingPublicBlitzLeagueId  | 200            | 

  @league_not_found
  Scenario Outline: GetBlitzTeamsByLeague fails when league ID does not exist
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getBlitzTeamsByLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeamsByLeague League Not Found Response:', response
    * match response.data.getBlitzTeamsByLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId | expectedStatus | expectedMessage                 | expectedErrorCode   |
      | 999999   | 404            | League not found or deleted     | LEAGUE_NOT_FOUND    |
      | 100000   | 404            | League not found or deleted     | LEAGUE_NOT_FOUND    |
      | 888888   | 404            | League not found or deleted     | LEAGUE_NOT_FOUND    |

  @invalid_league_id
  Scenario Outline: GetBlitzTeamsByLeague fails with invalid league ID format
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getBlitzTeamsByLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeamsByLeague Invalid League ID Response:', response
    * match response.data.getBlitzTeamsByLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId      | expectedStatus | expectedMessage                 | expectedErrorCode   |
      | invalid       | 400            | League_ID must be a numeric ID  | INVALID_LEAGUE_ID   |
      | abc123        | 400            | League_ID must be a numeric ID  | INVALID_LEAGUE_ID   |
      | league_id     | 400            | League_ID must be a numeric ID  | INVALID_LEAGUE_ID   |
      | 0             | 400            | Invalid League_ID format        | INVALID_LEAGUE_ID   |
      | -999999       | 400            | Invalid League_ID format        | INVALID_LEAGUE_ID   |
      | -100000       | 400            | Invalid League_ID format        | INVALID_LEAGUE_ID   |
