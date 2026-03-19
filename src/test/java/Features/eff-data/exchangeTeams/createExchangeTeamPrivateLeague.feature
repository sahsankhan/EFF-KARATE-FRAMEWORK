Feature: EFF Data - Create Exchange Team For Private Exchange League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:/common/error-codes.json')
    * def createExchangeTeamQuery = read('classpath:/graphql/eff-data/exchangeTeams/createExchangeTeam.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def secondUserAccessToken = karate.get('signUpInfo.secondUser.accessToken', null)
    * def privateExchangeLeagueId = karate.get('signUpInfo.privateExchangeLeagueId', null)
    * def buildTeamData =
      """
      function(teamName, teamImage, leagueId, accessToken) {
        var nameValue = teamName;
        var imageValue = teamImage;
        var idValue = leagueId;

        // Handle special keywords for dynamic values
        if (nameValue === 'null') nameValue = null;
        if (nameValue === 'true') nameValue = true;
        if (nameValue === 'false') nameValue = false;
        if (imageValue === 'null') imageValue = null;
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPrivateExchangeLeagueId') idValue = privateExchangeLeagueId;
        
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
  Scenario Outline: CreateExchangeTeam succeeds for second user in private league and saves Team_ID
    # PREREQUISITE CHECK: Ensure second user token exists and season is preseason
    * if (secondUserAccessToken == null) karate.fail('No second user found. Run helpers/createSecondUser.feature first')
    * if (privateExchangeLeagueId == null) karate.abort()
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')

    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createExchangeTeamQuery)', variables: '#(build.variables)' }

    Given request payload
    When method post
    Then status 200
    * print 'CreateExchangeTeam Private League Success Response:', response
    * match response.data.createExchangeTeam.statusCode == <expectedStatus>
    * match response.data.createExchangeTeam.message == '<expectedMessage>'
    * match response.data.createExchangeTeam.Team_ID == '#present'
    * match response.data.createExchangeTeam.Team_ID == '#notnull'

    * def createdTeamId = response.data.createExchangeTeam.Team_ID
    * def createdTeamName = build.variables.Team_Name
    * karate.write({email: signUpInfo.email, resetKey: signUpInfo.resetKey, password: signUpInfo.password, isVerified: signUpInfo.isVerified, passwordSet: signUpInfo.passwordSet, refreshToken: signUpInfo.refreshToken, accessToken: signUpInfo.accessToken, extremePublicBlitzLeagueId: signUpInfo.extremePublicBlitzLeagueId, extremePublicExchangeLeagueId: signUpInfo.extremePublicExchangeLeagueId, privateBlitzLeagueId: signUpInfo.privateBlitzLeagueId, privateBlitzLeagueInviteCode: signUpInfo.privateBlitzLeagueInviteCode, privateExchangeLeagueId: signUpInfo.privateExchangeLeagueId, privateExchangeLeagueInviteCode: signUpInfo.privateExchangeLeagueInviteCode, secondUser: signUpInfo.secondUser, secondUserPrivateBlitzTeamId: signUpInfo.secondUserPrivateBlitzTeamId, secondUserPrivateBlitzTeamName: signUpInfo.secondUserPrivateBlitzTeamName, secondUserPrivateExchangeTeamId: createdTeamId, secondUserPrivateExchangeTeamName: createdTeamName}, 'target/info.txt')
    * karate.log('Saved Second User Private Exchange Team ID:', createdTeamId)

    Examples:
      | teamName                | teamImage  | leagueId                          | expectedStatus | expectedMessage                    |
      | Private Exchange Team   | icon_tiger | existingPrivateExchangeLeagueId   | 200            | Exchange Team created successfully |

  @user_already_has_team_in_private_league
  Scenario Outline: CreateExchangeTeam fails when second user already has a team in the private league
    * if (secondUserAccessToken == null) karate.abort()
    * if (privateExchangeLeagueId == null) karate.abort()
    * def existingTeamId = karate.get('signUpInfo.secondUserPrivateExchangeTeamId', null)
    * if (existingTeamId == null) karate.abort()

    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', secondUserAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createExchangeTeamQuery)', variables: '#(build.variables)' }

    Given request payload
    When method post
    Then status 200
    * print 'CreateExchangeTeam Private League User Already Has Team Response:', response
    * match response.data.createExchangeTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName          | teamImage  | leagueId                          | expectedStatus | expectedMessage                         | expectedErrorCode   |
      | SecondTeamAttempt | icon_skull | existingPrivateExchangeLeagueId   | 409            | You already have a team in this league. | TEAM_ALREADY_EXISTS |