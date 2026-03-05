Feature: EFF Data - Join Public Exchange League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def joinPublicExchangeLeagueQuery = read('classpath:graphql/eff-data/exchangeLeagues/joinPublicExchangeLeague.graphql')
    * def getAvailablePublicExtremeLeaguesQuery = read('classpath:graphql/eff-data/leagues/getAvailableLeagues.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def extremePublicExchangeLeagueId = karate.get('signUpInfo.extremePublicExchangeLeagueId', null)
    * def buildLeagueData =
      """
      function(leagueId, existingAccessToken) {
        var idValue = leagueId;
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPublicExchangeLeagueId') idValue = extremePublicExchangeLeagueId;
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        return { authToken: existingAccessToken, variables: { League_ID: idValue } };
      }
      """

  @missing_authorization_header
  Scenario Outline: JoinPublicExchangeLeague fails when Authorization header is missing
    # PREREQUISITE CHECK: Ensure league ID exist
    * if (extremePublicExchangeLeagueId == null) karate.abort()
   
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(joinPublicExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPublicExchangeLeague Missing Token Response:', response
    * match response.data.joinPublicExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                         | expectedStatus | expectedMessage         | expectedErrorCode   |
      | existingPublicExchangeLeagueId   | 400            | Missing token in header | MISSING_TOKEN       |

  @expired_token
  Scenario Outline: JoinPublicExchangeLeague fails with expired token
    # PREREQUISITE CHECK: Ensure league ID exist
    * if (extremePublicExchangeLeagueId == null) karate.abort()

    * def expiredToken = '<expiredToken>'
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = expiredToken
    * def payload = { query: '#(joinPublicExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPublicExchangeLeague Expired Token Response:', response
    * match response.data.joinPublicExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                         | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage | expectedErrorCode   |
      | existingPublicExchangeLeagueId   | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   | EXPIRED_TOKEN       |

  @invalid_token
  Scenario Outline: JoinPublicExchangeLeague fails with invalid or corrupted token
    # PREREQUISITE CHECK: Ensure league ID exist
    * if (extremePublicExchangeLeagueId == null) karate.abort()

    * def invalidToken = '<invalidToken>'
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = invalidToken
    * def payload = { query: '#(joinPublicExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPublicExchangeLeague Invalid Token Response:', response
    * match response.data.joinPublicExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                         | invalidToken                      | expectedStatus | expectedMessage | expectedErrorCode   |
      | existingPublicExchangeLeagueId   | Bearer invalidtoken123            | 401            | Invalid token   | INVALID_TOKEN       |
      | existingPublicExchangeLeagueId   | random_corrupted_string_12345     | 401            | Invalid token   | INVALID_TOKEN       |
      | existingPublicExchangeLeagueId   | invalid.token.string              | 401            | Invalid token   | INVALID_TOKEN       |

  @happy_path
  Scenario Outline: JoinPublicExchangeLeague succeeds with valid public league ID
    # PREREQUISITE CHECK: Ensure access token and league ID exist and season is preseason
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')
    * if (extremePublicExchangeLeagueId == null) karate.abort()
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(joinPublicExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPublicExchangeLeague Success Response:', response
    * match response.data.joinPublicExchangeLeague.statusCode == <expectedStatus>
    * match response.data.joinPublicExchangeLeague.message == '<expectedMessage>'
    * match response.data.joinPublicExchangeLeague.League_ID == extremePublicExchangeLeagueId

    # Step 2: Verify available leagues shows only one blitz league 
    * def getLeaguesPayload = { query: '#(getAvailablePublicExtremeLeaguesQuery)' }
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * header Authorization = build.authToken

    Given request getLeaguesPayload
    When method post
    Then status 200
    * print 'GetAvailablePublicExtremeLeagues After Join Response:', response
    
    # Validate response structure - should show only blitz league as available
    * match response.data.getAvailableLeagues.statusCode == <expectedStatus>
    * match response.data.getAvailableLeagues.blitz_league == '#present'
    * match response.data.getAvailableLeagues.exchange_league == null

    Examples:
      | leagueId                         | expectedStatus | expectedMessage                             |
      | existingPublicExchangeLeagueId   | 200            | Successfully joined the Exchange league.    |

  @already_member
  Scenario Outline: JoinPublicExchangeLeague handles already joined league gracefully
    # PREREQUISITE CHECK: Ensure access token and league ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremePublicExchangeLeagueId == null) karate.abort()
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(joinPublicExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    # Second join attempt (should handle already member case)
    Given request payload
    When method post
    Then status 200
    * print 'JoinPublicExchangeLeague Already Member Response:', response
    * match response.data.joinPublicExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                         | expectedStatus | expectedMessage                                                            | expectedErrorCode                |
      | existingPublicExchangeLeagueId   | 409            | You have already joined this league. Please create a team to participate.  | LEAGUE_JOINED_TEAM_NOT_CREATED   |

  @league_not_found
  Scenario Outline: JoinPublicExchangeLeague fails with non-existent league ID
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(joinPublicExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPublicExchangeLeague League Not Found Response:', response
    * match response.data.joinPublicExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId | expectedStatus | expectedMessage    | expectedErrorCode   |
      | 999999   | 404            | League not found   | LEAGUE_NOT_FOUND    |
      | 100000   | 404            | League not found   | LEAGUE_NOT_FOUND    |

  @invalid_league_id
  Scenario Outline: JoinPublicExchangeLeague fails with invalid league ID format
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(joinPublicExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPublicExchangeLeague Invalid League ID Response:', response
    * match response.data.joinPublicExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId      | expectedStatus | expectedMessage                  | expectedErrorCode   |
      | invalid       | 400            | League_ID must be a numeric ID.  | INVALID_LEAGUE_ID   |
      | abc123        | 400            | League_ID must be a numeric ID.  | INVALID_LEAGUE_ID   |
      | league_id     | 400            | League_ID must be a numeric ID.  | INVALID_LEAGUE_ID   |
      | -999999       | 400            | Invalid League_ID format!        | INVALID_LEAGUE_ID   |
      | -100000       | 400            | Invalid League_ID format!        | INVALID_LEAGUE_ID   |