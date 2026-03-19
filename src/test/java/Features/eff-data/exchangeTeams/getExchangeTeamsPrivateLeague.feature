Feature: EFF Data - Get Exchange Teams For Private Exchange League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def getExchangeTeamsQuery = read('classpath:graphql/eff-data/exchangeTeams/getExchangeTeams.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def secondUserAccessToken = karate.get('signUpInfo.secondUser.accessToken', null)
    * def privateExchangeTeamId = karate.get('signUpInfo.secondUserPrivateExchangeTeamId', null)
    * def privateExchangeTeamName = karate.get('signUpInfo.secondUserPrivateExchangeTeamName', null)
    * def privateExchangeLeagueId = karate.get('signUpInfo.privateExchangeLeagueId', null)

  @happy_path
  Scenario Outline: GetExchangeTeams successfully retrieves all user's exchange teams from private league
    # PREREQUISITE CHECK: Ensure second user access token and team ID exist and season is preseason
    * if (secondUserAccessToken == null) karate.fail('No second user access token found. Run createSecondUser.feature first')
    * if (privateExchangeTeamId == null) karate.abort()
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')
    
    * header Authorization = secondUserAccessToken
    * def payload = { query: '#(getExchangeTeamsQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeams Success Response:', response
    * match response.data.getExchangeTeams.statusCode == <expectedStatus>
    * match response.data.getExchangeTeams.teams == '#array'
    * match response.data.getExchangeTeams.teams == '#notnull'
    
    # Validate that teams array is not empty for user with teams
    * def teamsCount = response.data.getExchangeTeams.teams.length
    * assert teamsCount > 0
    * print 'Total Exchange Teams Retrieved:', teamsCount
    
    # Find the created team in the results
    * def createdTeam = karate.filter(response.data.getExchangeTeams.teams, function(team){ return team._id == privateExchangeTeamId + '' })
    * assert createdTeam.length == 1
    * print 'Found Created Exchange Team:', createdTeam[0]
    
    # Validate the created team data matches what was created
    * def team = createdTeam[0]
    * match team._id == privateExchangeTeamId + ''
    * match team.Team_Name == privateExchangeTeamName
    * match team.League_ID == privateExchangeLeagueId
    * match team.Owner_Email == signUpInfo.secondUser.email
    * match team.Cash == 1000.0
    * match team.Assets_Value == 0.0
    * match team.Total_Value == 1000.0
    * match team.Total_Transactions == 0
    * match team.Transaction_Limit == null
    
    # Validate owner information
    * match team.owner == '#present'
    * match team.owner.id == '#present'
    * match team.owner.username == '#present'
    
    # Validate league details
    * match team.league_details == '#present'
    * match team.league_details.Game_Type == 'EXTREME'
    * match team.league_details.League_Type == 'EXCHANGE'
    * match team.league_details.Public == false

     Examples:
      | expectedStatus |
      | 200            |