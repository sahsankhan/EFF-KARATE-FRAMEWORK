Feature: EFF Data - Get Blitz League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
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
  Scenario Outline: GetBlitzLeague fails when Authorization header is missing
    # PREREQUISITE CHECK: Ensure league ID exist
    * if (extremeBlitzLeagueId == null) karate.abort()

    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(getBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzLeague Missing Token Response:', response
    * match response.data.getBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId                     | expectedStatus | expectedMessage         |
      | existingPublicBlitzLeagueId  | 400            | Missing token in header |

  @expired_token
  Scenario Outline: GetBlitzLeague fails with expired token
    # PREREQUISITE CHECK: Ensure league ID exist
    * if (extremeBlitzLeagueId == null) karate.abort()

    * def expiredToken = '<expiredToken>'
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = expiredToken
    * def payload = { query: '#(getBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzLeague Expired Token Response:', response
    * match response.data.getBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | leagueId                    | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage |
      | existingPublicBlitzLeagueId | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   |

  @invalid_token
  Scenario Outline: GetBlitzLeague fails with invalid or corrupted token
    # PREREQUISITE CHECK: Ensure league ID exist
    * if (extremeBlitzLeagueId == null) karate.abort()

    * def invalidToken = '<invalidToken>'
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = invalidToken
    * def payload = { query: '#(getBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzLeague Invalid Token Response:', response
    * match response.data.getBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | leagueId                     | invalidToken                      | expectedStatus | expectedMessage |
      | existingPublicBlitzLeagueId  | invalid.token.string              | 401            | Invalid token   |
      | existingPublicBlitzLeagueId  | random_corrupted_string_12345     | 401            | Invalid token   |
      | existingPublicBlitzLeagueId  | Bearer invalidtoken123            | 401            | Invalid token   |

  @happy_path
  Scenario Outline: GetBlitzLeague succeeds with valid league ID
    # PREREQUISITE CHECK: Ensure access token and league ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremeBlitzLeagueId == null) karate.abort()
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzLeague Valid ID Response:', response
    * match response.data.getBlitzLeague.statusCode == <expectedStatus>
    * match response.data.getBlitzLeague.leagues == '#array'
    * match response.data.getBlitzLeague.leagues[0] == '#present'
    
    # Validate league data
    * def league = response.data.getBlitzLeague.leagues[0]
    * match league._id == extremeBlitzLeagueId
    * match league.League_Type == 'BLITZ'
    * match league.Game_Type == 'EXTREME'
    * match league.Public == true

    Examples:
      | leagueId                     | expectedStatus | 
      | existingPublicBlitzLeagueId  | 200            | 

  @league_id_not_found
  Scenario Outline: GetBlitzLeague fails with invalid league ID
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzLeague Invalid ID Response:', response
    * match response.data.getBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId | expectedStatus | expectedMessage                 |
      | 999999   | 404            | League not found or deleted     |
      | 100000   | 404            | League not found or deleted     |

  @invalid_league_id
  Scenario Outline: GetBlitzLeague with string league ID
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzLeague String ID Response:', response
    * match response.data.getBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueId      | expectedStatus | expectedMessage                 |
      | invalid       | 400            | League_ID must be a numeric ID. |
      | abc123        | 400            | League_ID must be a numeric ID. |
      | league_id     | 400            | League_ID must be a numeric ID. |
      | 0             | 400            | Invalid League_ID format!       |
      | -999999       | 400            | Invalid League_ID format!       |
      | -100000       | 400            | Invalid League_ID format!       |