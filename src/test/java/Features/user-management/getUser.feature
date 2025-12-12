Feature: User Management - Get User API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def getUserQuery = read('classpath:resources/graphql/user-management/getUser.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * print 'SignUp Info from file:', signUpInfo
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def existingEmail = karate.get('signUpInfo.email', null)
    * def buildGetUserData =
      """
      function(token, existingAccessToken) {
        var tokenValue = token;
        var resolved = tokenValue == 'existing' ? existingAccessToken : (tokenValue == '' ? null : tokenValue);
        return { authToken: resolved };
      }
      """

  @happy_path
  Scenario Outline: GetUser succeeds with valid access token
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildGetUserData('<token>', existingAccessToken)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def payload = { query: '#(getUserQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetUser API Response:', response
    * match response.data.getUser.statusCode == 200
    * match response.data.getUser.user.email == existingEmail
    * match response.data.getUser.user != null

    Examples:
      | token    |
      | existing |

  @missing_authorization_header
  Scenario Outline: GetUser fails when Authorization header is missing
    * def build = buildGetUserData('<token>', existingAccessToken)
    * def resolvedToken = build.authToken
    # Do not set Authorization header
    * def payload = { query: '#(getUserQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetUser Missing Token Response:', response
    * match response.data.getUser == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | token | expectedStatus | expectedMessage           |
      |       | 400            | 'Missing token in header' |

  @expired_token
  Scenario Outline: GetUser fails with expired token
    * def expiredToken = '<expiredToken>'
    * header Authorization = expiredToken
    * def payload = { query: '#(getUserQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetUser Expired Token Response:', response
    * match response.data.getUser == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | expiredToken                                                                                                                                                                | expectedStatus | expectedMessage |
      | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | 401            | 'Expired'       |

  @invalid_token
  Scenario Outline: GetUser fails with invalid or corrupted token
    * def invalidToken = '<invalidToken>'
    * header Authorization = invalidToken
    * def payload = { query: '#(getUserQuery)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'GetUser Invalid Token Response:', response
    * match response.data.getUser == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | invalidToken                              | expectedStatus | expectedMessage   |
      | invalid.token.string                      | 401            | 'Invalid'         |
      | random_corrupted_string_12345             | 401            | 'Invalid'         |
      | Bearer invalidtoken123                    | 401            | 'Invalid'         |


