Feature: EFF Data - Get Public Blitz Leagues API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def getPublicBlitzLeaguesQuery = read('classpath:resources/graphql/eff-data/blitzLeagues/getPublicBlitzLeagues.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)

  @missing_authorization_header
  Scenario Outline: GetPublicBlitzLeagues fails when Authorization header is missing
    # Do not set Authorization header
    * def payload = { query: '#(getPublicBlitzLeaguesQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetPublicBlitzLeagues Missing Token Response:', response
    * match response.data.getPublicBlitzLeagues == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | expectedStatus | expectedMessage         |
      | 400            | Missing token in header |

  @expired_token
  Scenario Outline: GetPublicBlitzLeagues fails with expired token
    * def expiredToken = '<expiredToken>'
    * header Authorization = expiredToken
    * def payload = { query: '#(getPublicBlitzLeaguesQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetPublicBlitzLeagues Expired Token Response:', response
    * match response.data.getPublicBlitzLeagues == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | expiredToken                                                                                                                                                            | expectedStatus | expectedMessage |
      | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   |

  @invalid_token
  Scenario Outline: GetPublicBlitzLeagues fails with invalid or corrupted token
    * def invalidToken = '<invalidToken>'
    * header Authorization = invalidToken
    * def payload = { query: '#(getPublicBlitzLeaguesQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetPublicBlitzLeagues Invalid Token Response:', response
    * match response.data.getPublicBlitzLeagues == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | invalidToken                         | expectedStatus | expectedMessage |
      | invalid.token.string                 | 401            | Invalid token   |
      | random_corrupted_string_12345        | 401            | Invalid token   |
      | Bearer invalidtoken123               | 401            | Invalid token   |

  @happy_path_with_leagues
  Scenario: GetPublicBlitzLeagues returns proper schema for each league
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * header Authorization = existingAccessToken
    * def payload = { query: '#(getPublicBlitzLeaguesQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetPublicBlitzLeagues Schema Validation Response:', response
    * match response.data.getPublicBlitzLeagues.statusCode == 200
    * match response.data.getPublicBlitzLeagues.leagues == '#array'
    
    # If leagues exist, validate schema
    * def publicLeagues = response.data.getPublicBlitzLeagues.leagues
    * def isLeaguesAvailable = publicLeagues.length > 0
    * eval if (isLeaguesAvailable) karate.match(publicLeagues[0]._id, '#present')
    * eval if (isLeaguesAvailable) karate.match(publicLeagues[0].League_Name, '#string')
    * eval if (isLeaguesAvailable) karate.match(publicLeagues[0].owner, '#present')

    # Assert all leagues have Public flag set to true
    * eval if (isLeaguesAvailable) karate.forEach(publicLeagues, function(league){ karate.match(league.Public, true) })
    
    # Validate league types (EXTREME or WEEKLY) for all leagues
    * eval if (isLeaguesAvailable) karate.forEach(publicLeagues, function(league){ karate.match(league.Game_Type, '#regex (EXTREME|WEEKLY)') })
    * eval if (isLeaguesAvailable) karate.forEach(publicLeagues, function(league){ karate.match(league.League_Type, 'BLITZ') })
    
    # Save EXTREME league ID for subsequent tests
    * def extremeLeague = publicLeagues.find(function(league){ return league.Game_Type == 'EXTREME' })
    * def extremeBlitzLeagueId = extremeLeague != null ? extremeLeague._id : null
    * if (extremeBlitzLeagueId != null) karate.write({email: signUpInfo.email, resetKey: signUpInfo.resetKey, password: signUpInfo.password, isVerified: signUpInfo.isVerified, passwordSet: signUpInfo.passwordSet, refreshToken: signUpInfo.refreshToken, accessToken: signUpInfo.accessToken, extremeBlitzLeagueId: extremeBlitzLeagueId}, 'target/info.txt')
    * if (extremeBlitzLeagueId != null) karate.log('Saved EXTREME League ID:', extremeBlitzLeagueId)
    * if (extremeBlitzLeagueId == null) karate.log('No EXTREME league found in public leagues')