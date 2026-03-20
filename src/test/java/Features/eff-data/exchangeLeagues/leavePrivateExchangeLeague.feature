Feature: EFF Data - Leave Private Exchange League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def leaveExchangeLeagueQuery = read('classpath:graphql/eff-data/exchangeLeagues/leaveExchangeLeague.graphql')
    * def getExchangeLeagueQuery = read('classpath:graphql/eff-data/exchangeLeagues/getExchangeLeague.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def secondUserAccessToken = karate.get('signUpInfo.secondUser.accessToken', null)
    * def privateExchangeLeagueId = karate.get('signUpInfo.privateExchangeLeagueId', null)
    * def buildLeagueData =
      """
      function(leagueId, accessToken) {
        var idValue = leagueId;
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPrivateExchangeLeagueId') idValue = privateExchangeLeagueId;
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        return { authToken: accessToken, variables: { League_ID: idValue } };
      }
      """

  @missing_authorization_header
  Scenario Outline: LeavePrivateExchangeLeague fails when Authorization header is missing
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (privateExchangeLeagueId == null) karate.abort()

    * def build = buildLeagueData('<leagueId>', secondUserAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(leaveExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeavePrivateExchangeLeague Missing Token Response:', response
    * match response.data.leaveExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                        | expectedStatus | expectedMessage         | expectedErrorCode   |
      | existingPrivateExchangeLeagueId | 400            | Missing token in header | MISSING_TOKEN       |

  @expired_token
  Scenario Outline: LeavePrivateExchangeLeague fails with expired token
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (privateExchangeLeagueId == null) karate.abort()

    * def expiredToken = '<expiredToken>'
    * def build = buildLeagueData('<leagueId>', secondUserAccessToken)
    * header Authorization = expiredToken
    * def payload = { query: '#(leaveExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeavePrivateExchangeLeague Expired Token Response:', response
    * match response.data.leaveExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                        | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage | expectedErrorCode   |
      | existingPrivateExchangeLeagueId | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   | EXPIRED_TOKEN       |

  @invalid_token
  Scenario Outline: LeavePrivateExchangeLeague fails with invalid or corrupted token
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (privateExchangeLeagueId == null) karate.abort()

    * def invalidToken = '<invalidToken>'
    * def build = buildLeagueData('<leagueId>', secondUserAccessToken)
    * header Authorization = invalidToken
    * def payload = { query: '#(leaveExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeavePrivateExchangeLeague Invalid Token Response:', response
    * match response.data.leaveExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                        | invalidToken                      | expectedStatus | expectedMessage | expectedErrorCode   |
      | existingPrivateExchangeLeagueId | Bearer invalidtoken123            | 401            | Invalid token   | INVALID_TOKEN       |
      | existingPrivateExchangeLeagueId | random_corrupted_string_12345     | 401            | Invalid token   | INVALID_TOKEN       |
      | existingPrivateExchangeLeagueId | invalid.token.string              | 401            | Invalid token   | INVALID_TOKEN       |

  @happy_path
  Scenario Outline: LeavePrivateExchangeLeague succeeds with valid league ID and verifies member is removed
    # PREREQUISITE CHECK: Ensure second user access token and league ID exist and season is preseason
    * if (secondUserAccessToken == null) karate.fail('No second user access token found. Run createSecondUser.feature first')
    * if (privateExchangeLeagueId == null) karate.abort()
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')
    
    # Step 1: Second user leaves the private league
    * def build = buildLeagueData('<leagueId>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(leaveExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeavePrivateExchangeLeague Success Response:', response
    * match response.data.leaveExchangeLeague.statusCode == <expectedStatus>
    * match response.data.leaveExchangeLeague.message == '<expectedMessage>'
    
    # Step 2: Verify second user is no longer a member by calling getExchangeLeague
    * def getLeaguePayload = { query: '#(getExchangeLeagueQuery)', variables: '#(build.variables)' }
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * header Authorization = build.authToken
    
    Given request getLeaguePayload
    When method post
    Then status 200
    * print 'GetExchangeLeague After Leave Response:', response
    * match response.data.getExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == 403
    * match response.errors[0].message contains 'You do not have permission to view this league'

    Examples:
      | leagueId                        | expectedStatus | expectedMessage                                    |
      | existingPrivateExchangeLeagueId | 200            | You have successfully left the Exchange league.    |

  @not_league_member
  Scenario Outline: LeavePrivateExchangeLeague fails when user is not a member
    # PREREQUISITE CHECK: Ensure second user access token and league ID exist
    * if (secondUserAccessToken == null) karate.fail('No second user access token found. Run createSecondUser.feature first')
    * if (privateExchangeLeagueId == null) karate.abort()

    # Attempt to leave the league again (should fail as second user already left)
    * def build = buildLeagueData('<leagueId>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(leaveExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeavePrivateExchangeLeague Not Member Response:', response
    * match response.data.leaveExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                        | expectedStatus | expectedMessage                         | expectedErrorCode           |
      | existingPrivateExchangeLeagueId | 404            | You are not a member of this league.    | LEAGUE_MEMBERSHIP_NOT_FOUND |