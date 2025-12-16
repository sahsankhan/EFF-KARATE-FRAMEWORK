Feature: Refresh Token API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def refreshTokenQuery = read('classpath:resources/graphql/auth/refreshToken.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingRefreshToken = karate.get('signUpInfo.refreshToken', null)
    * def buildRefreshData =
    """
    function(token, existing) {
      return {
        refreshToken:
          token === 'existing' ? existing :
          token === 'null' ? null :
          token === '' ? '' :
          token
      };
    }
    """

  @happy_path
  Scenario Outline: Refresh succeeds with valid refresh token
    * if (existingRefreshToken == null) karate.fail('No refresh token found in test data. Run login.feature first')
    * def build = buildRefreshData('<refreshToken>', existingRefreshToken)
    * def refreshVars = karate.toJson(build)
    * def payload = { query: '#(refreshTokenQuery)', variables: '#(refreshVars)' }

    Given request payload
    When method post
    Then status 200
    * print 'RefreshToken API Response:', response
    * match response.data.refreshToken.statusCode == <expectedStatus>
    * match response.data.refreshToken.accessToken == '#present'
    * match response.data.refreshToken.newRefreshToken == '#present'
    * match response.data.refreshToken.user.email == karate.get('signUpInfo.email')

    Examples:
      | refreshToken | expectedStatus | 
      | existing     | 200            | 

  @invalid_token
  Scenario Outline: Refresh fails with invalid refresh token
    * def build = buildRefreshData('<refreshToken>', existingRefreshToken)
    * def refreshVars = karate.toJson(build)
    * def payload = { query: '#(refreshTokenQuery)', variables: '#(refreshVars)' }

    Given request payload
    When method post
    Then status 200
    * print 'RefreshToken Invalid Token Response:', response
    * match response.data.refreshToken == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | refreshToken               | expectedStatus | expectedMessage                      |
      | corrupted_or_invalid_token | 401            | 'Invalid or corrupted refresh token' |

  @missing_token
  Scenario Outline: Refresh fails when token is missing
    * def build = buildRefreshData('<refreshToken>', existingRefreshToken)
    * def refreshVars = karate.toJson(build)
    * def payload = { query: '#(refreshTokenQuery)', variables: '#(refreshVars)' }

    Given request payload
    When method post
    Then status 200
    * print 'RefreshToken Missing Token Response:', response
    * match response.data.refreshToken == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | refreshToken | expectedStatus | expectedMessage          |
      |              | 400            | 'Missing refresh token'  |

  @null_token
  Scenario Outline: Refresh fails when token is missing
    * def build = buildRefreshData('<refreshToken>', existingRefreshToken)
    * def refreshVars = karate.toJson(build)
    * def payload = { query: '#(refreshTokenQuery)', variables: '#(refreshVars)' }

    Given request payload
    When method post
    Then status 200
    * print 'RefreshToken Missing Token Response:', response
    * match response.data == null
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | refreshToken | expectedMessage                                                              |
      | null         | "Variable 'refreshToken' has coerced Null value for NonNull type 'String!'"  |




