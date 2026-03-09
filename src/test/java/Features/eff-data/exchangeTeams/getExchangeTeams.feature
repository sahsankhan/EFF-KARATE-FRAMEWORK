Feature: EFF Data - Get Exchange Teams API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def getExchangeTeamsQuery = read('classpath:graphql/eff-data/exchangeTeams/getExchangeTeams.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def privateExchangeTeamId = karate.get('signUpInfo.privateExchangeTeamId', null)
    * def privateExchangeTeamName = karate.get('signUpInfo.privateExchangeTeamName', null)
    * def extremePublicExchangeLeagueId = karate.get('signUpInfo.extremePublicExchangeLeagueId', null)

  @missing_authorization_header
  Scenario Outline: GetExchangeTeams fails when Authorization header is missing
    # Do not set Authorization header
    * def payload = { query: '#(getExchangeTeamsQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeams Missing Token Response:', response
    * match response.data.getExchangeTeams == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

      Examples:
      | expectedStatus | expectedMessage         | expectedErrorCode   |
      | 400            | Missing token in header | MISSING_TOKEN       |

  @expired_token
  Scenario Outline: GetExchangeTeams fails with expired token
    * def expiredToken = '<expiredToken>'
    * header Authorization = expiredToken
    * def payload = { query: '#(getExchangeTeamsQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeams Expired Token Response:', response
    * match response.data.getExchangeTeams == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage | expectedErrorCode |
      | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   | EXPIRED_TOKEN     |

  @invalid_token
  Scenario Outline: GetExchangeTeams fails with invalid or corrupted token
    * def invalidToken = '<invalidToken>'
    * header Authorization = invalidToken
    * def payload = { query: '#(getExchangeTeamsQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeams Invalid Token Response:', response
    * match response.data.getExchangeTeams == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | invalidToken                      | expectedStatus | expectedMessage | expectedErrorCode |
      | invalid.token.string              | 401            | Invalid token   | INVALID_TOKEN     |
      | random_corrupted_string_12345     | 401            | Invalid token   | INVALID_TOKEN     |
      | Bearer invalidtoken123            | 401            | Invalid token   | INVALID_TOKEN     |

  @happy_path
  Scenario Outline: GetExchangeTeams successfully retrieves all user's exchange teams
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')
    
    * header Authorization = existingAccessToken
    * def payload = { query: '#(getExchangeTeamsQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeams Success Response:', response
    * match response.data.getExchangeTeams.statusCode == <expectedStatus>
    * match response.data.getExchangeTeams.teams == '#array'
    * match response.data.getExchangeTeams.teams == '#notnull'

    # Validate that teams array is not empty
    * def teamsCount = response.data.getExchangeTeams.teams.length
    * assert teamsCount > 0
    * print 'Total Teams Retrieved:', teamsCount
    
    # Find the created team in the results
    * def createdTeam = karate.filter(response.data.getExchangeTeams.teams, function(team){ return team._id == privateExchangeTeamId + '' })
    * assert createdTeam.length == 1
    * print 'Found Created Team:', createdTeam[0]
    
    # Validate the created team data matches what was created
    * def team = createdTeam[0]
    * match team._id == privateExchangeTeamId + ''
    * match team.Team_Name == privateExchangeTeamName
    * match team.League_ID == extremePublicExchangeLeagueId
    * match team.Owner_Email == signUpInfo.email
    
    # Validate league details
    * match team.league_details == '#present'
    * match team.league_details.Game_Type == 'EXTREME'
    * match team.league_details.League_Type == 'EXCHANGE'


    Examples:
      | expectedStatus  | 
      | 200             | 