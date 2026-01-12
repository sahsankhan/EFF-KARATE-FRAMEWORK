Feature: EFF Data - Get Home Page Public Extreme Leagues API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def getHomePagePublicExtremeLeaguesQuery = read('classpath:resources/graphql/eff-data/blitzLeagues/getHomePagePublicExtremeLeagues.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)

  @missing_authorization_header
  Scenario Outline: GetHomePagePublicExtremeLeagues fails when Authorization header is missing
    # Do not set Authorization header
    * def payload = { query: '#(getHomePagePublicExtremeLeaguesQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetHomePagePublicExtremeLeagues Missing Token Response:', response
    * match response.data.getHomePagePublicExtremeLeagues == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | expectedStatus | expectedMessage         |
      | 400            | Missing token in header |

  @expired_token
  Scenario Outline: GetHomePagePublicExtremeLeagues fails with expired token
    * def expiredToken = '<expiredToken>'
    * header Authorization = expiredToken
    * def payload = { query: '#(getHomePagePublicExtremeLeaguesQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetHomePagePublicExtremeLeagues Expired Token Response:', response
    * match response.data.getHomePagePublicExtremeLeagues == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | expiredToken                                                                                                                                                            | expectedStatus | expectedMessage |
      | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   |

  @invalid_token
  Scenario Outline: GetHomePagePublicExtremeLeagues fails with invalid or corrupted token
    * def invalidToken = '<invalidToken>'
    * header Authorization = invalidToken
    * def payload = { query: '#(getHomePagePublicExtremeLeaguesQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetHomePagePublicExtremeLeagues Invalid Token Response:', response
    * match response.data.getHomePagePublicExtremeLeagues == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | invalidToken                         | expectedStatus | expectedMessage |
      | invalid.token.string                 | 401            | Invalid token   |
      | random_corrupted_string_12345        | 401            | Invalid token   |
      | Bearer invalidtoken123               | 401            | Invalid token   |

  @happy_path_with_leagues
  Scenario: GetHomePagePublicExtremeLeagues returns proper schema for blitz and exchange leagues 
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * header Authorization = existingAccessToken
    * def payload = { query: '#(getHomePagePublicExtremeLeaguesQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetHomePagePublicExtremeLeagues Schema Validation Response:', response
    
    # Check if it's off-season or active season (MUST check this FIRST before accessing data)
    # Only treat as off-season if it's specifically a 403 error, not any other error
    * def hasError = response.data.getHomePagePublicExtremeLeagues == null && response.errors != null
    * def isOffSeason = hasError && response.errors[0].errorInfo.statusCode == 403 && response.errors[0].message.contains('offseason')
    
    # If there's an error but NOT off-season, fail the test (could be a bug)
    * def isUnexpectedError = hasError && !isOffSeason
    * if (isUnexpectedError) karate.fail('Unexpected error occurred: ' + response.errors[0].message + ' (Status: ' + response.errors[0].errorInfo.statusCode + ')')
    
    # Handle OFF-SEASON scenario
    * eval if (isOffSeason) karate.match(response.errors[0].errorInfo.statusCode, 403)
    * eval if (isOffSeason) karate.match(response.errors[0].message, 'The season has finished and is now on the NFL offseason.')
    * eval if (isOffSeason) karate.log('Off-season detected: No public leagues available during NFL offseason')
    
    # Handle ACTIVE SEASON scenario - Only validate if NOT off-season
    * def isActiveSeason = !isOffSeason
    * eval if (isActiveSeason) karate.match(response.data.getHomePagePublicExtremeLeagues.statusCode, 200)
    * eval if (isActiveSeason) karate.match(response.data.getHomePagePublicExtremeLeagues.blitz_league, '#array')
    * eval if (isActiveSeason) karate.match(response.data.getHomePagePublicExtremeLeagues.exchange_league, '#array')
    
    # Validate Blitz Leagues Schema (only during active season)
    * def blitzLeagues = isActiveSeason ? response.data.getHomePagePublicExtremeLeagues.blitz_league : []
    * def isBlitzLeaguesAvailable = isActiveSeason && blitzLeagues.length > 0
    * eval if (isBlitzLeaguesAvailable) karate.match(blitzLeagues[0]._id, '#present')
    * eval if (isBlitzLeaguesAvailable) karate.match(blitzLeagues[0].League_Name, '#string')
    * eval if (isBlitzLeaguesAvailable) karate.match(blitzLeagues[0].owner, '#present')

    # Assert blitz league have Public flag set to true
    * eval if (isBlitzLeaguesAvailable) karate.match(blitzLeagues[0].public, true)
    
    # Validate league type for blitz league (should be EXTREME)
    * eval if (isBlitzLeaguesAvailable) karate.match(blitzLeagues[0].Game_Type, 'EXTREME') 
    * eval if (isBlitzLeaguesAvailable) karate.match(blitzLeagues[0].League_Type, 'BLITZ')  
    
    # Validate Exchange Leagues Schema (only during active season)
    * def exchangeLeagues = isActiveSeason ? response.data.getHomePagePublicExtremeLeagues.exchange_league : []
    * def isExchangeLeaguesAvailable = isActiveSeason && exchangeLeagues.length > 0
    * eval if (isExchangeLeaguesAvailable) karate.match(exchangeLeagues[0]._id, '#present')
    * eval if (isExchangeLeaguesAvailable) karate.match(exchangeLeagues[0].League_Name, '#string')
    * eval if (isExchangeLeaguesAvailable) karate.match(exchangeLeagues[0].owner, '#present')

    # Assert exchange league have Public flag set to true
    * eval if (isExchangeLeaguesAvailable) karate.match(exchangeLeagues[0].public, true)
    
    # Validate league type for exchange league (should be EXTREME)
    * eval if (isExchangeLeaguesAvailable) karate.match(exchangeLeagues[0].Game_Type, 'EXTREME') 
    * eval if (isExchangeLeaguesAvailable) karate.match(exchangeLeagues[0].League_Type, 'EXCHANGE')  
    
    # Save EXTREME Blitz League ID for subsequent tests 
    * def extremeBlitzLeague = isBlitzLeaguesAvailable ? blitzLeagues[0] : null
    * def extremeBlitzLeagueId = extremeBlitzLeague != null ? extremeBlitzLeague._id : null
    * if (extremeBlitzLeagueId != null) karate.write({email: signUpInfo.email, resetKey: signUpInfo.resetKey, password: signUpInfo.password, isVerified: signUpInfo.isVerified, passwordSet: signUpInfo.passwordSet, refreshToken: signUpInfo.refreshToken, accessToken: signUpInfo.accessToken, extremeBlitzLeagueId: extremeBlitzLeagueId}, 'target/info.txt')
    * if (extremeBlitzLeagueId != null) karate.log('Saved EXTREME Blitz League ID:', extremeBlitzLeagueId)
    * if (isActiveSeason && extremeBlitzLeagueId == null) karate.log('No EXTREME blitz league found in public leagues')
    
    # Save EXTREME Exchange League ID for subsequent tests 
    * def extremeExchangeLeague = isExchangeLeaguesAvailable ? exchangeLeagues[0] : null
    * def extremeExchangeLeagueId = extremeExchangeLeague != null ? extremeExchangeLeague._id : null
    * if (extremeExchangeLeagueId != null) karate.write({email: signUpInfo.email, resetKey: signUpInfo.resetKey, password: signUpInfo.password, isVerified: signUpInfo.isVerified, passwordSet: signUpInfo.passwordSet, refreshToken: signUpInfo.refreshToken, accessToken: signUpInfo.accessToken, extremeExchangeLeagueId: extremeExchangeLeagueId}, 'target/info.txt')
    * if (extremeExchangeLeagueId != null) karate.log(' Found EXTREME Exchange League ID:', extremeExchangeLeagueId)
    * if (isActiveSeason && extremeExchangeLeagueId == null) karate.log('No EXTREME exchange league found in public leagues')
