Feature: EFF Data - Check Exchange League Name API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def checkExchangeLeagueNameQuery = read('classpath:resources/graphql/eff-data/exchangeLeagues/checkExchangeLeagueName.graphql')
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
  Scenario Outline: CheckExchangeLeagueName fails when Authorization header is missing
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * def variables = { League_Name: build.League_Name }
    # Do not set Authorization header
    * def payload = { query: '#(checkExchangeLeagueNameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeLeagueName Missing Token Response:', response
    * match response.data.checkExchangeLeagueName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName     | expectedStatus | expectedMessage           |
      | Valid League   | 400            | Missing token in header   |

  @expired_token
  Scenario Outline: CheckExchangeLeagueName fails with expired token
    * def expiredToken = '<expiredToken>'
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * def variables = { League_Name: build.League_Name }
    * header Authorization = expiredToken
    * def payload = { query: '#(checkExchangeLeagueNameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeLeagueName Expired Token Response:', response
    * match response.data.checkExchangeLeagueName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName     | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage |
      | Valid League   | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | Expired         |

  @invalid_token
  Scenario Outline: CheckExchangeLeagueName fails with invalid or corrupted token
    * def invalidToken = '<invalidToken>'
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * def variables = { League_Name: build.League_Name }
    * header Authorization = invalidToken
    * def payload = { query: '#(checkExchangeLeagueNameQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeLeagueName Invalid Token Response:', response
    * match response.data.checkExchangeLeagueName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName     | invalidToken                              | expectedStatus | expectedMessage   |
      | Valid League   | invalid.token.string                      | 401            | Invalid           |
      | Valid League   | random_corrupted_string_12345             | 401            | Invalid           |
      | Valid League   | Bearer invalidtoken123                    | 401            | Invalid           |

  @happy_path_available
  Scenario Outline: CheckExchangeLeagueName succeeds when league name is available
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkExchangeLeagueNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeLeagueName Available Response:', response
    * match response.data.checkExchangeLeagueName.statusCode == <expectedStatus>
    * match response.data.checkExchangeLeagueName.message == '<expectedMessage>'
    * match response.data.checkExchangeLeagueName.valid == <expectedValid>

    Examples:
      | leagueName                    | expectedStatus | expectedMessage              | expectedValid |
      | Available League Name         | 200            | League name is available.    | true          |
      | The Champions League 2025     | 200            | League name is available.    | true          | 

  @league_name_taken
  Scenario Outline: CheckExchangeLeagueName fails when league name is already taken
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkExchangeLeagueNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeLeagueName Taken Response:', response
    * match response.data.checkExchangeLeagueName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message == '<expectedMessage>'

    Examples:
      | leagueName           | expectedStatus | expectedMessage               |
      | EFF Exchange League  | 409            | League name is already taken. |

  @league_name_too_short
  Scenario Outline: CheckExchangeLeagueName fails when league name is less than 3 characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkExchangeLeagueNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeLeagueName Too Short Response:', response
    * match response.data.checkExchangeLeagueName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName | expectedStatus | expectedMessage                                |
      | A          | 400            | League name must be at least 3 characters      |
      | AB         | 400            | League name must be at least 3 characters      |
      | 1          | 400            | League name must be at least 3 characters      |
      | 12         | 400            | League name must be at least 3 characters      |

  @league_name_too_long
  Scenario Outline: CheckExchangeLeagueName fails when league name exceeds 50 characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkExchangeLeagueNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeLeagueName Too Long Response:', response
    * match response.data.checkExchangeLeagueName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName                                                 | expectedStatus | expectedMessage                           |
      | This is a very long league name that exceeds fifty chars   | 400            | League name cannot exceed 50 characters   |

  @invalid_league_name_characters
  Scenario Outline: CheckExchangeLeagueName fails when league name contains invalid characters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkExchangeLeagueNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeLeagueName Invalid Characters Response:', response
    * match response.data.checkExchangeLeagueName == null
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
  Scenario Outline: CheckExchangeLeagueName fails when league name contains no letters
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkExchangeLeagueNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeLeagueName No Letters Response:', response
    * match response.data.checkExchangeLeagueName == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | leagueName | expectedStatus | expectedMessage                               |
      | 123        | 400            | League name must contain at least one letter. |
      | ---        | 400            | League name must contain at least one letter. |
      | 123-456    | 400            | League name must contain at least one letter. |

  @whitespace_handling
  Scenario Outline: CheckExchangeLeagueName with various whitespace scenarios
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkExchangeLeagueNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeLeagueName Whitespace Response:', response
    * match response.data.checkExchangeLeagueName == null
    * match response.data.checkExchangeLeagueName.statusCode == <expectedStatus>
    * match response.data.checkExchangeLeagueName.message == '<expectedMessage>'

    Examples:
     | leagueName                        | expectedStatus | expectedMessage                  | 
     | EFF    Exchange     League        | 400            | League name is already taken.    |
     | E F F E X C H A N G E L e a g u e | 400            | League name is already taken.    |

  @case_sensitive_handling
  Scenario Outline: CheckExchangeLeagueName with various whitespace scenarios
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildLeagueNameData('<leagueName>', existingAccessToken)
    * header Authorization = build.authToken
    * def payload = { query: '#(checkExchangeLeagueNameQuery)', variables: '#(build.variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'CheckExchangeLeagueName Whitespace Response:', response
    * match response.data.checkExchangeLeagueName == null
    * match response.data.checkExchangeLeagueName.statusCode == <expectedStatus>
    * match response.data.checkExchangeLeagueName.message == '<expectedMessage>'

    Examples:
     | leagueName            | expectedStatus | expectedMessage                  |
     | eff exchange league   | 400            | League name is already taken.    |
  