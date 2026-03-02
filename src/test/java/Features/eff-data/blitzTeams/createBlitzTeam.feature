Feature: EFF Data - Create Blitz Team API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:/common/error-codes.json')
    * def createBlitzTeamQuery = read('classpath:/graphql/eff-data/blitzTeams/createBlitzTeam.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def extremePublicBlitzLeagueId = karate.get('signUpInfo.extremePublicBlitzLeagueId', null)
    * def buildTeamData =
      """
      function(teamName, teamImage, leagueId, existingAccessToken, privateBlitzTeamName) {
        var nameValue = teamName;
        var imageValue = teamImage;
        var idValue = leagueId;
        if (nameValue === 'privateBlitzTeamName') nameValue = privateBlitzTeamName;
        if (nameValue === 'null') nameValue = null;
        if (nameValue === 'true') nameValue = true;
        if (nameValue === 'false') nameValue = false;
        if (imageValue === 'null') imageValue = null;
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPublicBlitzLeagueId') idValue = extremePublicBlitzLeagueId;
        
        // Convert numeric strings to numbers
        if (!isNaN(nameValue) && nameValue !== '' && nameValue !== null) {
          nameValue = Number(nameValue);
        }
        if (!isNaN(idValue) && idValue !== '' && idValue !== null) {
          idValue = Number(idValue);
        }
        
        // Handle whitespace and case transformations
        if (privateBlitzTeamName) {
          if (nameValue === 'UPPER') nameValue = privateBlitzTeamName.toUpperCase();
          if (nameValue === 'LOWER') nameValue = privateBlitzTeamName.toLowerCase();
          if (nameValue === 'MIXED_SPACES') nameValue = '   ' + privateBlitzTeamName.replace(/ /g, '    ') + '   ';
          if (nameValue === 'NO_SPACES') nameValue = privateBlitzTeamName.replace(/ /g, '');
          if (nameValue === 'SPACED_LETTERS') nameValue = privateBlitzTeamName.split('').join(' ');
        }
        
        var variables = { Team_Name: nameValue, League_ID: idValue };
        
        // Only include Team_Image if it's defined
        if (imageValue !== undefined) {
          variables.Team_Image = imageValue;
        }
        
        return { authToken: existingAccessToken, variables: variables };
      }
      """
    * def runSuffix = java.lang.System.currentTimeMillis() + ''
    * def privateBlitzTeamName = 'Blitz Team' + runSuffix

  @missing_authorization_header
  Scenario Outline: CreateBlitzTeam fails when Authorization header is missing
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (extremePublicBlitzLeagueId == null) karate.abort()
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Missing Token Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:  
      | teamName     | teamImage     | leagueId                      | expectedStatus | expectedMessage         | expectedErrorCode   |
      | Valid Team   | icon_tiger    | existingPublicBlitzLeagueId   | 400            | Missing token in header | MISSING_TOKEN       |

  @expired_token
  Scenario Outline: CreateBlitzTeam fails with expired token
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (extremePublicBlitzLeagueId == null) karate.abort()

    * def expiredToken = '<expiredToken>'
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken)
    * header Authorization = expiredToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Expired Token Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName     | teamImage     | leagueId                     | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage | expectedErrorCode   |
      | Valid Team   | icon_tiger    | existingPublicBlitzLeagueId  | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   | EXPIRED_TOKEN       |

  @invalid_token
  Scenario Outline: CreateBlitzTeam fails with invalid or corrupted token
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (extremePublicBlitzLeagueId == null) karate.abort()

    * def invalidToken = '<invalidToken>'
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken)
    * header Authorization = invalidToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Invalid Token Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName      | teamImage     | leagueId                      | invalidToken                      | expectedStatus | expectedMessage | expectedErrorCode   |
      | Valid Team    | icon_tiger    | existingPublicBlitzLeagueId   | Bearer invalidtoken123            | 401            | Invalid token   | INVALID_TOKEN       | 
      | Valid Team    | icon_tiger    | existingPublicBlitzLeagueId   | privateBlitzTeamName_corrupted_string_12345     | 401            | Invalid token   | INVALID_TOKEN       | 
      | Valid Team    | icon_tiger    | existingPublicBlitzLeagueId   | invalid.token.string              | 401            | Invalid token   | INVALID_TOKEN       | 

  @invalid_team_image
  Scenario Outline: CreateBlitzTeam fails with invalid image provided
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremePublicBlitzLeagueId == null) karate.abort()

    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken, privateBlitzTeamName)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Invalid Token Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName       | teamImage  | leagueId                      | expectedStatus | expectedMessage                                 | expectedErrorCode  |
      | Valid Team     | abc        | existingPublicBlitzLeagueId   | 400            | Invalid team image. Must be a valid icon name   | INVALID_TEAM_IMAGE |
      | Valid Team     | ---        | existingPublicBlitzLeagueId   | 400            | Invalid team image. Must be a valid icon name   | INVALID_TEAM_IMAGE |
      | Valid Team     | 123        | existingPublicBlitzLeagueId   | 400            | Invalid team image. Must be a valid icon name   | INVALID_TEAM_IMAGE |
      | Valid Team     | icon       | existingPublicBlitzLeagueId   | 400            | Invalid team image. Must be a valid icon name   | INVALID_TEAM_IMAGE |

  @happy_path
  Scenario Outline: CreateBlitzTeam succeeds with valid data and saves Team_ID
    # PREREQUISITE CHECK: Ensure access token and league ID exist and season is preseason
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')
    * if (extremePublicBlitzLeagueId == null) karate.abort()
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken, privateBlitzTeamName)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Success Response:', response
    * match response.data.createBlitzTeam.statusCode == <expectedStatus>
    * match response.data.createBlitzTeam.message == '<expectedMessage>'
    * match response.data.createBlitzTeam.Team_ID == '#present'
    * match response.data.createBlitzTeam.Team_ID == '#notnull'
    
    # Save Team_ID and Team_Name to info file for subsequent tests
    * def privateBlitzTeamId = response.data.createBlitzTeam.Team_ID
    * karate.write({email: signUpInfo.email, resetKey: signUpInfo.resetKey, password: signUpInfo.password, isVerified: signUpInfo.isVerified, passwordSet: signUpInfo.passwordSet, refreshToken: signUpInfo.refreshToken, accessToken: signUpInfo.accessToken, extremePublicBlitzLeagueId: signUpInfo.extremePublicBlitzLeagueId, privateBlitzLeagueId: signUpInfo.privateBlitzLeagueId, privateBlitzTeamId: privateBlitzTeamId, privateBlitzTeamName: privateBlitzTeamName }, 'target/info.txt')

    Examples:
      | teamName             | teamImage     | leagueId                      | expectedStatus | expectedMessage                       |
      | privateBlitzTeamName | icon_tiger    | existingPublicBlitzLeagueId   | 200            | Blitz Team created successfully       |

  @user_already_has_team
  Scenario Outline: CreateBlitzTeam fails when user already has a team in the league
    # PREREQUISITE CHECK: Ensure access token, league ID, and team ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremePublicBlitzLeagueId == null) karate.abort()
    * def existingTeamId = karate.get('signUpInfo.privateBlitzTeamId', null)
    * if (existingTeamId == null) karate.abort()
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken, privateBlitzTeamName)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam User Already Has Team Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName              | teamImage      | leagueId                      | expectedStatus | expectedMessage                           | expectedErrorCode   |
      | SecondTeamAttempt     | icon_skull     | existingPublicBlitzLeagueId   | 409            | You already have a team in this league.   | TEAM_ALREADY_EXISTS |

  @league_not_found
  Scenario Outline: CreateBlitzTeam fails with non-existent league ID
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam League Not Found Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName     | teamImage    | leagueId | expectedStatus | expectedMessage                | expectedErrorCode   |
      |  Valid Team  | icon_reaper  | 999999   | 404            | League not found or deleted.   | LEAGUE_NOT_FOUND    |
      |  Valid Team  | icon_reaper  | 100000   | 404            | League not found or deleted.   | LEAGUE_NOT_FOUND    |

  @invalid_league_id
  Scenario Outline: CreateBlitzTeam fails with invalid league ID format
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Invalid League ID Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName      | teamImage    | leagueId   | expectedStatus | expectedMessage                  | expectedErrorCode   |
      | Valid Team    | icon_reaper  | invalid    | 400            | League_ID must be a numeric ID   | INVALID_LEAGUE_ID   | 
      | Valid Team    | icon_reaper  | abc123     | 400            | League_ID must be a numeric ID   | INVALID_LEAGUE_ID   |
      | Valid Team    | icon_reaper  | league_id  | 400            | League_ID must be a numeric ID   | INVALID_LEAGUE_ID   |
      | Valid Team    | icon_reaper  | -999999    | 400            | Invalid League_ID format         | INVALID_LEAGUE_ID   |
      | Valid Team    | icon_reaper  | -100000    | 400            | Invalid League_ID format         | INVALID_LEAGUE_ID   |

  @team_name_too_short
  Scenario Outline: CreateBlitzTeam fails when team name is less than 3 characters
    # PREREQUISITE CHECK: Ensure access token and league ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremePublicBlitzLeagueId == null) karate.abort()
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Team Name Too Short Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName | teamImage      | leagueId                      | expectedStatus | expectedMessage                              | expectedErrorCode   |
      | A        | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name cannot be less than 3 characters.  | TEAM_NAME_TOO_SHORT | 
      | AB       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name cannot be less than 3 characters.  | TEAM_NAME_TOO_SHORT | 
      | 1        | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name cannot be less than 3 characters.  | TEAM_NAME_TOO_SHORT | 
      | 12       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name cannot be less than 3 characters.  | TEAM_NAME_TOO_SHORT | 

  @team_name_too_long
  Scenario Outline: CreateBlitzTeam fails when team name exceeds 50 characters
    # PREREQUISITE CHECK: Ensure access token and league ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremePublicBlitzLeagueId == null) karate.abort()
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Team Name Too Long Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName                                               | teamImage      | leagueId                      | expectedStatus | expectedMessage                                                                              | expectedErrorCode   |
      | This is a very long team name that exceeds fifty chars | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name cannot be more than 50 characters.                                                 | TEAM_NAME_TOO_LONG  | 
      | ------------------------------------------------------ | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name cannot be more than 50 characters.                                                 | TEAM_NAME_TOO_LONG  | 
      | !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  | INVALID_TEAM_NAME   |   

  @invalid_team_name_characters
  Scenario Outline: CreateBlitzTeam fails when team name contains invalid characters
    # PREREQUISITE CHECK: Ensure access token and league ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremePublicBlitzLeagueId == null) karate.abort()
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Invalid Team Name Characters Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName        | teamImage      | leagueId                      | expectedStatus | expectedMessage                                                                              | expectedErrorCode   |
      | Team@Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  | INVALID_TEAM_NAME   |
      | Team#Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  | INVALID_TEAM_NAME   |
      | Team$Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  | INVALID_TEAM_NAME   |
      | Team%Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  | INVALID_TEAM_NAME   |
      | Team&Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  | INVALID_TEAM_NAME   |
      | Team*Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  | INVALID_TEAM_NAME   |
      | Team!Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  | INVALID_TEAM_NAME   |
      | Team/Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  | INVALID_TEAM_NAME   |
      | Team?Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  | INVALID_TEAM_NAME   |
      | Team\\Name      | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  | INVALID_TEAM_NAME   |
      | Team=Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  | INVALID_TEAM_NAME   |
      | Team+Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  | INVALID_TEAM_NAME   |
      | Team;Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  | INVALID_TEAM_NAME   |

  @team_name_without_letters
  Scenario Outline: CreateBlitzTeam fails when team name contains no letters
    # PREREQUISITE CHECK: Ensure access token and league ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremePublicBlitzLeagueId == null) karate.abort()
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken, privateBlitzTeamName)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Team Name Without Letters Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName | teamImage      | leagueId                      | expectedStatus | expectedMessage                             | expectedErrorCode   |
      | 123      | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name must contain at least one letter  | TEAM_NAME_NO_LETTER |
      | ---      | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name must contain at least one letter  | TEAM_NAME_NO_LETTER |
      | 123-456  | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name must contain at least one letter  | TEAM_NAME_NO_LETTER |

  @whitespace_handling
  Scenario Outline: CreateBlitzTeam with various whitespace scenarios
    # PREREQUISITE CHECK: Ensure access token, league ID, and team name exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (signUpInfo.privateBlitzTeamName == null) karate.fail('No created team name found. Run @happy_path scenario first')
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken, signUpInfo.privateBlitzTeamName)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
     | teamName       | teamImage     | leagueId                      | expectedStatus | expectedMessage                           | expectedErrorCode   |
     | UPPER          | icon_tiger    | existingPublicBlitzLeagueId   | 409            | You already have a team in this league.   | TEAM_ALREADY_EXISTS |
     | MIXED_SPACES   | icon_tiger    | existingPublicBlitzLeagueId   | 409            | You already have a team in this league.   | TEAM_ALREADY_EXISTS |
     | NO_SPACES      | icon_tiger    | existingPublicBlitzLeagueId   | 409            | You already have a team in this league.   | TEAM_ALREADY_EXISTS |
     | SPACED_LETTERS | icon_tiger    | existingPublicBlitzLeagueId   | 409            | You already have a team in this league.   | TEAM_ALREADY_EXISTS |

  @case_sensitive_handling
  Scenario Outline: CreateBlitzTeam with case sensitivity scenarios
    # PREREQUISITE CHECK: Ensure access token, league ID, and team name exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (signUpInfo.privateBlitzTeamName == null) karate.fail('No created team name found. Run @happy_path scenario first')
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken, signUpInfo.privateBlitzTeamName)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
     | teamName | teamImage     | leagueId                      | expectedStatus | expectedMessage                           | expectedErrorCode   |
     | LOWER    | icon_tiger    | existingPublicBlitzLeagueId   | 409            | You already have a team in this league.   | TEAM_ALREADY_EXISTS |
     | UPPER    | icon_tiger    | existingPublicBlitzLeagueId   | 409            | You already have a team in this league.   | TEAM_ALREADY_EXISTS |
