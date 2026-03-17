Feature: EFF Data - Join Private Exchange League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def joinPrivateExchangeLeagueQuery = read('classpath:graphql/eff-data/exchangeLeagues/joinPrivateExchangeLeague.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def secondUser = karate.get('signUpInfo.secondUser', null)
    * def secondUserAccessToken = karate.get('signUpInfo.secondUser.accessToken', null)
    * def privateExchangeLeagueInviteCode = karate.get('signUpInfo.privateExchangeLeagueInviteCode', null)
    * def privateExchangeLeagueId = karate.get('signUpInfo.privateExchangeLeagueId', null)
    * def buildJoinExchangeLeagueData =
      """
      function(inviteCode, secondUserAccessToken) {
        var codeValue = inviteCode;
        if (codeValue === 'null') codeValue = null;
        if (codeValue === 'existing') codeValue = privateExchangeLeagueInviteCode;
        
        return { authToken: secondUserAccessToken, variables: { Invite_Code: codeValue } };
      }
      """

  @missing_authorization_header
  Scenario Outline: JoinPrivateExchangeLeague fails when Authorization header is missing
    * def build = buildJoinExchangeLeagueData('<inviteCode>', secondUserAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(joinPrivateExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPrivateExchangeLeague Missing Token Response:', response
    * match response.data.joinPrivateExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | inviteCode | expectedStatus | expectedMessage         | expectedErrorCode |
      | 24034X     | 400            | Missing token in header | MISSING_TOKEN     |

  @expired_token
  Scenario Outline: JoinPrivateExchangeLeague fails with expired token
    * def expiredToken = '<expiredToken>'
    * def build = buildJoinExchangeLeagueData('<inviteCode>', secondUserAccessToken)
    * header Authorization = expiredToken
    * def payload = { query: '#(joinPrivateExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPrivateExchangeLeague Expired Token Response:', response
    * match response.data.joinPrivateExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | inviteCode | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage | expectedErrorCode |
      | 24034X     | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   | EXPIRED_TOKEN     |

  @invalid_token
  Scenario Outline: JoinPrivateExchangeLeague fails with invalid or corrupted token
    * def invalidToken = '<invalidToken>'
    * def build = buildJoinExchangeLeagueData('<inviteCode>', secondUserAccessToken)
    * header Authorization = invalidToken
    * def payload = { query: '#(joinPrivateExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPrivateExchangeLeague Invalid Token Response:', response
    * match response.data.joinPrivateExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | inviteCode | invalidToken                      | expectedStatus | expectedMessage | expectedErrorCode |
      | 24034X     | invalid.token.string              | 401            | Invalid token   | INVALID_TOKEN     |
      | 24034X     | random_corrupted_string_12345     | 401            | Invalid token   | INVALID_TOKEN     |
      | 24034X     | Bearer invalidtoken123            | 401            | Invalid token   | INVALID_TOKEN     |

  @invalid_invite_code
  Scenario Outline: JoinPrivateExchangeLeague fails with invalid invite code
    # PREREQUISITE CHECK: Ensure second user token exists
    * if (secondUserAccessToken == null) karate.fail('No second user found. Run helpers/createSecondUser.feature first')

    * def build = buildJoinExchangeLeagueData('<inviteCode>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(joinPrivateExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPrivateExchangeLeague Invalid Invite Code Response:', response
    * match response.data.joinPrivateExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | inviteCode      | expectedStatus | expectedMessage        | expectedErrorCode      |
      | INVALID123      | 404            | Invalid invite code!   | INVALID_INVITE_CODE    |
      | WRONGCODE       | 404            | Invalid invite code!   | INVALID_INVITE_CODE    |
      | ABC123          | 404            | Invalid invite code!   | INVALID_INVITE_CODE    |
      | 12345           | 404            | Invalid invite code!   | INVALID_INVITE_CODE    |
      | EXPIRED123      | 404            | Invalid invite code!   | INVALID_INVITE_CODE    |

  @happy_path
  Scenario Outline: JoinPrivateExchangeLeague succeeds with valid invite code
    # PREREQUISITE CHECK: Ensure second user token exists, season is preseason and invite code exists
    * if (secondUserAccessToken == null) karate.fail('No second user found. Run helpers/createSecondUser.feature first')
    * if (privateExchangeLeagueInviteCode == null) karate.fail('No invite code found. Run createExchangeLeague.feature first')
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')

    * def build = buildJoinExchangeLeagueData('<inviteCode>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(joinPrivateExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPrivateExchangeLeague Success Response:', response
    * match response.data.joinPrivateExchangeLeague.statusCode == <expectedStatus>
    * match response.data.joinPrivateExchangeLeague.message == '<expectedMessage>'
    * match response.data.joinPrivateExchangeLeague.League_ID == '#present'
    * match response.data.joinPrivateExchangeLeague.League_ID == privateExchangeLeagueId

    Examples:
      | inviteCode | expectedStatus | expectedMessage                             |
      | existing   | 200            | Successfully joined the Exchange league.    |

  @already_member
  Scenario Outline: JoinPrivateExchangeLeague fails when user is already a member
    # PREREQUISITE CHECK: Ensure second user token exists
    * if (secondUserAccessToken == null) karate.fail('No second user found. Run helpers/createSecondUser.feature first')
    # PREREQUISITE CHECK: Ensure invite code exists
    * if (privateExchangeLeagueInviteCode == null) karate.fail('No invite code found. Run createExchangeLeague.feature first')

    # User already joined in @happy_path scenario
    * def build = buildJoinExchangeLeagueData('<inviteCode>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(joinPrivateExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'JoinPrivateExchangeLeague Already Member Response:', response
    * match response.data.joinPrivateExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | inviteCode | expectedStatus | expectedMessage                                                                      | expectedErrorCode                |
      | existing   | 409            | You have already joined this league. Please create a team to participate.          | LEAGUE_JOINED_TEAM_NOT_CREATED   |
