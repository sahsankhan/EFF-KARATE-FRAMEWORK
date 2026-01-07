Feature: EFF Data - Check Blitz League Name API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def checkBlitzLeagueNameQuery = read('classpath:resources/graphql/eff-data/blitzLeagues/checkBlitzLeagueName.graphql')
    * def createBlitzLeagueQuery = read('classpath:resources/graphql/eff-data/blitzLeagues/createBlitzLeague.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def buildLeagueNameData =
      """
      function(leagueName, existingAccessToken) {
        var nameValue = leagueName;
        if (nameValue === 'null') nameValue = null;
        if (nameValue === 'true') nameValue = true;
        if (nameValue === 'false') nameValue = false;
        if (!isNaN(nameValue) && nameValue !== '' && nameValue !== null) {
          nameValue = Number(nameValue);
        }
        return { authToken: existingAccessToken, variables: { League_Name: nameValue } };
      }
      """

  @missing_authorization_header
  Scenario Outline: CheckBlitzLeagueName fails when Authorization header is missing
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * def variables = { League_Name: build.League_Name }
    # Do not set Authorization header
    * def payload = { query: '#(checkBlitzLeagueNameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzLeagueName Missing Token Response:', response
    * match response.data.checkBlitzLeagueName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName     | expectedStatus | expectedMessage           |
      | Valid League   | 400            | Missing token in header   |

  @expired_token
  Scenario Outline: CheckBlitzLeagueName fails with expired token
    * def expiredToken = '<expiredToken>'
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * def variables = { League_Name: build.League_Name }
    * header Authorization = expiredToken
    * def payload = { query: '#(checkBlitzLeagueNameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzLeagueName Expired Token Response:', response
    * match response.data.checkBlitzLeagueName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName     | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage   |
      | Valid League   | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired token     |

  @invalid_token
  Scenario Outline: CheckBlitzLeagueName fails with invalid or corrupted token
    * def invalidToken = '<invalidToken>'
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * def variables = { League_Name: build.League_Name }
    * header Authorization = invalidToken
    * def payload = { query: '#(checkBlitzLeagueNameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzLeagueName Invalid Token Response:', response
    * match response.data.checkBlitzLeagueName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName     | invalidToken                              | expectedStatus | expectedMessage   |
      | Valid League   | invalid.token.string                      | 401            | Invalid token     |
      | Valid League   | random_corrupted_string_12345             | 401            | Invalid token     |
      | Valid League   | Bearer invalidtoken123                    | 401            | Invalid token     |

  @happy_path_available
  Scenario Outline: CheckBlitzLeagueName succeeds when league name is available
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzLeagueNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzLeagueName Available Response:', response
    * match response.data.checkBlitzLeagueName.statusCode == <expectedStatus>
    * match response.data.checkBlitzLeagueName.message == '<expectedMessage>'
    * match response.data.checkBlitzLeagueName.valid == <expectedValid>

    Examples:
      | leagueName                    | expectedStatus | expectedMessage              | expectedValid |
      | Available League Name         | 200            | League name is available.    | true          |
      | The Champions League 2025     | 200            | League name is available.    | true          | 

  @league_name_taken
  Scenario Outline: CheckBlitzLeagueName fails when league name is already taken
    # PREREQUISITE
    * if (!existingAccessToken) karate.fail('No access token found. Run login.feature first')

    # STEP 1: Check availability
    * def checkBuild = buildLeagueNameData('<leagueName>', existingAccessToken)
    * header Authorization = checkBuild.authToken
    * def checkPayload = { query: '#(checkBlitzLeagueNameQuery)', variables: '#(checkBuild.variables)' }
  
    Given request checkPayload
    When method post
    Then status 200
    * print 'Availability response:', response

    # Safely read node (prevents "Cannot read property valid from null")
    * def checkNode = karate.get('response.data.checkBlitzLeagueName')
    * def isAvailable = checkNode != null && checkNode.valid == true

    * eval
    """
    if (!isAvailable) {
      karate.match(karate.get('response.data.checkBlitzLeagueName'), null);
      karate.match(karate.get('response.errors[0].errorInfo.statusCode'), expectedStatus);
      karate.match(karate.get('response.errors[0].message'), expectedMessage);
      karate.abort();
    }
    """

    # PATH 2: AVAILABLE → CREATE
    * header Authorization = checkBuild.authToken
    * def createPayload = { query: '#(createBlitzLeagueQuery)', variables: { League_Name: '<leagueName>', League_Image: null }}
    
    Given request createPayload
    When method post
    Then status 200

    * karate.pause(500)

    # STEP 3: Re-check → must now be taken
    * def recheckBuild = buildLeagueNameData('<leagueName>', existingAccessToken)
    * header Authorization = recheckBuild.authToken
    * def recheckPayload = { query: '#(checkBlitzLeagueNameQuery)', variables: '#(recheckBuild.variables)' }

    Given request recheckPayload
    When method post
    Then status 200
    * print 'Taken response:', response

    * match response.data.checkBlitzLeagueName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | leagueName        | expectedStatus | expectedMessage               |
      | EFF Blitz League  | 409            | League name is already taken. |

  @league_name_too_short
  Scenario Outline: CheckBlitzLeagueName fails when league name is less than 3 characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzLeagueNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzLeagueName Too Short Response:', response
    * match response.data.checkBlitzLeagueName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName | expectedStatus | expectedMessage                                |
      | A          | 400            | League name must be at least 3 characters      |
      | AB         | 400            | League name must be at least 3 characters      |
      | 1          | 400            | League name must be at least 3 characters      |
      | 12         | 400            | League name must be at least 3 characters      |

  @league_name_too_long
  Scenario Outline: CheckBlitzLeagueName fails when league name exceeds 50 characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzLeagueNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzLeagueName Too Long Response:', response
    * match response.data.checkBlitzLeagueName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName                                                 | expectedStatus | expectedMessage                           |
      | This is a very long league name that exceeds fifty chars   | 400            | League name cannot exceed 50 characters   |

  @invalid_league_name_characters
  Scenario Outline: CheckBlitzLeagueName fails when league name contains invalid characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzLeagueNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzLeagueName Invalid Characters Response:', response
    * match response.data.checkBlitzLeagueName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | leagueName        | expectedStatus | expectedMessage                                                                              |
      | League@Name       | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League#Name       | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League$Name       | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League%Name       | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League&Name       | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League*Name       | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League!Name       | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League(Name)      | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League[Name]      | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League{Name}      | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League/Name       | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League+Name       | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League=Name       | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League,Name       | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League;Name       | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League:Name       | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League"Name"      | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League<Name>      | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League?Name       | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League\\Name      | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League~Name       | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |
      | League`Name       | 400            | League name can only contain letters, numbers, spaces, hyphen, underscore, apostrophe and dot. |

  @league_name_without_letters
  Scenario Outline: CheckBlitzLeagueName fails when league name contains no letters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzLeagueNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzLeagueName No Letters Response:', response
    * match response.data.checkBlitzLeagueName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName | expectedStatus | expectedMessage                               |
      | 123        | 400            | League name must contain at least one letter. |
      | ---        | 400            | League name must contain at least one letter. |
      | 123-456    | 400            | League name must contain at least one letter. |

  @whitespace_handling
  Scenario Outline: CheckBlitzLeagueName with various whitespace scenarios
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzLeagueNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzLeagueName Whitespace Response:', response
    * match response.data.checkBlitzLeagueName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
     | leagueName                  | expectedStatus | expectedMessage                  | 
     | EFF    Blitz     League     | 409            | League name is already taken.    |
     | E F F B l I T Z L E A G U E | 409            | League name is already taken.    |
     | EFFBlitzLeague              | 409            | League name is already taken.    |
     | E f F B l i T z L e a G u E | 409            | League name is already taken.    |
     | EFFBlitz    League          | 409            | League name is already taken.    |
     | EFF      BlitzLeague        | 409            | League name is already taken.    |

  @case_sensitive_handling
  Scenario Outline: CheckBlitzLeagueName with various whitespace scenarios
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkBlitzLeagueNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckBlitzLeagueName Whitespace Response:', response
    * match response.data.checkBlitzLeagueName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
     | leagueName         | expectedStatus | expectedMessage                  |
     | eff blitz league   | 409            | League name is already taken.    |
  