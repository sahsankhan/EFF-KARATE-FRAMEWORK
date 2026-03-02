Feature: EFF Data - Get Blitz Team for Private Blitz League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def getBlitzTeamQuery = read('classpath:graphql/eff-data/blitzTeams/getBlitzTeam.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def secondUserAccessToken = karate.get('signUpInfo.secondUser.accessToken', null)
    * def privateBlitzTeamId = karate.get('signUpInfo.secondUserPrivateBlitzTeamId', null)
    * def privateBlitzTeamName = karate.get('signUpInfo.secondUserPrivateBlitzTeamName', null)
    * def privateBlitzLeagueId = karate.get('signUpInfo.privateBlitzLeagueId', null)

    * def buildTeamData =
      """
      function(teamId, secondUserAccessToken) {
        var idValue = teamId;
        
        // Handle special keywords for dynamic values
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPrivateBlitzTeamId') idValue = privateBlitzTeamId;
        
        // Convert numeric strings to numbers
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        
        return { authToken: secondUserAccessToken, variables: { Team_ID: idValue } };
      }
      """

  @happy_path
  Scenario Outline: GetBlitzTeam succeeds when owner retrieves their own team created on a private league
    # PREREQUISITE CHECK: Ensure second user access token and team ID exist and season is preseason
    * if (secondUserAccessToken == null) karate.fail('No second user access token found. Run createSecondUser.feature first')
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')
    * if (privateBlitzTeamId == null) karate.abort()
    
    * def build = buildTeamData('<teamId>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetBlitzTeam Success Response:', response
    * match response.data.getBlitzTeam.statusCode == <expectedStatus>
    * match response.data.getBlitzTeam.teams == '#array'
    * match response.data.getBlitzTeam.teams[0] == '#present'
    
    # Validate team data
    * def team = response.data.getBlitzTeam.teams[0]
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
      | teamId                      | expectedStatus  | 
      | existingPrivateBlitzTeamId  | 200             | 
  