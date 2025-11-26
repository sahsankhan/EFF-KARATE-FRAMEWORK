Feature: Validate Token API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def validateQuery = read('classpath:resources/graphql/validateToken.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def buildValidateData =
      """
      function(token, existingAccessToken) {
        var tokenValue = token;
        var resolved = tokenValue == 'existing' ? existingAccessToken : (tokenValue == '' ? null : tokenValue);
        return { authToken: resolved };
      }
      """

  @happy_path
  Scenario Outline: Validate succeeds with valid access token
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    * def build = buildValidateData('<token>', existingAccessToken)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def payload = { query: '#(validateQuery)' }
    Given request payload
    When method post
    Then status 200
    * print 'Validate API Response:', response
    * match response.data.validate.statusCode == 200
    * match response.data.validate.valid == true
    * match response.data.validate.data == karate.get('signUpInfo.email')

    Examples:
      | token   |
      | existing|

  @missing_token
  Scenario Outline: Validate fails when token is missing
    * def build = buildValidateData('<token>', existingAccessToken)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def payload = { query: '#(validateQuery)' }
    Given request payload
    When method post
    Then status 200
    * print 'Validate Missing Token Response:', response
    * match response.data.validate == null
    * match response.errors[0].errorInfo.statusCode == 400
    * match response.errors[0].message contains 'Missing token'

    Examples:
      | token |
      |       |

  @expired_token
  Scenario Outline: Validate fails with expired token
    * def build = buildValidateData('<token>', existingAccessToken)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def payload = { query: '#(validateQuery)' }
    Given request payload
    When method post
    Then status 200
    * print 'Validate Expired Token Response:', response
    * match response.data.validate == null
    * match response.errors[0].errorInfo.statusCode == 401
    * match response.errors[0].message contains 'Expired token'

    Examples:
      | token   |
      | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo |

  @invalid_token
  Scenario Outline: Validate fails with invalid token
    * def build = buildValidateData('<token>', existingAccessToken)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def payload = { query: '#(validateQuery)' }
    Given request payload
    When method post
    Then status 200
    * print 'Validate Invalid Token Response:', response
    * match response.data.validate == null
    * match response.errors[0].errorInfo.statusCode == 401
    * match response.errors[0].message contains 'Invalid token'

    Examples:
      | token                   |
      | malformed_or_invalid_token |

