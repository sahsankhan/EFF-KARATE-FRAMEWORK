Feature: EFF Data - Leave Blitz League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def leaveBlitzLeagueQuery = read('classpath:resources/graphql/eff-data/blitzLeagues/leaveBlitzLeague.graphql')
    * def getBlitzLeagueQuery = read('classpath:resources/graphql/eff-data/blitzLeagues/getBlitzLeague.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def extremeBlitzLeagueId = karate.get('signUpInfo.extremeBlitzLeagueId', null)
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
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(leaveBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'LeaveBlitzLeague Missing Token Response:', response
    * match response.data.leaveBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                      | expectedStatus | expectedMessage         |
      | existingPublicBlitzLeagueId   | 400            | Missing token in header |

  @expired_token
  Scenario Outline: LeaveBlitzLeague fails with expired token
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
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | leagueId                     | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage |
      | existingPublicBlitzLeagueId  | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   |

  @invalid_token
  Scenario Outline: LeaveBlitzLeague fails with invalid or corrupted token
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
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | leagueId                      | invalidToken                      | expectedStatus | expectedMessage |
      | existingPublicBlitzLeagueId   | Bearer invalidtoken123            | 401            | Invalid token   |
      | existingPublicBlitzLeagueId   | random_corrupted_string_12345     | 401            | Invalid token   |
      | existingPublicBlitzLeagueId   | invalid.token.string              | 401            | Invalid token   |

  @happy_path
  Scenario Outline: LeaveBlitzLeague succeeds with valid league ID and verifies member is removed
    # PREREQUISITE CHECK: Ensure access token and league ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremeBlitzLeagueId == null) karate.fail('No Blitz Extreme league ID found. Run getPublicBlitzLeagues.feature first')
    
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

    Examples:
      | leagueId                      | expectedStatus | expectedMessage                                 |
      | existingPublicBlitzLeagueId   | 200            | You have successfully left the Blitz league.    |

  @not_league_member
  Scenario Outline: LeaveBlitzLeague fails when user is not a member
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
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
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                      | expectedStatus | expectedMessage                         |
      | existingPublicBlitzLeagueId   | 404            | You are not a member of this league.    |

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
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId | expectedStatus | expectedMessage   |
      | 999999   | 404            | League not found  |
      | 100000   | 404            | League not found  |

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
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId      | expectedStatus | expectedMessage                                 |
      | invalid       | 400            | Invalid League_ID format. Expected numeric ID.  |
      | abc123        | 400            | Invalid League_ID format. Expected numeric ID.  |
      | league_id     | 400            | Invalid League_ID format. Expected numeric ID.  |
      | -999999       | 400            | Invalid League_ID format. Expected numeric ID.  |
      | -100000       | 400            | Invalid League_ID format. Expected numeric ID.  |