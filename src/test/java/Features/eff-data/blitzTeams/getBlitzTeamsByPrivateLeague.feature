Feature: EFF Data - Get Blitz Teams by Private Blitz League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def getBlitzTeamsByLeagueQuery = read('classpath:graphql/eff-data/blitzTeams/getBlitzTeamsByLeague.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def secondUserAccessToken = karate.get('signUpInfo.secondUser.accessToken', null)
    * def privateBlitzLeagueId = karate.get('signUpInfo.privateBlitzLeagueId', null)
    * def privateBlitzTeamId = karate.get('signUpInfo.secondUserPrivateBlitzTeamId', null)
    * def privateBlitzTeamName = karate.get('signUpInfo.secondUserPrivateBlitzTeamName', null)
    * def buildLeagueData =
      """
      function(leagueId, secondUserAccessToken) {
        var idValue = leagueId;
        
        // Handle special keywords for dynamic values
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPrivateBlitzLeagueId') idValue = privateBlitzLeagueId;
        
        // Convert numeric strings to numbers
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        
        return { authToken: secondUserAccessToken, variables: { League_ID: idValue } };
      }
      """

  @happy_path
  Scenario Outline: GetBlitzTeamsByLeague successfully retrieves all teams in the league
    # PREREQUISITE CHECK: Ensure second user access token, league ID, and team ID exist
    * if (secondUserAccessToken == null) karate.fail('No second user access token found. Run createSecondUser.feature first')
    * if (privateBlitzLeagueId == null) karate.abort()
    * if (privateBlitzTeamId == null) karate.abort()
    
    * def build = buildLeagueData('<leagueId>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getBlitzTeamsByLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeamsByLeague Success Response:', response
    * match response.data.getBlitzTeamsByLeague.statusCode == <expectedStatus>
    * match response.data.getBlitzTeamsByLeague.teams == '#array'
    * match response.data.getBlitzTeamsByLeague.teams == '#notnull'
    
    # Validate that teams array is not empty
    * def teamsCount = response.data.getBlitzTeamsByLeague.teams.length
    * assert teamsCount > 0
    * print 'Total Teams in League:', teamsCount
    
    # Find the user's created team in the league results
    * def userTeam = karate.filter(response.data.getBlitzTeamsByLeague.teams, function(team){ return team._id == privateBlitzTeamId + '' })
    * assert userTeam.length == 1
    * print 'Found User Created Team in League:', userTeam[0]
    
    # Validate the user's team data
    * def team = userTeam[0]
    * match team._id == privateBlitzTeamId + ''
    * match team.Team_Name == privateBlitzTeamName
    * match team.League_ID == privateBlitzLeagueId
    * match team.Owner_Email == signUpInfo.secondUser.email
    
    # Validate league details
    * match team.league_details == '#present'
    * match team.league_details.Game_Type == 'EXTREME'
    * match team.league_details.League_Type == 'BLITZ'
    * match team.league_details.Public == false

    Examples:
      | leagueId                      | expectedStatus | 
      | existingPrivateBlitzLeagueId  | 200            | 

 