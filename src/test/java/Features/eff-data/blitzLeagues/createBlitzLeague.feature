
Feature: EFF Data - Create Private Blitz League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def createBlitzLeagueQuery = read('classpath:graphql/eff-data/blitzLeagues/createBlitzLeague.graphql')
    * def getBlitzLeagueQuery = read('classpath:graphql/eff-data/blitzLeagues/getBlitzLeague.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def buildLeagueData =
      """
      function(leagueName, leagueImage, existingAccessToken) {
        var nameValue = leagueName;
        var imageValue = leagueImage;
        if (nameValue === 'null') nameValue = null;
        if (imageValue === 'null') imageValue = null;
        if (nameValue === 'true') nameValue = true;
        if (nameValue === 'false') nameValue = false;
        if (!isNaN(nameValue) && nameValue !== '' && nameValue !== null) {
          nameValue = Number(nameValue);
        }
        return { authToken: existingAccessToken, variables: { League_Name: nameValue, League_Image: imageValue } };
      }
      """

  @missing_authorization_header
  Scenario Outline: CreateBlitzLeague fails when Authorization header is missing
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(createBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzLeague Missing Token Response:', response
    * match response.data.createBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName             | leagueImage | expectedStatus | expectedMessage         |  expectedErrorCode   |
      | Private Blitz League   | icon_bull   | 400            | Missing token in header |  MISSING_TOKEN       |

  @expired_token
  Scenario Outline: CreateBlitzLeague fails with expired token
    * def expiredToken = '<expiredToken>'
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = expiredToken
    * def payload = { query: '#(createBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzLeague Expired Token Response:', response
    * match response.data.createBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName             | leagueImage | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage |  expectedErrorCode   |
      | Private Blitz League   | icon_bull   | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   |  EXPIRED_TOKEN       |

  @invalid_token
  Scenario Outline: CreateBlitzLeague fails with invalid or corrupted token
    * def invalidToken = '<invalidToken>'
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = invalidToken
    * def payload = { query: '#(createBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzLeague Invalid Token Response:', response
    * match response.data.createBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName             | leagueImage | invalidToken                      | expectedStatus | expectedMessage | expectedErrorCode   |
      | Private Blitz League   | icon_bull   | invalid.token.string              | 401            | Invalid token   | INVALID_TOKEN       |
      | Private Blitz League   | icon_bull   | random_corrupted_string_12345     | 401            | Invalid token   | INVALID_TOKEN       |
      | Private Blitz League   | icon_bull   | Bearer invalidtoken123            | 401            | Invalid token   | INVALID_TOKEN       |
 
  @invalid_league_image
  Scenario Outline: CreateBlitzLeague fails with invalid league image
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    # STEP 1: Create first league with this name
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200    
    * print 'CreateBlitzLeague Response:', response
    * match response.data.createBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName                            | leagueImage | expectedStatus | expectedMessage                                   | expectedErrorCode      |
      | Private Blitz League for Automation   | 123         | 400            | Invalid league image. Must be a valid icon name   | INVALID_LEAGUE_IMAGE   |
      | Private Blitz League for Automation   | abc         | 400            | Invalid league image. Must be a valid icon name   | INVALID_LEAGUE_IMAGE   |
      | Private Blitz League for Automation   | ---         | 400            | Invalid league image. Must be a valid icon name   | INVALID_LEAGUE_IMAGE   |
      | Private Blitz League for Automation   | icon        | 400            | Invalid league image. Must be a valid icon name   | INVALID_LEAGUE_IMAGE   |
 
  @happy_path_create_private_league
  Scenario Outline: CreateBlitzLeague succeeds with valid data and saves invite code
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzLeague Success Response:', response
    * match response.data.createBlitzLeague.statusCode == <expectedStatus>
    * match response.data.createBlitzLeague.message == '<expectedMessage>'
    * match response.data.createBlitzLeague.League_ID == '#present'
    * match response.data.createBlitzLeague.League_ID == '#notnull'
    
    # Save the created league ID
    * def privateBlitzLeagueId = response.data.createBlitzLeague.League_ID
    * karate.log('Created Private Blitz League ID:', privateBlitzLeagueId)
    
    * karate.pause(1000)
    
    # STEP 2: Fetch league details to get invite code
    * def leagueIdNumber = parseInt(privateBlitzLeagueId)
    * karate.log(leagueIdNumber)
    * def getLeagueVariables = ({ League_ID: leagueIdNumber })
    * def getLeaguePayload = ({ query: getBlitzLeagueQuery, variables: getLeagueVariables })
    
    # Reset headers for second request
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * header Authorization = existingAccessToken
    
    Given request getLeaguePayload
    When method post
    Then status 200
    * print 'GetBlitzLeague Response for created league:', response
    * match response.data.getBlitzLeague.statusCode == <expectedStatus>
    * match response.data.getBlitzLeague.leagues == '#array'
    * match response.data.getBlitzLeague.leagues[0] == '#present'
    
    # STEP 3: Validate and save invite code
    * def createdLeague = response.data.getBlitzLeague.leagues[0]
    * match createdLeague.Public == false
    * match createdLeague.Invite_Code == '#present'
    * match createdLeague.Invite_Code == '#notnull'
    
    # Save private league ID and invite code to info.txt
    * def privateBlitzLeagueInviteCode = createdLeague.Invite_Code
    * karate.write({email: signUpInfo.email, resetKey: signUpInfo.resetKey, password: signUpInfo.password, isVerified: signUpInfo.isVerified, passwordSet: signUpInfo.passwordSet, refreshToken: signUpInfo.refreshToken, accessToken: signUpInfo.accessToken, extremeBlitzLeagueId: signUpInfo.extremeBlitzLeagueId, privateBlitzLeagueId: privateBlitzLeagueId, privateBlitzLeagueInviteCode: privateBlitzLeagueInviteCode}, 'target/info.txt')
    * karate.log('Saved Private League ID:', privateBlitzLeagueId)
    * karate.log('Saved Private League Invite Code:', privateBlitzLeagueInviteCode)

    Examples:
      | leagueName                           | leagueImage | expectedStatus | expectedMessage                       | 
      | Private Blitz League for Automation  | icon_bull   | 200            | Blitz League created successfully     |

  @duplicate_league_name
  Scenario Outline: CreateBlitzLeague fails with duplicate league name
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    # STEP 1: Create first league with this name
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200    
    * print 'CreateBlitzLeague Response:', response
    * match response.data.createBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName                            | leagueImage | expectedStatus | expectedMessage                           | expectedErrorCode   |
      | Private Blitz League for Automation   | icon_bull   | 409            | A league with this name already exists.   | LEAGUE_NAME_TAKEN   |

  @league_name_too_short
  Scenario Outline: CreateBlitzLeague fails when league name is less than 3 characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzLeague Too Short Response:', response
    * match response.data.createBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName | leagueImage  | expectedStatus | expectedMessage                                | expectedErrorCode     |
      | A          | icon_bull    | 400            | League name must be at least 3 characters      | LEAGUE_NAME_TOO_SHORT |
      | AB         | icon_bull    | 400            | League name must be at least 3 characters      | LEAGUE_NAME_TOO_SHORT |
      | 1          | icon_bull    | 400            | League name must be at least 3 characters      | LEAGUE_NAME_TOO_SHORT |
      | 12         | icon_bull    | 400            | League name must be at least 3 characters      | LEAGUE_NAME_TOO_SHORT |

  @league_name_too_long
  Scenario Outline: CreateBlitzLeague fails when league name exceeds 50 characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzLeague Too Long Response:', response
    * match response.data.createBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName                                                 | leagueImage  | expectedStatus | expectedMessage                                                                                  | expectedErrorCode    |
      | This is a very long league name that exceeds fifty chars   | icon_bull    | 400            | League name cannot exceed 50 characters                                                          | LEAGUE_NAME_TOO_LONG | 
      | !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!   | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot.   | INVALID_LEAGUE_NAME  |
      | --------------------------------------------------------   | icon_bull    | 400            | League name cannot exceed 50 characters                                                          | LEAGUE_NAME_TOO_LONG | 

  @invalid_league_name_characters
  Scenario Outline: CreateBlitzLeague fails when league name contains invalid characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzLeague Invalid Characters Response:', response
    * match response.data.createBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName        | leagueImage  | expectedStatus | expectedMessage                                                                                | expectedErrorCode   |
      | League@Name       | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League#Name       | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League$Name       | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League%Name       | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League&Name       | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League*Name       | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League!Name       | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League(Name)      | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League[Name]      | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League{Name}      | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League/Name       | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League+Name       | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League=Name       | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League,Name       | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League;Name       | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League:Name       | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League"Name"      | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League<Name>      | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League?Name       | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League\\Name      | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League~Name       | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League`Name       | icon_bull    | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |

  @league_name_without_letters
  Scenario Outline: CreateBlitzLeague fails when league name contains no letters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzLeague No Letters Response:', response
    * match response.data.createBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName | leagueImage  | expectedStatus | expectedMessage                               | expectedErrorCode     |
      | 123        | icon_bull    | 400            | League name must contain at least one letter. | LEAGUE_NAME_NO_LETTER |
      | ---        | icon_bull    | 400            | League name must contain at least one letter. | LEAGUE_NAME_NO_LETTER |
      | 123-456    | icon_bull    | 400            | League name must contain at least one letter. | LEAGUE_NAME_NO_LETTER |

  @whitespace_handling
  Scenario Outline: CreateBlitzLeague with various whitespace scenarios
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzLeague Whitespace Response:', response
    * match response.data.createBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
     | leagueName                                       | leagueImage  | expectedStatus | expectedMessage                            | expectedErrorCode   |
     | PRIVATE BLITZ LEAGUE FOR AUTOMATION              | icon_bull    | 409            | A league with this name already exists.    | LEAGUE_NAME_TAKEN   |
     | PRIVATE B L I T Z L E A G U E FOR AUTOMATION     | icon_bull    | 409            | A league with this name already exists.    | LEAGUE_NAME_TAKEN   |
     | PRIVATEBLITZLEAGUEFORAUTOMATION                  | icon_bull    | 409            | A league with this name already exists.    | LEAGUE_NAME_TAKEN   |
     |   pRIvAtEBLITZ LEaGuE    FOrAuToMAtIoN           | icon_bull    | 409            | A league with this name already exists.    | LEAGUE_NAME_TAKEN   |
     | PRIVATE   blitzleague    FORAUTOMATION           | icon_bull    | 409            | A league with this name already exists.    | LEAGUE_NAME_TAKEN   |
     | PRIVATEBlitzLeague     FOR     AUTOMATION        | icon_bull    | 409            | A league with this name already exists.    | LEAGUE_NAME_TAKEN   |

  @case_sensitive_handling
  Scenario Outline: CreateBlitzLeague with various whitespace scenarios
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createBlitzLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateBlitzLeague Whitespace Response:', response
    * match response.data.createBlitzLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
     | leagueName                            | leagueImage  | expectedStatus | expectedMessage                            | expectedErrorCode   |
     | private blitz league for automation   | icon_bull    | 409            | A league with this name already exists.    | LEAGUE_NAME_TAKEN   |
  