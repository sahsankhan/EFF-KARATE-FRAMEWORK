Feature: EFF Data - Create Blitz Team (Private League) API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:/common/error-codes.json')
    * def createBlitzTeamQuery = read('classpath:/graphql/eff-data/blitzTeams/createBlitzTeam.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def secondUserAccessToken = karate.get('signUpInfo.secondUser.accessToken', null)
    * def privateBlitzLeagueId = karate.get('signUpInfo.privateBlitzLeagueId', null)
    * def random = function() { return java.lang.Math.floor(java.lang.Math.random() * 100000); }
    * def buildTeamData =
      """
      function(teamName, teamImage, leagueId, accessToken) {
        var nameValue = teamName;
        var imageValue = teamImage;
        var idValue = leagueId;

        if (nameValue === 'random') {
           nameValue = 'Blitz Team' + random() + Date.now(); 
        }

        // Handle special keywords for dynamic values
        if (nameValue === 'null') nameValue = null;
        if (nameValue === 'true') nameValue = true;
        if (nameValue === 'false') nameValue = false;
        if (imageValue === 'null') imageValue = null;
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPrivateBlitzLeagueId') idValue = privateBlitzLeagueId;
        
        // Convert numeric strings to numbers
        if (!isNaN(nameValue) && nameValue !== '' && nameValue !== null) {
          nameValue = Number(nameValue);
        }
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        
        var variables = { Team_Name: nameValue, League_ID: idValue };
        
        // Only include Team_Image if it's defined
        if (imageValue !== undefined) {
          variables.Team_Image = imageValue;
        }
        
        return { authToken: accessToken, variables: variables };
      }
      """

  @happy_path_private_league
  Scenario Outline: CreateBlitzTeam succeeds for second user in private league and saves Team_ID
    * if (secondUserAccessToken == null) karate.abort()
    * if (privateBlitzLeagueId == null) karate.abort()

    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }

    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Private League Success Response:', response
    * match response.data.createBlitzTeam.statusCode == <expectedStatus>
    * match response.data.createBlitzTeam.message == '<expectedMessage>'
    * match response.data.createBlitzTeam.Team_ID == '#present'
    * match response.data.createBlitzTeam.Team_ID == '#notnull'

    * def createdTeamId = response.data.createBlitzTeam.Team_ID
    * def createdTeamName = build.variables.Team_Name
    * karate.write({email: signUpInfo.email, resetKey: signUpInfo.resetKey, password: signUpInfo.password, isVerified: signUpInfo.isVerified, passwordSet: signUpInfo.passwordSet, refreshToken: signUpInfo.refreshToken, accessToken: signUpInfo.accessToken, extremeBlitzLeagueId: signUpInfo.extremeBlitzLeagueId, privateBlitzLeagueId: signUpInfo.privateBlitzLeagueId, privateBlitzLeagueInviteCode: signUpInfo.privateBlitzLeagueInviteCode, secondUser: signUpInfo.secondUser, privateBlitzTeamId: signUpInfo.privateBlitzTeamId, privateBlitzTeamName: signUpInfo.privateBlitzTeamName, secondUserPrivateBlitzTeamId: createdTeamId, secondUserPrivateBlitzTeamName: createdTeamName}, 'target/info.txt')
    * karate.log('Saved Second User Private Blitz Team ID:', createdTeamId)

    Examples:
      | teamName | teamImage  | leagueId                       | expectedStatus | expectedMessage                 |
      | random   | icon_tiger | existingPrivateBlitzLeagueId   | 200            | Blitz Team created successfully |

  @user_already_has_team_in_private_league
  Scenario Outline: CreateBlitzTeam fails when second user already has a team in the private league
    * if (secondUserAccessToken == null) karate.abort()
    * if (privateBlitzLeagueId == null) karate.abort()
    * def existingTeamId = karate.get('signUpInfo.secondUserPrivateBlitzTeamId', null)
    * if (existingTeamId == null) karate.abort()

    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }

    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Private League User Already Has Team Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName          | teamImage  | leagueId                       | expectedStatus | expectedMessage                         | expectedErrorCode   |
      | SecondTeamAttempt | icon_skull | existingPrivateBlitzLeagueId   | 409            | You already have a team in this league. | TEAM_ALREADY_EXISTS |
