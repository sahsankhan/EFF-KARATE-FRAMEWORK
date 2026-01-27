Feature: EFF Data - Create Blitz Team API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def createBlitzTeamQuery = read('classpath:resources/graphql/eff-data/blitzTeams/createBlitzTeam.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def extremeBlitzLeagueId = karate.get('signUpInfo.extremeBlitzLeagueId', null)
    * def buildTeamData =
      """
      function(teamName, teamImage, leagueId, existingAccessToken) {
        var nameValue = teamName;
        var imageValue = teamImage;
        var idValue = leagueId;
        
        // Handle special keywords for dynamic values
        if (nameValue === 'null') nameValue = null;
        if (nameValue === 'true') nameValue = true;
        if (nameValue === 'false') nameValue = false;
        if (imageValue === 'null') imageValue = null;
        if (idValue === 'null') idValue = null;
        if (idValue === 'existingPublicBlitzLeagueId') idValue = extremeBlitzLeagueId;
        
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
        
        return { authToken: existingAccessToken, variables: variables };
      }
      """

  @missing_authorization_header
  Scenario Outline: CreateBlitzTeam fails when Authorization header is missing
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (extremeBlitzLeagueId == null) karate.abort()
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Missing Token Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:  
      | teamName                                      | teamImage     | leagueId                      | expectedStatus | expectedMessage         |
      | Personal Blitz Team for Testing Automation    | icon_tiger    | existingPublicBlitzLeagueId   | 400            | Missing token in header |

  @expired_token
  Scenario Outline: CreateBlitzTeam fails with expired token
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (extremeBlitzLeagueId == null) karate.abort()

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
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | teamName                                      | teamImage     | leagueId                     | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage |
      | Personal Blitz Team for Testing Automation    | icon_tiger    | existingPublicBlitzLeagueId  | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   |

  @invalid_token
  Scenario Outline: CreateBlitzTeam fails with invalid or corrupted token
    # PREREQUISITE CHECK: Ensure league ID exists
    * if (extremeBlitzLeagueId == null) karate.abort()

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
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | teamName                                      | teamImage     | leagueId                      | invalidToken                      | expectedStatus | expectedMessage |
      | Personal Blitz Team for Testing Automation    | icon_tiger    | existingPublicBlitzLeagueId   | Bearer invalidtoken123            | 401            | Invalid token   |
      | Personal Blitz Team for Testing Automation    | icon_tiger    | existingPublicBlitzLeagueId   | random_corrupted_string_12345     | 401            | Invalid token   |
      | Personal Blitz Team for Testing Automation    | icon_tiger    | existingPublicBlitzLeagueId   | invalid.token.string              | 401            | Invalid token   |

  @happy_path
  Scenario Outline: CreateBlitzTeam succeeds with valid data and saves Team_ID
    # PREREQUISITE CHECK: Ensure access token and league ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremeBlitzLeagueId == null) karate.abort()
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken)
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
    
    # Save Team_ID to info file for subsequent tests
    * def createdTeamId = response.data.createBlitzTeam.Team_ID
    * karate.write({email: signUpInfo.email, resetKey: signUpInfo.resetKey, password: signUpInfo.password, isVerified: signUpInfo.isVerified, passwordSet: signUpInfo.passwordSet, refreshToken: signUpInfo.refreshToken, accessToken: signUpInfo.accessToken, extremeBlitzLeagueId: signUpInfo.extremeBlitzLeagueId, privateBlitzLeagueId: signUpInfo.privateBlitzLeagueId, privateBlitzTeamId: createdTeamId }, 'target/info.txt')

    Examples:
      | teamName                                      | teamImage     | leagueId                      | expectedStatus | expectedMessage                       |
      | Personal Blitz Team for Testing Automation    | icon_tiger    | existingPublicBlitzLeagueId   | 200            | Blitz Team created successfully       |

  @user_already_has_team
  Scenario Outline: CreateBlitzTeam fails when user already has a team in the league
    # PREREQUISITE CHECK: Ensure access token, league ID, and team ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremeBlitzLeagueId == null) karate.abort()
    * def existingTeamId = karate.get('signUpInfo.blitzTeamId', null)
    * if (existingTeamId == null) karate.abort()
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam User Already Has Team Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName              | teamImage      | leagueId                      | expectedStatus | expectedMessage                           |
      | SecondTeamAttempt     | icon_skull     | existingPublicBlitzLeagueId   | 409            | You already have a team in this league.   |

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
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName                                     | teamImage    | leagueId | expectedStatus | expectedMessage                |
      |  Personal Blitz Team for Testing Automation  | icon_reaper  | 999999   | 404            | League not found or deleted.   |
      |  Personal Blitz Team for Testing Automation  | icon_reaper  | 100000   | 404            | League not found or deleted.   |

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
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName                                    | teamImage    | leagueId   | expectedStatus | expectedMessage                  |
      | Personal Blitz Team for Testing Automation  | icon_reaper  | invalid    | 400            | League_ID must be a numeric ID   |
      | Personal Blitz Team for Testing Automation  | icon_reaper  | abc123     | 400            | League_ID must be a numeric ID   |
      | Personal Blitz Team for Testing Automation  | icon_reaper  | league_id  | 400            | League_ID must be a numeric ID   |
      | Personal Blitz Team for Testing Automation  | icon_reaper  | -999999    | 400            | Invalid League_ID format         |
      | Personal Blitz Team for Testing Automation  | icon_reaper  | -100000    | 400            | Invalid League_ID format         |

  @team_name_too_short
  Scenario Outline: CreateBlitzTeam fails when team name is less than 3 characters
    # PREREQUISITE CHECK: Ensure access token and league ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremeBlitzLeagueId == null) karate.abort()
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Team Name Too Short Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName | teamImage      | leagueId                      | expectedStatus | expectedMessage                              |
      | A        | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name cannot be less than 3 characters.  |
      | AB       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name cannot be less than 3 characters.  |
      | 1        | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name cannot be less than 3 characters.  |
      | 12       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name cannot be less than 3 characters.  |

  @team_name_too_long
  Scenario Outline: CreateBlitzTeam fails when team name exceeds 50 characters
    # PREREQUISITE CHECK: Ensure access token and league ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremeBlitzLeagueId == null) karate.abort()
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Team Name Too Long Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName                                               | teamImage      | leagueId                      | expectedStatus | expectedMessage                                                                              |
      | This is a very long team name that exceeds fifty chars | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name cannot be more than 50 characters.                                                 |
      | ------------------------------------------------------ | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name cannot be more than 50 characters.                                                 |
      | !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  |

  @invalid_team_name_characters
  Scenario Outline: CreateBlitzTeam fails when team name contains invalid characters
    # PREREQUISITE CHECK: Ensure access token and league ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremeBlitzLeagueId == null) karate.abort()
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Invalid Team Name Characters Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName        | teamImage      | leagueId                      | expectedStatus | expectedMessage                                                                              |
      | Team@Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  |
      | Team#Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  |
      | Team$Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  |
      | Team%Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  |
      | Team&Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  |
      | Team*Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  |
      | Team!Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  |
      | Team/Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  |
      | Team?Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  |
      | Team\\Name      | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  |
      | Team=Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  |
      | Team+Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  |
      | Team;Name       | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot  |

  @team_name_without_letters
  Scenario Outline: CreateBlitzTeam fails when team name contains no letters
    # PREREQUISITE CHECK: Ensure access token and league ID exist
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (extremeBlitzLeagueId == null) karate.abort()
    
    * def build = buildTeamData('<teamName>', '<teamImage>', '<leagueId>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzTeamQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzTeam Team Name Without Letters Response:', response
    * match response.data.createBlitzTeam == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | teamName | teamImage      | leagueId                      | expectedStatus | expectedMessage                             |
      | 123      | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name must contain at least one letter  |
      | ---      | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name must contain at least one letter  |
      | 123-456  | icon_reaper    | existingPublicBlitzLeagueId   | 400            | Team name must contain at least one letter  |
