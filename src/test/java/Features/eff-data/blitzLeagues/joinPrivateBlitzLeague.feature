Feature: EFF Data - Join Private Blitz League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def joinPrivateBlitzLeagueQuery = read('classpath:graphql/eff-data/blitzLeagues/joinPrivateBlitzLeague.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def secondUser = karate.get('signUpInfo.secondUser', null)
    * def secondUserAccessToken = karate.get('signUpInfo.secondUser.accessToken', null)
    * def privateBlitzLeagueInviteCode = karate.get('signUpInfo.privateBlitzLeagueInviteCode', null)
    * def privateBlitzLeagueId = karate.get('signUpInfo.privateBlitzLeagueId', null)
    * def buildJoinLeagueData =
      """
      function(inviteCode, secondUserAccessToken) {
        var codeValue = inviteCode;
        if (codeValue === 'null') codeValue = null;
        if (codeValue === 'existing') codeValue = privateBlitzLeagueInviteCode;
        
        return { authToken: secondUserAccessToken, variables: { Invite_Code: codeValue } };
      }
      """

  @missing_authorization_header
  Scenario Outline: JoinPrivateBlitzLeague fails when Authorization header is missing
    # PREREQUISITE CHECK: Ensure invite code exists
    * if (privateBlitzLeagueInviteCode == null) karate.fail('No invite code found. Run createBlitzLeague.feature first')
   
    * def build = buildJoinLeagueData('<inviteCode>', secondUserAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(joinPrivateBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPrivateBlitzLeague Missing Token Response:', response
    * match response.data.joinPrivateBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | inviteCode | expectedStatus | expectedMessage         |  expectedErrorCode   |
      | existing   | 400            | Missing token in header |  MISSING_TOKEN       |

  @expired_token
  Scenario Outline: JoinPrivateBlitzLeague fails with expired token
    # PREREQUISITE CHECK: Ensure invite code exists
    * if (privateBlitzLeagueInviteCode == null) karate.fail('No invite code found. Run createBlitzLeague.feature first')

    * def expiredToken = '<expiredToken>'
    * def build = buildJoinLeagueData('<inviteCode>', secondUserAccessToken)
    * header Authorization = expiredToken
    * def payload = { query: '#(joinPrivateBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPrivateBlitzLeague Expired Token Response:', response
    * match response.data.joinPrivateBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | inviteCode | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage |  expectedErrorCode   |
      | existing   | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   |  EXPIRED_TOKEN       |

  @invalid_token
  Scenario Outline: JoinPrivateBlitzLeague fails with invalid or corrupted token
    # PREREQUISITE CHECK: Ensure invite code exists
    * if (privateBlitzLeagueInviteCode == null) karate.fail('No invite code found. Run createBlitzLeague.feature first')

    * def invalidToken = '<invalidToken>'
    * def build = buildJoinLeagueData('<inviteCode>', secondUserAccessToken)
    * header Authorization = invalidToken
    * def payload = { query: '#(joinPrivateBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPrivateBlitzLeague Invalid Token Response:', response
    * match response.data.joinPrivateBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | inviteCode | invalidToken                      | expectedStatus | expectedMessage |  expectedErrorCode   |
      | existing   | invalid.token.string              | 401            | Invalid token   |  INVALID_TOKEN       |
      | existing   | random_corrupted_string_12345     | 401            | Invalid token   |  INVALID_TOKEN       |
      | existing   | Bearer invalidtoken123            | 401            | Invalid token   |  INVALID_TOKEN       |

  @invalid_invite_code
  Scenario Outline: JoinPrivateBlitzLeague fails with invalid invite code
    # PREREQUISITE CHECK: Ensure second user token exists
    * if (secondUserAccessToken == null) karate.fail('No second user found. Run helpers/createSecondUser.feature first')

    * def build = buildJoinLeagueData('<inviteCode>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(joinPrivateBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPrivateBlitzLeague Invalid Invite Code Response:', response
    * match response.data.joinPrivateBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | inviteCode      | expectedStatus | expectedMessage        |  expectedErrorCode   |
      | INVALID123      | 404            | Invalid invite code!   |  INVALID_INVITE_CODE |
      | WRONGCODE       | 404            | Invalid invite code!   |  INVALID_INVITE_CODE |
      | ABC123          | 404            | Invalid invite code!   |  INVALID_INVITE_CODE |

  @happy_path
  Scenario Outline: JoinPrivateBlitzLeague succeeds with valid invite code
    # PREREQUISITE CHECK: Ensure second user token exists
    * if (secondUserAccessToken == null) karate.fail('No second user found. Run helpers/createSecondUser.feature first')
    # PREREQUISITE CHECK: Ensure invite code exists
    * if (privateBlitzLeagueInviteCode == null) karate.fail('No invite code found. Run createBlitzLeague.feature first')
    # PREREQUISITE CHECK: Ensure private league ID exists
    * if (privateBlitzLeagueId == null) karate.fail('No private league ID found. Run createBlitzLeague.feature first')

    * def build = buildJoinLeagueData('<inviteCode>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(joinPrivateBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPrivateBlitzLeague Success Response:', response
    * match response.data.joinPrivateBlitzLeague.statusCode == <expectedStatus>
    * match response.data.joinPrivateBlitzLeague.message == '<expectedMessage>'
    * match response.data.joinPrivateBlitzLeague.League_ID == '#present'
    * match response.data.joinPrivateBlitzLeague.League_ID == privateBlitzLeagueId

    Examples:
      | inviteCode | expectedStatus | expectedMessage                            |
      | existing   | 200            | Successfully joined the Blitz league.      |

  @already_member
  Scenario Outline: JoinPrivateBlitzLeague fails when user is already a member
    # PREREQUISITE CHECK: Ensure second user token exists
    * if (secondUserAccessToken == null) karate.fail('No second user found. Run helpers/createSecondUser.feature first')
    # PREREQUISITE CHECK: Ensure invite code exists
    * if (privateBlitzLeagueInviteCode == null) karate.fail('No invite code found. Run createBlitzLeague.feature first')

    # User already joined in @happy_path scenario
    * def build = buildJoinLeagueData('<inviteCode>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(joinPrivateBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPrivateBlitzLeague Already Member Response:', response
    * match response.data.joinPrivateBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | inviteCode | expectedStatus | expectedMessage                                                            |  expectedErrorCode               |
      | existing   | 409            | You have already joined this league. Please create a team to participate.  |  LEAGUE_JOINED_TEAM_NOT_CREATED  |

