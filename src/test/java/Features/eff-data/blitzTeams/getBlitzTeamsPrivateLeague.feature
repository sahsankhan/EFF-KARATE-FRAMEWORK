Feature: EFF Data - Get Blitz Teams For Private Blitz League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def getBlitzTeamsQuery = read('classpath:graphql/eff-data/blitzTeams/getBlitzTeams.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def secondUserAccessToken = karate.get('signUpInfo.secondUser.accessToken', null)
    * def privateBlitzTeamId = karate.get('signUpInfo.secondUserPrivateBlitzTeamId', null)
    * def privateBlitzTeamName = karate.get('signUpInfo.secondUserPrivateBlitzTeamName', null)
    * def privateBlitzLeagueId = karate.get('signUpInfo.privateBlitzLeagueId', null)

  @happy_path
  Scenario Outline: GetBlitzTeams successfully retrieves all user's teams
    # PREREQUISITE CHECK: Ensure second user access token and team ID exist
    * if (secondUserAccessToken == null) karate.fail('No second user access token found. Run createSecondUser.feature first')
    * if (privateBlitzTeamId == null) karate.abort()
    
    * header Authorization = secondUserAccessToken
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
    * match team.League_ID == privateBlitzLeagueId
    * match team.Owner_Email == signUpInfo.secondUser.email
    
    # Validate league details
    * match team.league_details == '#present'
    * match team.league_details.Game_Type == 'EXTREME'
    * match team.league_details.League_Type == 'BLITZ'
    * match team.league_details.Public == false

     Examples:
      | expectedStatus  | 
      | 200             | 