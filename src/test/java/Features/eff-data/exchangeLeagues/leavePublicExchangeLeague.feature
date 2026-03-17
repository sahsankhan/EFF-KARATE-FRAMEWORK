Feature: EFF Data - Leave Exchange League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def leaveExchangeLeagueQuery = read('classpath:graphql/eff-data/exchangeLeagues/leaveExchangeLeague.graphql')
    * def getExchangeLeagueQuery = read('classpath:graphql/eff-data/exchangeLeagues/getExchangeLeague.graphql')
    * def getHomePagePublicExtremeLeaguesQuery = read('classpath:graphql/eff-data/leagues/getHomePagePublicExtremeLeagues.graphql')
    * def getAvailablePublicExtremeLeaguesQuery = read('classpath:graphql/eff-data/leagues/getAvailableLeagues.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def secondUserAccessToken = karate.get('signUpInfo.secondUser.accessToken', null)
    * karate.log(secondUserAccessToken)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def extremePublicExchangeLeagueId = karate.get('signUpInfo.extremePublicExchangeLeagueId', null)
    * def leftExchangeLeagueId = karate.get('signUpInfo.extremePublicExchangeLeagueId', null)
    * def currentExchangeMemberCount = karate.get('signUpInfo.currentExchangeMemberCount', null)
    * def buildLeagueData =
      """
      function(leagueId, existingAccessToken) {
        var idValue = leagueId;
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPublicExchangeLeagueId') idValue = extremePublicExchangeLeagueId;
        if (idValue === 'leftExchangeLeagueId') idValue = leftExchangeLeagueId
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        return { authToken: existingAccessToken, variables: { League_ID: idValue } };
      }
      """

  @missing_authorization_header
  Scenario Outline: LeaveExchangeLeague fails when Authorization header is missing
    # PREREQUISITE CHECK: Ensure league ID exist
    * if (extremePublicExchangeLeagueId == null) karate.abort()

    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(leaveExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeaveExchangeLeague Missing Token Response:', response
    * match response.data.leaveExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                         | expectedStatus | expectedMessage         | expectedErrorCode   |
      | existingPublicExchangeLeagueId   | 400            | Missing token in header | MISSING_TOKEN       |

  @expired_token
  Scenario Outline: LeaveExchangeLeague fails with expired token
    # PREREQUISITE CHECK: Ensure league ID exist
    * if (extremePublicExchangeLeagueId == null) karate.abort()

    * def expiredToken = '<expiredToken>'
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = expiredToken
    * def payload = { query: '#(leaveExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeaveExchangeLeague Expired Token Response:', response
    * match response.data.leaveExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                        | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage | expectedErrorCode   |
      | existingPublicExchangeLeagueId  | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   | EXPIRED_TOKEN       |

  @invalid_token
  Scenario Outline: LeaveExchangeLeague fails with invalid or corrupted token
    # PREREQUISITE CHECK: Ensure league ID exist
    * if (extremePublicExchangeLeagueId == null) karate.abort()

    * def invalidToken = '<invalidToken>'
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = invalidToken
    * def payload = { query: '#(leaveExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeaveExchangeLeague Invalid Token Response:', response
    * match response.data.leaveExchangeLeague == null
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
  Scenario Outline: LeaveExchangeLeague complete flow - leave, verify permissions removed, and member count decreased
    # PREREQUISITE CHECK: Ensure access token and league ID exist and season is preseason
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremePublicExchangeLeagueId == null) karate.abort()
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')
    
    # Log member count before leaving for tracking
    * if (currentExchangeMemberCount != null) karate.log('Member count before leaving:', currentExchangeMemberCount)
    * if (currentExchangeMemberCount != null) karate.log('Expected member count after leaving:', currentExchangeMemberCount - 1)
    
    # Step 1: Leave the league
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(leaveExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeaveExchangeLeague Success Response:', response
    * match response.data.leaveExchangeLeague.statusCode == <expectedStatus>
    * match response.data.leaveExchangeLeague.message == '<expectedMessage>'

    # Step 2: Verify available leagues show both public blitz and exchange leagues
    * def getLeaguesPayload = { query: '#(getAvailablePublicExtremeLeaguesQuery)' }
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * header Authorization = build.authToken

    Given request getLeaguesPayload
    When method post
    Then status 200
    * print 'GetAvailablePublicExtremeLeagues After Leave Response:', response
    
    # Validate response structure
    * match response.data.getAvailableLeagues.statusCode == <expectedStatus>
    * match response.data.getAvailableLeagues.blitz_league == '#present'
    * match response.data.getAvailableLeagues.exchange_league == '#present'

    # Step 3: Verify member count is decremented by fetching public leagues again
    * def getLeaguesPayload = { query: '#(getHomePagePublicExtremeLeaguesQuery)' }
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * header Authorization = build.authToken

    Given request getLeaguesPayload
    When method post
    Then status 200
    * print 'GetHomePagePublicExtremeLeagues After Leave Response:', response
    
    # Validate response structure
    * match response.data.getHomePagePublicExtremeLeagues.statusCode == 200
    * match response.data.getHomePagePublicExtremeLeagues.exchange_league == '#present'
    
    # Find the league user just left and verify member count decreased
    * def exchangeLeague = response.data.getHomePagePublicExtremeLeagues.exchange_league
    * match exchangeLeague._id == extremePublicExchangeLeagueId
    * match exchangeLeague.Members == '#number'
    
    * def memberCountAfterLeave = exchangeLeague.Members
    * print 'Member count after leaving:', memberCountAfterLeave
    
    # Verify member count decreased (flexible validation for parallel execution)
    * if (currentExchangeMemberCount != null) karate.log('Before leave:', currentExchangeMemberCount)
    * if (currentExchangeMemberCount != null) karate.log('After leave:', memberCountAfterLeave)
    * if (currentExchangeMemberCount != null && memberCountAfterLeave >= currentExchangeMemberCount) karate.fail('Member count should have decreased after leaving. Before=' + currentExchangeMemberCount + ', After=' + memberCountAfterLeave)
    * if (currentExchangeMemberCount != null) karate.log('Member count validation passed - decreased from ' + currentExchangeMemberCount + ' to ' + memberCountAfterLeave + ' (parallel execution safe)')
    
    * def leftExchangeLeagueId = extremePublicExchangeLeagueId

    # Clear extremePublicExchangeLeagueId so subsequent features know the user is no longer a public league member
    * karate.write({email: signUpInfo.email, resetKey: signUpInfo.resetKey, password: signUpInfo.password, isVerified: signUpInfo.isVerified, passwordSet: signUpInfo.passwordSet, refreshToken: signUpInfo.refreshToken, accessToken: signUpInfo.accessToken, extremePublicBlitzLeagueId: signUpInfo.extremePublicBlitzLeagueId, extremePublicExchangeLeagueId: null, privateBlitzLeagueId: signUpInfo.privateBlitzLeagueId, privateBlitzTeamId: signUpInfo.privateBlitzTeamId, privateBlitzTeamName: signUpInfo.privateBlitzTeamName, secondUser: signUpInfo.secondUser, leftExchangeLeagueId: leftExchangeLeagueId}, 'target/info.txt')
    * karate.log('Cleared extremePublicExchangeLeagueId after leaving public league')

    Examples:
      | leagueId                         | expectedStatus | expectedMessage                                    |
      | existingPublicExchangeLeagueId   | 200            | You have successfully left the Exchange league.    |

  @not_league_member
  Scenario Outline: LeaveExchangeLeague fails when user is not a member
    # PREREQUISITE CHECK: Ensure access token and league ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (leftExchangeLeagueId == null) karate.abort()

    # Attempt to leave the league again (should fail as user already left)
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(leaveExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeaveExchangeLeague Not Member Response:', response
    * match response.data.leaveExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId               | expectedStatus | expectedMessage                         | expectedErrorCode           |
      | leftExchangeLeagueId   | 404            | You are not a member of this league.    | LEAGUE_MEMBERSHIP_NOT_FOUND |

  @league_not_found
  Scenario Outline: LeaveExchangeLeague fails with non-existent league ID
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(leaveExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeaveExchangeLeague League Not Found Response:', response
    * match response.data.leaveExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId | expectedStatus | expectedMessage   | expectedErrorCode   |
      | 999999   | 404            | League not found  | LEAGUE_NOT_FOUND    |
      | 100000   | 404            | League not found  | LEAGUE_NOT_FOUND    |

  @invalid_league_id
  Scenario Outline: LeaveExchangeLeague fails with invalid league ID format
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(leaveExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeaveExchangeLeague Invalid League ID Response:', response
    * match response.data.leaveExchangeLeague == null
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