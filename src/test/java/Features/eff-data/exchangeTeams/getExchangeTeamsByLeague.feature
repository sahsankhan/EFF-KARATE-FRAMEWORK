Feature: EFF Data - Get Exchange Teams By League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def getExchangeTeamsByLeagueQuery = read('classpath:graphql/eff-data/exchangeTeams/getExchangeTeamsByLeague.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def extremePublicExchangeLeagueId = karate.get('signUpInfo.extremePublicExchangeLeagueId', null)
    * def privateExchangeTeamId = karate.get('signUpInfo.privateExchangeTeamId', null)
    * def privateExchangeTeamName = karate.get('signUpInfo.privateExchangeTeamName', null)
    * def buildLeagueData =
      """
      function(leagueId, existingAccessToken) {
        var idValue = leagueId;
        
        // Handle special keywords for dynamic values
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPublicExchangeLeagueId') idValue = extremePublicExchangeLeagueId;
        
        // Convert numeric strings to numbers
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        
        return { authToken: existingAccessToken, variables: { League_ID: idValue } };
      }
      """

  @missing_authorization_header
  Scenario Outline: GetExchangeTeamsByLeague fails when Authorization header is missing
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (extremePublicExchangeLeagueId == null) karate.abort()

    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(getExchangeTeamsByLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeamsByLeague Missing Token Response:', response
    * match response.data.getExchangeTeamsByLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                         | expectedStatus | expectedMessage         | expectedErrorCode |
      | existingPublicExchangeLeagueId   | 400            | Missing token in header | MISSING_TOKEN     |

  @expired_token
  Scenario Outline: GetExchangeTeamsByLeague fails with expired token
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (extremePublicExchangeLeagueId == null) karate.abort()

    * def expiredToken = '<expiredToken>'
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = expiredToken
    * def payload = { query: '#(getExchangeTeamsByLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeamsByLeague Expired Token Response:', response
    * match response.data.getExchangeTeamsByLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                         | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage | expectedErrorCode |
      | existingPublicExchangeLeagueId   | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   | EXPIRED_TOKEN     |

  @invalid_token
  Scenario Outline: GetExchangeTeamsByLeague fails with invalid or corrupted token
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (extremePublicExchangeLeagueId == null) karate.abort()

    * def invalidToken = '<invalidToken>'
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = invalidToken
    * def payload = { query: '#(getExchangeTeamsByLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeamsByLeague Invalid Token Response:', response
    * match response.data.getExchangeTeamsByLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                        | invalidToken                      | expectedStatus | expectedMessage | expectedErrorCode |
      | existingPublicExchangeLeagueId  | invalid.token.string              | 401            | Invalid token   | INVALID_TOKEN     |
      | existingPublicExchangeLeagueId  | random_corrupted_string_12345     | 401            | Invalid token   | INVALID_TOKEN     |
      | existingPublicExchangeLeagueId  | Bearer invalidtoken123            | 401            | Invalid token   | INVALID_TOKEN     |

  @happy_path
  Scenario Outline: GetExchangeTeamsByLeague successfully retrieves all teams in the league
    # PREREQUISITE CHECK: Ensure access token and league ID exist and season is preseason
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremePublicExchangeLeagueId == null) karate.abort()
    * if (privateExchangeTeamId == null) karate.abort()
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getExchangeTeamsByLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeamsByLeague Public League Success Response:', response
    * match response.data.getExchangeTeamsByLeague.statusCode == <expectedStatus>
    * match response.data.getExchangeTeamsByLeague.teams == '#array'
    * match response.data.getExchangeTeamsByLeague.teams == '#notnull'
    
    # Validate that teams array is not empty
    * def teamsCount = response.data.getExchangeTeamsByLeague.teams.length
    * assert teamsCount > 0
    * print 'Total Teams in League:', teamsCount
    
    # Find the user's created team in the league results
    * def userTeam = karate.filter(response.data.getExchangeTeamsByLeague.teams, function(team){ return team._id == privateExchangeTeamId + '' })
    * assert userTeam.length == 1
    * print 'Found User Created Team in League:', userTeam[0]
    
    # Validate the user's team data
    * def team = userTeam[0]
    * match team._id == privateExchangeTeamId + ''
    * match team.Team_Name == privateExchangeTeamName
    * match team.League_ID == extremePublicExchangeLeagueId
    * match team.Owner_Email == signUpInfo.email
    
    # Validate league details
    * match team.league_details == '#present'
    * match team.league_details.Game_Type == 'EXTREME'
    * match team.league_details.League_Type == 'EXCHANGE'

    Examples:
      | leagueId                        | expectedStatus |
      | existingPublicExchangeLeagueId  | 200            |

  @league_not_found
  Scenario Outline: GetExchangeTeamsByLeague fails when league ID does not exist
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getExchangeTeamsByLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeamsByLeague League Not Found Response:', response
    * match response.data.getExchangeTeamsByLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId | expectedStatus | expectedMessage    | expectedErrorCode |
      | 999999   | 404            | League not found   | LEAGUE_NOT_FOUND  |
      | 100000   | 404            | League not found   | LEAGUE_NOT_FOUND  |
      | 888888   | 404            | League not found   | LEAGUE_NOT_FOUND  |

  @invalid_league_id
  Scenario Outline: GetExchangeTeamsByLeague fails with invalid league ID format
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getExchangeTeamsByLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeamsByLeague Invalid League ID Response:', response
    * match response.data.getExchangeTeamsByLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId     | expectedStatus | expectedMessage                  | expectedErrorCode   |
      | invalid      | 400            | League_ID must be a numeric ID.  | INVALID_LEAGUE_ID   |
      | abc123       | 400            | League_ID must be a numeric ID.  | INVALID_LEAGUE_ID   |
      | league_id    | 400            | League_ID must be a numeric ID.  | INVALID_LEAGUE_ID   |
      | 0            | 400            | Invalid League_ID format         | INVALID_LEAGUE_ID   |
      | -100000      | 400            | Invalid League_ID format         | INVALID_LEAGUE_ID   |
      | -999999      | 400            | Invalid League_ID format         | INVALID_LEAGUE_ID   |
