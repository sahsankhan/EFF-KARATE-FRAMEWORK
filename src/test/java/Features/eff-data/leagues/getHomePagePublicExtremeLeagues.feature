Feature: EFF Data - Get Home Page Public Extreme Leagues API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def getHomePagePublicExtremeLeaguesQuery = read('classpath:graphql/eff-data/leagues/getHomePagePublicExtremeLeagues.graphql')
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
   
    * match response.data.getHomePagePublicExtremeLeagues.statusCode == 200
    * match response.data.getHomePagePublicExtremeLeagues.blitz_league == '#object'
    * match response.data.getHomePagePublicExtremeLeagues.exchange_league == '#object'
    
    # Extract leagues
    * def blitzLeague = response.data.getHomePagePublicExtremeLeagues.blitz_league
    * def exchangeLeague = response.data.getHomePagePublicExtremeLeagues.exchange_league

    # Validate Blitz League Schema 
    * match blitzLeague._id == '#present'
    * match blitzLeague.Public == true
    * match blitzLeague.Game_Type == 'EXTREME'
    * match blitzLeague.League_Type == 'BLITZ'

    # Validate Exchange League Schema 
    * match exchangeLeague._id == '#present'
    * match exchangeLeague.Public == true
    * match exchangeLeague.Game_Type == 'EXTREME'
    * match exchangeLeague.League_Type == 'EXCHANGE'
    
    # Save IDs for next tests
    * def extremeBlitzLeagueId = blitzLeague._id
    * def extremeExchangeLeagueId = exchangeLeague._id
    * def initialBlitzMemberCount = blitzLeague.Members
    * def initialExchangeMemberCount = exchangeLeague.Members

    * karate.log('Saved EXTREME Blitz League ID:', extremeBlitzLeagueId)
    * karate.log('Saved EXTREME Exchange League ID:', extremeExchangeLeagueId)
    * karate.log('Initial Blitz Member Count:', initialBlitzMemberCount)
    * karate.log('Initial Exchange Member Count:', initialExchangeMemberCount)

    # Persist to info file
    * def updatedInfo = signUpInfo
    * updatedInfo.extremeBlitzLeagueId = extremeBlitzLeagueId
    * updatedInfo.initialBlitzMemberCount = initialBlitzMemberCount
    * updatedInfo.extremeExchangeLeagueId = extremeExchangeLeagueId
    * updatedInfo.initialExchangeMemberCount = initialExchangeMemberCount

    * karate.write(updatedInfo, 'target/info.txt')
    * karate.log('Saved league IDs and member count to info file:', updatedInfo)

  @verify_limit_on_leagues
  Scenario: GetHomePagePublicExtremeLeagues returns valid 200 Limit for both public leagues 
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * header Authorization = existingAccessToken
    * def payload = { query: '#(getHomePagePublicExtremeLeaguesQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetHomePagePublicExtremeLeagues Schema Validation Response:', response
   
    * match response.data.getHomePagePublicExtremeLeagues.statusCode == 200
    * def blitzLeague = response.data.getHomePagePublicExtremeLeagues.blitz_league
    * def exchangeLeague = response.data.getHomePagePublicExtremeLeagues.exchange_league

    # Validate Blitz League Limit 
    * match blitzLeague._id == '#present'
    * match blitzLeague.Limit == 200

    # Validate Exchange League Limit 
    * match exchangeLeague._id == '#present'
    * match exchangeLeague.Limit == 200
    
