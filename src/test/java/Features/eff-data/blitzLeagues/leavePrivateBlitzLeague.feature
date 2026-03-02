Feature: EFF Data - Leave Private Blitz League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def leaveBlitzLeagueQuery = read('classpath:graphql/eff-data/blitzLeagues/leaveBlitzLeague.graphql')
    * def getBlitzLeagueQuery = read('classpath:graphql/eff-data/blitzLeagues/getBlitzLeague.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def secondUserAccessToken = karate.get('signUpInfo.secondUser.accessToken', null)
    * def privateBlitzLeagueId = karate.get('signUpInfo.privateBlitzLeagueId', null)
    * def buildLeagueData =
      """
      function(leagueId, accessToken) {
        var idValue = leagueId;
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPrivateBlitzLeagueId') idValue = privateBlitzLeagueId;
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        return { authToken: accessToken, variables: { League_ID: idValue } };
      }
      """

  @missing_authorization_header
  Scenario Outline: LeavePrivateBlitzLeague fails when Authorization header is missing
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (privateBlitzLeagueId == null) karate.abort()

    * def build = buildLeagueData('<leagueId>', secondUserAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(leaveBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeavePrivateBlitzLeague Missing Token Response:', response
    * match response.data.leaveBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                      | expectedStatus | expectedMessage         | expectedErrorCode   |
      | existingPrivateBlitzLeagueId  | 400            | Missing token in header | MISSING_TOKEN       |

  @expired_token
  Scenario Outline: LeavePrivateBlitzLeague fails with expired token
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (privateBlitzLeagueId == null) karate.abort()

    * def expiredToken = '<expiredToken>'
    * def build = buildLeagueData('<leagueId>', secondUserAccessToken)
    * header Authorization = expiredToken
    * def payload = { query: '#(leaveBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeavePrivateBlitzLeague Expired Token Response:', response
    * match response.data.leaveBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                     | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage | expectedErrorCode   |
      | existingPrivateBlitzLeagueId | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   | EXPIRED_TOKEN       |

  @invalid_token
  Scenario Outline: LeavePrivateBlitzLeague fails with invalid or corrupted token
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (privateBlitzLeagueId == null) karate.abort()

    * def invalidToken = '<invalidToken>'
    * def build = buildLeagueData('<leagueId>', secondUserAccessToken)
    * header Authorization = invalidToken
    * def payload = { query: '#(leaveBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeavePrivateBlitzLeague Invalid Token Response:', response
    * match response.data.leaveBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                      | invalidToken                      | expectedStatus | expectedMessage | expectedErrorCode   |
      | existingPrivateBlitzLeagueId  | Bearer invalidtoken123            | 401            | Invalid token   | INVALID_TOKEN       |
      | existingPrivateBlitzLeagueId  | random_corrupted_string_12345     | 401            | Invalid token   | INVALID_TOKEN       |
      | existingPrivateBlitzLeagueId  | invalid.token.string              | 401            | Invalid token   | INVALID_TOKEN       |

  @happy_path
  Scenario Outline: LeavePrivateBlitzLeague succeeds with valid league ID and verifies member is removed
    # PREREQUISITE CHECK: Ensure second user access token and league ID exist and season is preseason
    * if (secondUserAccessToken == null) karate.fail('No second user access token found. Run createSecondUser.feature first')
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')
    * if (privateBlitzLeagueId == null) karate.abort()
    
    # Step 1: Second user leaves the private league
    * def build = buildLeagueData('<leagueId>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(leaveBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeavePrivateBlitzLeague Success Response:', response
    * match response.data.leaveBlitzLeague.statusCode == <expectedStatus>
    * match response.data.leaveBlitzLeague.message == '<expectedMessage>'
    
    # Step 2: Verify second user is no longer a member by calling getBlitzLeague
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

    Examples:
      | leagueId                      | expectedStatus | expectedMessage                                 |
      | existingPrivateBlitzLeagueId  | 200            | You have successfully left the Blitz league.    |

  @not_league_member
  Scenario Outline: LeavePrivateBlitzLeague fails when user is not a member
    # PREREQUISITE CHECK: Ensure second user access token and league ID exist
    * if (secondUserAccessToken == null) karate.fail('No second user access token found. Run createSecondUser.feature first')
    * if (privateBlitzLeagueId == null) karate.abort()

    # Attempt to leave the league again (should fail as second user already left)
    * def build = buildLeagueData('<leagueId>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(leaveBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeavePrivateBlitzLeague Not Member Response:', response
    * match response.data.leaveBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                      | expectedStatus | expectedMessage                         | expectedErrorCode           |
      | existingPrivateBlitzLeagueId  | 404            | You are not a member of this league.    | LEAGUE_MEMBERSHIP_NOT_FOUND |

