Feature: EFF Data - Get Private Exchange League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def getExchangeLeagueQuery = read('classpath:graphql/eff-data/exchangeLeagues/getExchangeLeague.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def privateExchangeLeagueId = karate.get('signUpInfo.privateExchangeLeagueId', null)
    * def initialPrivateExchangeLeagueMemberCount = karate.get('signUpInfo.initialPrivateExchangeLeagueMemberCount', null)
    * def buildLeagueData =
      """
      function(leagueId, existingAccessToken) {
        var idValue = leagueId;
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPrivateExchangeLeagueId') idValue = privateExchangeLeagueId;
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        return { authToken: existingAccessToken, variables: { League_ID: idValue } };
      }
      """
      
  @happy_path
  Scenario Outline: GetExchangeLeague succeeds with valid league ID and verifies member count increment
    # PREREQUISITE CHECK: Ensure access token and league ID exist and season is preseason
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * call read('classpath:helpers/checkAndEnsurePreseason.feature') 
    * if (privateExchangeLeagueId == null) karate.abort()
    
    * def build = buildLeagueData('<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(getExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetExchangeLeague Valid ID Response:', response
    * match response.data.getExchangeLeague.statusCode == <expectedStatus>
    * match response.data.getExchangeLeague.leagues == '#array'
    * match response.data.getExchangeLeague.leagues[0] == '#present'
    
    # Validate league data
    * def league = response.data.getExchangeLeague.leagues[0]
    * match league._id == privateExchangeLeagueId
    * match league.League_Type == 'EXCHANGE'
    * match league.Game_Type == 'EXTREME'
    * match league.Public == false
    
    # Verify member count increased after second user joined and created team
    * def currentMemberCount = league.Members
    * print 'Current Member Count:', currentMemberCount
    
    * if (initialPrivateExchangeLeagueMemberCount != null && currentMemberCount <= initialPrivateExchangeLeagueMemberCount) karate.fail('Member count should have increased after joining. Before=' + initialPrivateExchangeLeagueMemberCount + ', After=' + currentMemberCount)

    Examples:
      | leagueId                          | expectedStatus | 
      | existingPrivateExchangeLeagueId   | 200            | 