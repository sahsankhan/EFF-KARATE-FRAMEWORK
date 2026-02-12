Feature: EFF Data - Leave Blitz League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def leaveBlitzLeagueQuery = read('classpath:graphql/eff-data/blitzLeagues/leaveBlitzLeague.graphql')
    * def getBlitzLeagueQuery = read('classpath:graphql/eff-data/blitzLeagues/getBlitzLeague.graphql')
    * def getHomePagePublicExtremeLeaguesQuery = read('classpath:graphql/eff-data/blitzLeagues/getHomePagePublicExtremeLeagues.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def extremeBlitzLeagueId = karate.get('signUpInfo.extremeBlitzLeagueId', null)
    * def currentBlitzMemberCount = karate.get('signUpInfo.currentBlitzMemberCount', null)
    * def buildLeagueData =
      """
      function(leagueId, existingAccessToken) {
        var idValue = leagueId;
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPublicBlitzLeagueId') idValue = extremeBlitzLeagueId;
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        return { authToken: existingAccessToken, variables: { League_ID: idValue } };
      }
      """

  @missing_authorization_header
  Scenario Outline: LeaveBlitzLeague fails when Authorization header is missing
    # PREREQUISITE CHECK: Ensure league ID exist
    * if (extremeBlitzLeagueId == null) karate.abort()

    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(leaveBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeaveBlitzLeague Missing Token Response:', response
    * match response.data.leaveBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                      | expectedStatus | expectedMessage         | expectedErrorCode   |
      | existingPublicBlitzLeagueId   | 400            | Missing token in header | MISSING_TOKEN       |

  @expired_token
  Scenario Outline: LeaveBlitzLeague fails with expired token
    # PREREQUISITE CHECK: Ensure league ID exist
    * if (extremeBlitzLeagueId == null) karate.abort()

    * def expiredToken = '<expiredToken>'
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = expiredToken
    * def payload = { query: '#(leaveBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeaveBlitzLeague Expired Token Response:', response
    * match response.data.leaveBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                     | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage | expectedErrorCode   |
      | existingPublicBlitzLeagueId  | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   | EXPIRED_TOKEN       |

  @invalid_token
  Scenario Outline: LeaveBlitzLeague fails with invalid or corrupted token
    # PREREQUISITE CHECK: Ensure league ID exist
    * if (extremeBlitzLeagueId == null) karate.abort()

    * def invalidToken = '<invalidToken>'
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = invalidToken
    * def payload = { query: '#(leaveBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeaveBlitzLeague Invalid Token Response:', response
    * match response.data.leaveBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                      | invalidToken                      | expectedStatus | expectedMessage | expectedErrorCode   |
      | existingPublicBlitzLeagueId   | Bearer invalidtoken123            | 401            | Invalid token   | INVALID_TOKEN       |
      | existingPublicBlitzLeagueId   | random_corrupted_string_12345     | 401            | Invalid token   | INVALID_TOKEN       |
      | existingPublicBlitzLeagueId   | invalid.token.string              | 401            | Invalid token   | INVALID_TOKEN       |

  @happy_path
  Scenario Outline: LeaveBlitzLeague complete flow - leave, verify permissions removed, and member count decreased
    # PREREQUISITE CHECK: Ensure access token and league ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremeBlitzLeagueId == null) karate.abort()
    
    # Log member count before leaving for tracking
    * if (currentBlitzMemberCount != null) karate.log('Member count before leaving:', currentBlitzMemberCount)
    * if (currentBlitzMemberCount != null) karate.log('Expected member count after leaving:', currentBlitzMemberCount - 1)
    
    # Step 1: Leave the league
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(leaveBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeaveBlitzLeague Success Response:', response
    * match response.data.leaveBlitzLeague.statusCode == <expectedStatus>
    * match response.data.leaveBlitzLeague.message == '<expectedMessage>'
    
    # Step 2: Verify user is no longer a member by calling getBlitzLeague
    * def getLeaguePayload = { query: '#(getBlitzLeagueQuery)', variables: '#(build.variables)' }
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * header Authorization = build.authToken
    
    Given request getLeaguePayload
    When method post
    Then status 200
    * print 'GetBlitzLeague After Leave Response:', response
    * match response.data.getBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == 403
    * match response.errors[0].message contains 'You do not have permission to view this league'

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
    * match response.data.getHomePagePublicExtremeLeagues.blitz_league == '#present'
    
    # Find the league user just left and verify member count decreased
    * def blitzLeague = response.data.getHomePagePublicExtremeLeagues.blitz_league
    * match blitzLeague._id == extremeBlitzLeagueId
    * match blitzLeague.Members == '#number'
    
    * def memberCountAfterLeave = blitzLeague.Members
    * print 'Member count after leaving:', memberCountAfterLeave
    
    # Verify member count decreased by exactly 1
    * if (currentBlitzMemberCount != null) karate.log('Before leave:', currentBlitzMemberCount)
    * if (currentBlitzMemberCount != null) karate.log('After leave:', memberCountAfterLeave)
    * if (currentBlitzMemberCount != null && memberCountAfterLeave != currentBlitzMemberCount - 1) karate.fail('Member count should have decreased by 1 after leaving. Before=' + currentBlitzMemberCount + ', After=' + memberCountAfterLeave)

    Examples:
      | leagueId                      | expectedStatus | expectedMessage                                 |
      | existingPublicBlitzLeagueId   | 200            | You have successfully left the Blitz league.    |

  @not_league_member
  Scenario Outline: LeaveBlitzLeague fails when user is not a member
    # PREREQUISITE CHECK: Ensure access token and league ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremeBlitzLeagueId == null) karate.abort()

    # Attempt to leave the league again (should fail as user already left)
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(leaveBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeaveBlitzLeague Not Member Response:', response
    * match response.data.leaveBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                      | expectedStatus | expectedMessage                         | expectedErrorCode           |
      | existingPublicBlitzLeagueId   | 404            | You are not a member of this league.    | LEAGUE_MEMBERSHIP_NOT_FOUND |

  @league_not_found
  Scenario Outline: LeaveBlitzLeague fails with non-existent league ID
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(leaveBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeaveBlitzLeague League Not Found Response:', response
    * match response.data.leaveBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId | expectedStatus | expectedMessage   | expectedErrorCode   |
      | 999999   | 404            | League not found  | LEAGUE_NOT_FOUND    |
      | 100000   | 404            | League not found  | LEAGUE_NOT_FOUND    |

  @invalid_league_id
  Scenario Outline: LeaveBlitzLeague fails with invalid league ID format
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(leaveBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeaveBlitzLeague Invalid League ID Response:', response
    * match response.data.leaveBlitzLeague == null
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