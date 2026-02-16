Feature: EFF Data - Get Home Page Public Extreme Leagues API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def getHomePagePublicExtremeLeaguesQuery = read('classpath:graphql/eff-data/blitzLeagues/getHomePagePublicExtremeLeagues.graphql')
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
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'


    Examples:
      | expectedStatus | expectedMessage         | expectedErrorCode   |
      | 400            | Missing token in header | MISSING_TOKEN       |

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
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'


    Examples:
      | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage | expectedErrorCode   |
      | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   | EXPIRED_TOKEN       |

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
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'


    Examples:
      | invalidToken                         | expectedStatus | expectedMessage | expectedErrorCode   |
      | invalid.token.string                 | 401            | Invalid token   | INVALID_TOKEN       |
      | random_corrupted_string_12345        | 401            | Invalid token   | INVALID_TOKEN       |
      | Bearer invalidtoken123               | 401            | Invalid token   | INVALID_TOKEN       |

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
    * def isBlitzLeaguesAvailable = isActiveSeason && blitzLeagues != null
    * eval if (isBlitzLeaguesAvailable) karate.log('Blitz leagues are available')
    * eval if (isBlitzLeaguesAvailable) karate.match(blitzLeagues._id, '#present')
    * eval if (isBlitzLeaguesAvailable) karate.match(blitzLeagues.League_Name, '#string')
    * eval if (isBlitzLeaguesAvailable) karate.match(blitzLeagues.owner, '#present')

    # Assert blitz league have Public flag set to true
    * eval if (isBlitzLeaguesAvailable) karate.match(blitzLeagues.public, true)
    
    # Validate league type for blitz league (should be EXTREME)
    * eval if (isBlitzLeaguesAvailable) karate.match(blitzLeagues.Game_Type, 'EXTREME') 
    * eval if (isBlitzLeaguesAvailable) karate.match(blitzLeagues.League_Type, 'BLITZ')  
    
    # Validate Exchange Leagues Schema (only during active season)
    * def exchangeLeagues = isActiveSeason ? response.data.getHomePagePublicExtremeLeagues.exchange_league : []
    * def isExchangeLeaguesAvailable = isActiveSeason && exchangeLeagues
    * eval if (isExchangeLeaguesAvailable) karate.match(exchangeLeagues._id, '#present')
    * eval if (isExchangeLeaguesAvailable) karate.match(exchangeLeagues.League_Name, '#string')
    * eval if (isExchangeLeaguesAvailable) karate.match(exchangeLeagues.owner, '#present')

    # Assert exchange league have Public flag set to true
    * eval if (isExchangeLeaguesAvailable) karate.match(exchangeLeagues.public, true)
    
    # Validate league type for exchange league (should be EXTREME)
    * eval if (isExchangeLeaguesAvailable) karate.match(exchangeLeagues.Game_Type, 'EXTREME') 
    * eval if (isExchangeLeaguesAvailable) karate.match(exchangeLeagues.League_Type, 'EXCHANGE')  
    
    # Save EXTREME Blitz League ID and initial member count for subsequent tests 
    * def extremeBlitzLeague = isBlitzLeaguesAvailable ? blitzLeagues : null
    * def extremeBlitzLeagueId = extremeBlitzLeague != null ? extremeBlitzLeague._id : null
    * def initialBlitzMemberCount = extremeBlitzLeague != null && extremeBlitzLeague.Members != null ? extremeBlitzLeague.Members : null
    * if (extremeBlitzLeagueId != null) karate.log('Saved EXTREME Blitz League ID:', extremeBlitzLeagueId)
    * if (initialBlitzMemberCount != null) karate.log('Initial Blitz League Member Count:', initialBlitzMemberCount)
    * if (isActiveSeason && extremeBlitzLeagueId == null) karate.log('No EXTREME blitz league found in public leagues')
    
    # Save EXTREME Exchange League ID for subsequent tests 
    * def extremeExchangeLeague = isExchangeLeaguesAvailable ? exchangeLeagues : null
    * def extremeExchangeLeagueId = extremeExchangeLeague != null ? extremeExchangeLeague._id : null
    * if (extremeExchangeLeagueId != null) karate.log(' Found EXTREME Exchange League ID:', extremeExchangeLeagueId)
    * if (isActiveSeason && extremeExchangeLeagueId == null) karate.log('No EXTREME exchange league found in public leagues')
    
    # Save league IDs and initial member count together
    * def updatedInfo = signUpInfo
    * if (extremeBlitzLeagueId != null) updatedInfo.extremeBlitzLeagueId = extremeBlitzLeagueId
    * if (initialBlitzMemberCount != null) updatedInfo.initialBlitzMemberCount = initialBlitzMemberCount
    * if (extremeExchangeLeagueId != null) updatedInfo.extremeExchangeLeagueId = extremeExchangeLeagueId
    * if (extremeBlitzLeagueId != null || extremeExchangeLeagueId != null) karate.write(updatedInfo, 'target/info.txt')
    * if (extremeBlitzLeagueId != null || extremeExchangeLeagueId != null) karate.log('Saved league IDs and member count to info file:', updatedInfo)
