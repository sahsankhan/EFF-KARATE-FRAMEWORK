Feature: EFF Data - Get Exchange League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def getExchangeLeagueQuery = read('classpath:graphql/eff-data/exchangeLeagues/getExchangeLeague.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def extremePublicExchangeLeagueId = karate.get('signUpInfo.extremePublicExchangeLeagueId', null)
    * def initialPublicExchangeLeagueMemberCount = karate.get('signUpInfo.initialPublicExchangeLeagueMemberCount', null)
    * def buildLeagueData =
      """
      function(leagueId, existingAccessToken) {
        var idValue = leagueId;
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPublicExchangeLeagueId') idValue = extremePublicExchangeLeagueId;
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        return { authToken: existingAccessToken, variables: { League_ID: idValue } };
      }
      """

  @missing_authorization_header
  Scenario Outline: GetExchangeLeague fails when Authorization header is missing
    # PREREQUISITE CHECK: Ensure league ID exist
    * if (extremePublicExchangeLeagueId == null) karate.abort()

    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(getExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeLeague Missing Token Response:', response
    * match response.data.getExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                        | expectedStatus | expectedMessage         | expectedErrorCode   |
      | existingPublicExchangeLeagueId  | 400            | Missing token in header | MISSING_TOKEN       |

  @expired_token
  Scenario Outline: GetExchangeLeague fails with expired token
    # PREREQUISITE CHECK: Ensure league ID exist
    * if (extremePublicExchangeLeagueId == null) karate.abort()

    * def expiredToken = '<expiredToken>'
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = expiredToken
    * def payload = { query: '#(getExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeLeague Expired Token Response:', response
    * match response.data.getExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                       | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage | expectedErrorCode   |
      | existingPublicExchangeLeagueId | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   | EXPIRED_TOKEN       |

  @invalid_token
  Scenario Outline: GetExchangeLeague fails with invalid or corrupted token
    # PREREQUISITE CHECK: Ensure league ID exist
    * if (extremePublicExchangeLeagueId == null) karate.abort()

    * def invalidToken = '<invalidToken>'
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = invalidToken
    * def payload = { query: '#(getExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeLeague Invalid Token Response:', response
    * match response.data.getExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                        | invalidToken                      | expectedStatus | expectedMessage | expectedErrorCode   |
      | existingPublicExchangeLeagueId  | invalid.token.string              | 401            | Invalid token   | INVALID_TOKEN       |
      | existingPublicExchangeLeagueId  | random_corrupted_string_12345     | 401            | Invalid token   | INVALID_TOKEN       |
      | existingPublicExchangeLeagueId  | Bearer invalidtoken123            | 401            | Invalid token   | INVALID_TOKEN       |

  @happy_path
  Scenario Outline: GetExchangeLeague succeeds with valid league ID and verifies member count increment
    # PREREQUISITE CHECK: Ensure access token and league ID exist and season is preseason
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremePublicExchangeLeagueId == null) karate.abort()
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeLeague Valid ID Response:', response
    * match response.data.getExchangeLeague.statusCode == <expectedStatus>
    * match response.data.getExchangeLeague.leagues == '#array'
    * match response.data.getExchangeLeague.leagues[0] == '#present'
    
    # Validate league data
    * def league = response.data.getExchangeLeague.leagues[0]
    * match league._id == extremePublicExchangeLeagueId
    * match league.League_Type == 'EXCHANGE'
    * match league.Game_Type == 'EXTREME'
    * match league.Public == true
    
    # Verify member count increased after user joined and created team
    * def currentMemberCount = league.Members
    * print 'Current Member Count:', currentMemberCount
    
    * if (initialPublicExchangeLeagueMemberCount != null && currentMemberCount <= initialPublicExchangeLeagueMemberCount) karate.fail('Member count should have increased after joining. Before=' + initialPublicExchangeLeagueMemberCount + ', After=' + currentMemberCount)
    
    # Save current member count for leave verification
    * def updatedInfo = signUpInfo
    * updatedInfo.currentExchangeMemberCount = currentMemberCount
    * karate.write(updatedInfo, 'target/info.txt')

    Examples:
      | leagueId                        | expectedStatus | 
      | existingPublicExchangeLeagueId  | 200            | 

  @league_id_not_found
  Scenario Outline: GetExchangeLeague fails with invalid league ID
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeLeague Invalid ID Response:', response
    * match response.data.getExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId | expectedStatus | expectedMessage                 | expectedErrorCode   |
      | 999999   | 404            | League not found or deleted     | LEAGUE_NOT_FOUND    |
      | 100000   | 404            | League not found or deleted     | LEAGUE_NOT_FOUND    |

  @invalid_league_id
  Scenario Outline: GetExchangeLeague with string league ID
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeLeague String ID Response:', response
    * match response.data.getExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId      | expectedStatus | expectedMessage                 | expectedErrorCode   |
      | invalid       | 400            | League_ID must be a numeric ID. | INVALID_LEAGUE_ID   |
      | abc123        | 400            | League_ID must be a numeric ID. | INVALID_LEAGUE_ID   |
      | league_id     | 400            | League_ID must be a numeric ID. | INVALID_LEAGUE_ID   |
      | 0             | 400            | Invalid League_ID format!       | INVALID_LEAGUE_ID   |
      | -999999       | 400            | Invalid League_ID format!       | INVALID_LEAGUE_ID   |
      | -100000       | 400            | Invalid League_ID format!       | INVALID_LEAGUE_ID   |