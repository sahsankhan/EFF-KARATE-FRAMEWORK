Feature: EFF Data - Get Exchange Team for Private Exchange League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def getExchangeTeamQuery = read('classpath:graphql/eff-data/exchangeTeams/getExchangeTeam.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def secondUserAccessToken = karate.get('signUpInfo.secondUser.accessToken', null)
    * def privateExchangeTeamId = karate.get('signUpInfo.secondUserPrivateExchangeTeamId', null)
    * def privateExchangeTeamName = karate.get('signUpInfo.secondUserPrivateExchangeTeamName', null)
    * def privateExchangeLeagueId = karate.get('signUpInfo.privateExchangeLeagueId', null)

    * def buildTeamData =
      """
      function(teamId, secondUserAccessToken) {
        var idValue = teamId;
        
        // Handle special keywords for dynamic values
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPrivateExchangeTeamId') idValue = privateExchangeTeamId;
        
        // Convert numeric strings to numbers
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        
        return { authToken: secondUserAccessToken, variables: { Team_ID: idValue } };
      }
      """

  @happy_path
  Scenario Outline: GetExchangeTeam succeeds when owner retrieves their own team created on a private league
    # PREREQUISITE CHECK: Ensure second user access token and team ID exist and season is preseason
    * if (secondUserAccessToken == null) karate.fail('No second user access token found. Run createSecondUser.feature first')
    * if (privateExchangeTeamId == null) karate.abort()
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')
    
    * def build = buildTeamData('<teamId>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getExchangeTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeTeam Success Response:', response
    * match response.data.getExchangeTeam.statusCode == <expectedStatus>
    * match response.data.getExchangeTeam.teams == '#array'
    * match response.data.getExchangeTeam.teams[0] == '#present'
    
    # Validate team data
    * def team = response.data.getExchangeTeam.teams[0]
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
      | teamId                          | expectedStatus  | 
      | existingPrivateExchangeTeamId   | 200             | 
