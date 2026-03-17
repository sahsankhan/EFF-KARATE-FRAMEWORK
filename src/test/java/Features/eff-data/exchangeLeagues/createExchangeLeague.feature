Feature: EFF Data - Create Private Exchange League API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def errorCodes = read('classpath:common/error-codes.json')
    * def createExchangeLeagueQuery = read('classpath:graphql/eff-data/exchangeLeagues/createExchangeLeague.graphql')
    * def getExchangeLeagueQuery = read('classpath:graphql/eff-data/exchangeLeagues/getExchangeLeague.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')
    * def buildLeagueData =
      """
      function(leagueName, leagueImage, existingAccessToken, privateExchangeLeagueName) {
        var nameValue = leagueName;
        var imageValue = leagueImage;
        if (nameValue === 'privateExchangeLeagueName') nameValue = privateExchangeLeagueName;
        if (nameValue === 'null') nameValue = null;
        if (imageValue === 'null') imageValue = null;
        if (nameValue === 'true') nameValue = true;
        if (nameValue === 'false') nameValue = false;
        if (!isNaN(nameValue) && nameValue !== '' && nameValue !== null) {
          nameValue = Number(nameValue);
        }
        
        // Handle whitespace and case transformations
        if (privateExchangeLeagueName) {
          if (nameValue === 'UPPER') nameValue = privateExchangeLeagueName.toUpperCase();
          if (nameValue === 'LOWER') nameValue = privateExchangeLeagueName.toLowerCase();
          if (nameValue === 'MIXED_SPACES') nameValue = '   ' + privateExchangeLeagueName.replace(/ /g, '    ') + '   ';
          if (nameValue === 'NO_SPACES') nameValue = privateExchangeLeagueName.replace(/ /g, '');
          if (nameValue === 'SPACED_LETTERS') nameValue = privateExchangeLeagueName.split('').join(' ');
        }
        
        return { authToken: existingAccessToken, variables: { League_Name: nameValue, League_Image: imageValue } };
      }
      """
    * def runSuffix = java.lang.System.currentTimeMillis() + ''
    * def privateExchangeLeagueName = 'Exch League' + runSuffix

  @missing_authorization_header
  Scenario Outline: CreateExchangeLeague fails when Authorization header is missing
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    # Do not set Authorization header
    * def payload = { query: '#(createExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateExchangeLeague Missing Token Response:', response
    * match response.data.createExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName     | leagueImage  | expectedStatus | expectedMessage         |  expectedErrorCode   |
      | Valid League   | icon_tiger   | 400            | Missing token in header |  MISSING_TOKEN       |

  @expired_token
  Scenario Outline: CreateExchangeLeague fails with expired token
    * def expiredToken = '<expiredToken>'
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = expiredToken
    * def payload = { query: '#(createExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateExchangeLeague Expired Token Response:', response
    * match response.data.createExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName     | leagueImage  | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage |  expectedErrorCode   |
      | Valid League   | icon_tiger   | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token   |  EXPIRED_TOKEN       |

  @invalid_token
  Scenario Outline: CreateExchangeLeague fails with invalid or corrupted token
    * def invalidToken = '<invalidToken>'
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = invalidToken
    * def payload = { query: '#(createExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateExchangeLeague Invalid Token Response:', response
    * match response.data.createExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName     | leagueImage  | invalidToken                      | expectedStatus | expectedMessage | expectedErrorCode   |
      | Valid League   | icon_tiger   | invalid.token.string              | 401            | Invalid token   | INVALID_TOKEN       |
      | Valid League   | icon_tiger   | random_corrupted_string_12345     | 401            | Invalid token   | INVALID_TOKEN       |
      | Valid League   | icon_tiger   | Bearer invalidtoken123            | 401            | Invalid token   | INVALID_TOKEN       |

  @invalid_league_image
  Scenario Outline: CreateExchangeLeague fails with invalid league image
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')

    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200    
    * print 'CreateExchangeLeague Response:', response
    * match response.data.createExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName    | leagueImage | expectedStatus | expectedMessage                                   | expectedErrorCode      |
      | Valid League  | 123         | 400            | Invalid league image. Must be a valid icon name   | INVALID_LEAGUE_IMAGE   |
      | Valid League  | abc         | 400            | Invalid league image. Must be a valid icon name   | INVALID_LEAGUE_IMAGE   |
      | Valid League  | ---         | 400            | Invalid league image. Must be a valid icon name   | INVALID_LEAGUE_IMAGE   |
      | Valid League  | icon        | 400            | Invalid league image. Must be a valid icon name   | INVALID_LEAGUE_IMAGE   |

  @happy_path_create_private_league
  Scenario Outline: CreateExchangeLeague succeeds with valid data and saves invite code 
    # PREREQUISITE CHECK: Ensure access token exists and season is preseason
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * call read('classpath:helpers/checkAndEnsurePreseason.feature')

    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken, privateExchangeLeagueName)
    * header Authorization = build.authToken
    * def payload = { query: '#(createExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateExchangeLeague Success Response:', response
    * match response.data.createExchangeLeague.statusCode == <expectedStatus>
    * match response.data.createExchangeLeague.message == '<expectedMessage>'
    * match response.data.createExchangeLeague.League_ID == '#present'
    * match response.data.createExchangeLeague.League_ID == '#notnull'
    
    # Save the created league ID
    * def privateExchangeLeagueId = response.data.createExchangeLeague.League_ID
    * karate.log('Created Private Exchange League ID:', privateExchangeLeagueId)
    
    * karate.pause(1000)
    
    # STEP 2: Fetch league details to get invite code
    * def leagueIdNumber = parseInt(privateExchangeLeagueId)
    * karate.log(leagueIdNumber)
    * def getLeagueVariables = ({ League_ID: leagueIdNumber })
    * def getLeaguePayload = ({ query: getExchangeLeagueQuery, variables: getLeagueVariables })
    
    # Reset headers for second request
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * header Authorization = existingAccessToken
    
    Given request getLeaguePayload
    When method post
    Then status 200
    * print 'GetExchangeLeague Response for created league:', response
    * match response.data.getExchangeLeague.statusCode == <expectedStatus>
    * match response.data.getExchangeLeague.leagues == '#array'
    * match response.data.getExchangeLeague.leagues[0] == '#present'
    
    # STEP 3: Validate and save invite code
    * def createdLeague = response.data.getExchangeLeague.leagues[0]
    * match createdLeague.Public == false
    * match createdLeague.Invite_Code == '#present'
    * match createdLeague.Invite_Code == '#notnull'
    
    # Save private league ID and invite code to info.txt
    * def privateExchangeLeagueInviteCode = createdLeague.Invite_Code
    * def initialPrivateExchangeLeagueMemberCount = createdLeague.Members

    * karate.log('Initial Private Exchange League Member Count:', initialPrivateExchangeLeagueMemberCount)

    * karate.write({email: signUpInfo.email, resetKey: signUpInfo.resetKey, password: signUpInfo.password, isVerified: signUpInfo.isVerified, passwordSet: signUpInfo.passwordSet, refreshToken: signUpInfo.refreshToken, accessToken: signUpInfo.accessToken, extremePublicBlitzLeagueId: signUpInfo.extremePublicBlitzLeagueId, extremePublicExchangeLeagueId: signUpInfo.extremePublicExchangeLeagueId, privateBlitzLeagueId: signUpInfo.privateBlitzLeagueId, privateBlitzLeagueName: signUpInfo.privateBlitzLeagueName, privateBlitzLeagueInviteCode: signUpInfo.privateBlitzLeagueInviteCode, initialPrivateBlitzLeagueMemberCount: signUpInfo.initialPrivateBlitzLeagueMemberCount, secondUser: signUpInfo.secondUser, privateExchangeLeagueId: privateExchangeLeagueId, privateExchangeLeagueName: privateExchangeLeagueName, privateExchangeLeagueInviteCode: privateExchangeLeagueInviteCode, initialPrivateExchangeLeagueMemberCount: initialPrivateExchangeLeagueMemberCount}, 'target/info.txt')
    * karate.log('Saved Private Exchange League ID:', privateExchangeLeagueId)
    * karate.log('Saved Private Exchange League Invite Code:', privateExchangeLeagueInviteCode)
    * karate.log('Saved Private Exchange League Initial Member Count:', initialPrivateExchangeLeagueMemberCount)

    Examples:
      | leagueName                  | leagueImage | expectedStatus | expectedMessage                           | 
      | privateExchangeLeagueName   | icon_tiger  | 200            | Exchange League created successfully      |

  @duplicate_league_name
  Scenario Outline: CreateExchangeLeague fails with duplicate league name
    # PREREQUISITE CHECK: Ensure access token and league name exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (signUpInfo.privateExchangeLeagueName == null) karate.fail('No created league name found. Run @happy_path_create_private_league scenario first')
    
    * def createdLeagueName = signUpInfo.privateExchangeLeagueName
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken, createdLeagueName)
    * header Authorization = build.authToken
    * def payload = { query: '#(createExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200    
    * print 'CreateExchangeLeague Response:', response
    * match response.data.createExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName                  | leagueImage | expectedStatus | expectedMessage                           | expectedErrorCode   |
      | privateExchangeLeagueName   | icon_tiger  | 409            | A league with this name already exists.   | LEAGUE_NAME_TAKEN   |

  @league_name_too_short
  Scenario Outline: CreateExchangeLeague fails when league name is less than 3 characters
    # PREREQUISITE CHECK: Ensure access token exists 
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')

    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateExchangeLeague Too Short Response:', response
    * match response.data.createExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName | leagueImage  | expectedStatus | expectedMessage                                | expectedErrorCode     |
      | A          | icon_tiger   | 400            | League name must be at least 3 characters      | LEAGUE_NAME_TOO_SHORT |
      | AB         | icon_tiger   | 400            | League name must be at least 3 characters      | LEAGUE_NAME_TOO_SHORT |
      | 1          | icon_tiger   | 400            | League name must be at least 3 characters      | LEAGUE_NAME_TOO_SHORT |
      | 12         | icon_tiger   | 400            | League name must be at least 3 characters      | LEAGUE_NAME_TOO_SHORT |

  @league_name_too_long
  Scenario Outline: CreateExchangeLeague fails when league name exceeds 50 characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')

    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateExchangeLeague Too Long Response:', response
    * match response.data.createExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName                                                 | leagueImage  | expectedStatus | expectedMessage                                                                                  | expectedErrorCode    |
      | This is a very long league name that exceeds fifty chars   | icon_tiger   | 400            | League name cannot exceed 50 characters                                                          | LEAGUE_NAME_TOO_LONG | 
      | !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!   | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot.   | INVALID_LEAGUE_NAME  |
      | --------------------------------------------------------   | icon_tiger   | 400            | League name cannot exceed 50 characters                                                          | LEAGUE_NAME_TOO_LONG | 

  @invalid_league_name_characters
  Scenario Outline: CreateExchangeLeague fails when league name contains invalid characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')

    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateExchangeLeague Invalid Characters Response:', response
    * match response.data.createExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName        | leagueImage  | expectedStatus | expectedMessage                                                                                | expectedErrorCode   |
      | League@Name       | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League#Name       | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League$Name       | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League%Name       | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League&Name       | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League*Name       | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League!Name       | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League(Name)      | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League[Name]      | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League{Name}      | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League/Name       | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League+Name       | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League=Name       | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League,Name       | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League;Name       | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League:Name       | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League"Name"      | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League<Name>      | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League?Name       | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League\\Name      | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League~Name       | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |
      | League`Name       | icon_tiger   | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. | INVALID_LEAGUE_NAME |

  @league_name_without_letters
  Scenario Outline: CreateExchangeLeague fails when league name contains no letters
    # PREREQUISITE CHECK: Ensure access token exists 
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')

    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(createExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateExchangeLeague No Letters Response:', response
    * match response.data.createExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName | leagueImage  | expectedStatus | expectedMessage                               | expectedErrorCode     |
      | 123        | icon_tiger   | 400            | League name must contain at least one letter. | LEAGUE_NAME_NO_LETTER |
      | ---        | icon_tiger   | 400            | League name must contain at least one letter. | LEAGUE_NAME_NO_LETTER |
      | 123-456    | icon_tiger   | 400            | League name must contain at least one letter. | LEAGUE_NAME_NO_LETTER |

  @whitespace_handling
  Scenario Outline: CreateExchangeLeague with various whitespace scenarios
    # PREREQUISITE CHECK: Ensure access token and league name exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (signUpInfo.privateExchangeLeagueName == null) karate.fail('No created league name found. Run @happy_path_create_private_league scenario first')
    
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken, signUpInfo.privateExchangeLeagueName)
    * header Authorization = build.authToken
    * def payload = { query: '#(createExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateExchangeLeague Response:', response
    * match response.data.createExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
     | leagueName       | leagueImage  | expectedStatus | expectedMessage                            | expectedErrorCode   |
     | UPPER            | icon_tiger   | 409            | A league with this name already exists.    | LEAGUE_NAME_TAKEN   |
     | MIXED_SPACES     | icon_tiger   | 409            | A league with this name already exists.    | LEAGUE_NAME_TAKEN   |
     | NO_SPACES        | icon_tiger   | 409            | A league with this name already exists.    | LEAGUE_NAME_TAKEN   |
     | SPACED_LETTERS   | icon_tiger   | 409            | A league with this name already exists.    | LEAGUE_NAME_TAKEN   |

  @case_sensitive_handling
  Scenario Outline: CreateExchangeLeague with case sensitivity scenarios
    # PREREQUISITE CHECK: Ensure access token and league name exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * if (signUpInfo.privateExchangeLeagueName == null) karate.fail('No created league name found. Run @happy_path_create_private_league scenario first')
    
    * def build = buildLeagueData('<leagueName>', '<leagueImage>', existingAccessToken, signUpInfo.privateExchangeLeagueName)
    * header Authorization = build.authToken
    * def payload = { query: '#(createExchangeLeagueQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CreateExchangeLeague Response:', response
    * match response.data.createExchangeLeague == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].errorInfo.errorCodeID == errorCodes[expectedErrorCode]
    * match response.errors[0].errorInfo.errorCode == '<expectedErrorCode>'
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
     | leagueName | leagueImage  | expectedStatus | expectedMessage                            | expectedErrorCode   |
     | LOWER      | icon_tiger   | 409            | A league with this name already exists.    | LEAGUE_NAME_TAKEN   |
     | UPPER      | icon_tiger   | 409            | A league with this name already exists.    | LEAGUE_NAME_TAKEN   |
