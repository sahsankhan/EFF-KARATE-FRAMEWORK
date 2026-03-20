Feature: EFF Data - Get Private Blitz League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def getBlitzLeagueQuery = read('classpath:graphql/eff-data/blitzLeagues/getBlitzLeague.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def privateBlitzLeagueId = karate.get('signUpInfo.privateBlitzLeagueId', null)
    * def initialPrivateBlitzLeagueMemberCount = karate.get('signUpInfo.initialPrivateBlitzLeagueMemberCount', null)
    * def buildLeagueData =
      """
      function(leagueId, existingAccessToken) {
        var idValue = leagueId;
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPrivateBlitzLeagueId') idValue = privateBlitzLeagueId;
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        return { authToken: existingAccessToken, variables: { League_ID: idValue } };
      }
      """

  @happy_path
  Scenario Outline: GetBlitzLeague succeeds with valid league ID and verifies member count increment
    # PREREQUISITE CHECK: Ensure access token and league ID exist and season is preseason
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * call read('classpath:helpers/checkAndEnsurePreseason.feature') 
    * if (privateBlitzLeagueId == null) karate.abort()
    
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
    * match league._id == privateBlitzLeagueId
    * match league.League_Type == 'BLITZ'
    * match league.Game_Type == 'EXTREME'
    * match league.Public == false
    
    # Verify member count increased after user joined and created team
    * def currentMemberCount = league.Members
    * print 'Current Member Count:', currentMemberCount
    
    * if (initialPrivateBlitzLeagueMemberCount != null && currentMemberCount <= initialPrivateBlitzLeagueMemberCount) karate.fail('Member count should have increased after joining. Before=' + initialPrivateBlitzLeagueMemberCount + ', After=' + currentMemberCount)

    Examples:
      | leagueId                      | expectedStatus | 
      | existingPrivateBlitzLeagueId  | 200            | 

 