Feature: EFF Data - Get Exchange Teams by Private Exchange League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def getExchangeTeamsByLeagueQuery = read('classpath:graphql/eff-data/exchangeTeams/getExchangeTeamsByLeague.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def secondUserAccessToken = karate.get('signUpInfo.secondUser.accessToken', null)
    * def privateExchangeLeagueId = karate.get('signUpInfo.privateExchangeLeagueId', null)
    * def privateExchangeTeamId = karate.get('signUpInfo.secondUserPrivateExchangeTeamId', null)
    * def privateExchangeTeamName = karate.get('signUpInfo.secondUserPrivateExchangeTeamName', null)
    * def buildLeagueData =
      """
      function(leagueId, secondUserAccessToken) {
        var idValue = leagueId;
        
        // Handle special keywords for dynamic values
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPrivateExchangeLeagueId') idValue = privateExchangeLeagueId;
        
        // Convert numeric strings to numbers
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        
        return { authToken: secondUserAccessToken, variables: { League_ID: idValue } };
      }
      """

  @happy_path
  Scenario Outline: getExchangeTeamsByLeague successfully retrieves all teams in the league
    # PREREQUISITE CHECK: Ensure second user access token, league ID, and team ID exist and season is preseason
    * if (secondUserAccessToken == null) karate.fail('No second user access token found. Run createSecondUser.feature first')
    * if (privateExchangeLeagueId == null) karate.abort()
    * if (privateExchangeTeamId == null) karate.abort()
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')

    
    * def build = buildLeagueData('<leagueId>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getExchangeTeamsByLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeamsByLeague Success Response:', response
    * match response.data.getExchangeTeamsByLeague.statusCode == <expectedStatus>
    * match response.data.getExchangeTeamsByLeague.teams == '#array'
    * match response.data.getExchangeTeamsByLeague.teams == '#notnull'
    
    # Validate that teams array is not empty
    * def teamsCount = response.data.getExchangeTeamsByLeague.teams.length
    * assert teamsCount > 0
    * print 'Total Teams in League:', teamsCount
    
    # Find the user's created team in the league results
    * def userTeam = karate.filter(response.data.getExchangeTeamsByLeague.teams, function(team){ return team._id == privateExchangeTeamId + '' })
    * assert userTeam.length == 1
    * print 'Found User Created Team in League:', userTeam[0]
    
    # Validate the user's team data
    * def team = userTeam[0]
    * match team._id == privateExchangeTeamId + ''
    * match team.Team_Name == privateExchangeTeamName
    * match team.League_ID == privateExchangeLeagueId
    * match team.Owner_Email == signUpInfo.secondUser.email
    * match team.Cash == 1000.0
    * match team.Assets_Value == 0.0
    * match team.Total_Value == 1000.0
    * match team.Total_Transactions == 0
    * match team.Transaction_Limit == null
    
    # Validate league details
    * match team.league_details == '#present'
    * match team.league_details.Game_Type == 'EXTREME'
    * match team.league_details.League_Type == 'EXCHANGE'
    * match team.league_details.Public == false

    Examples:
      | leagueId                         | expectedStatus | 
      | existingPrivateExchangeLeagueId  | 200            | 

 