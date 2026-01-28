Feature: EFF Data - Get Blitz Teams API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def getBlitzTeamsQuery = read('classpath:resources/graphql/eff-data/blitzTeams/getBlitzTeams.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def privateBlitzTeamId = karate.get('signUpInfo.privateBlitzTeamId', null)
    * def privateBlitzTeamName = karate.get('signUpInfo.privateBlitzTeamName', null)
    * def extremeBlitzLeagueId = karate.get('signUpInfo.extremeBlitzLeagueId', null)

  @missing_authorization_header
  Scenario Outline: GetBlitzTeams fails when Authorization header is missing
    # Do not set Authorization header
    * def payload = { query: '#(getBlitzTeamsQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeams Missing Token Response:', response
    * match response.data.getBlitzTeams == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

     Examples:
      | expectedStatus | expectedMessage         |
      | 400            | Missing token in header |

  @expired_token
  Scenario Outline: GetBlitzTeams fails with expired token
    * def expiredToken = '<expiredToken>'
    * header Authorization = expiredToken
    * def payload = { query: '#(getBlitzTeamsQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeams Expired Token Response:', response
    * match response.data.getBlitzTeams == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage |
      | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   |

  @invalid_token
  Scenario Outline: GetBlitzTeams fails with invalid or corrupted token
    * def invalidToken = '<invalidToken>'
    * header Authorization = invalidToken
    * def payload = { query: '#(getBlitzTeamsQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeams Invalid Token Response:', response
    * match response.data.getBlitzTeams == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | invalidToken                    | expectedStatus | expectedMessage |
      | invalid.token.string            | 401            | Invalid token   |
      | random_corrupted_string_12345   | 401            | Invalid token   |
      | Bearer invalidtoken123          | 401            | Invalid token   |

  @happy_path
  Scenario Outline: GetBlitzTeams successfully retrieves all user's teams
    # PREREQUISITE CHECK: Ensure access token, team ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (privateBlitzTeamId == null) karate.abort()
    
    * header Authorization = existingAccessToken
    * def payload = { query: '#(getBlitzTeamsQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeams Success Response:', response
    * match response.data.getBlitzTeams.statusCode == <expectedStatus>
    * match response.data.getBlitzTeams.teams == '#array'
    * match response.data.getBlitzTeams.teams == '#notnull'
    
    # Validate that teams array is not empty
    * def teamsCount = response.data.getBlitzTeams.teams.length
    * assert teamsCount > 0
    * print 'Total Teams Retrieved:', teamsCount
    
    # Find the created team in the results
    * def createdTeam = karate.filter(response.data.getBlitzTeams.teams, function(team){ return team._id == privateBlitzTeamId + '' })
    * assert createdTeam.length == 1
    * print 'Found Created Team:', createdTeam[0]
    
    # Validate the created team data matches what was created
    * def team = createdTeam[0]
    * match team._id == privateBlitzTeamId + ''
    * match team.Team_Name == privateBlitzTeamName
    * match team.League_ID == extremeBlitzLeagueId
    * match team.Owner_Email == signUpInfo.email
    
    # Validate league details
    * match team.league_details == '#present'
    * match team.league_details.Game_Type == 'EXTREME'
    * match team.league_details.League_Type == 'BLITZ'

     Examples:
      | expectedStatus  | 
      | 200             | 