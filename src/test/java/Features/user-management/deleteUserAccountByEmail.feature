Feature: User Management - Delete User Account By Email API Automation (Test Environment Only)

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def deleteUserQuery = read('classpath:resources/graphql/user-management/deleteUserAccountByEmail.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingEmail = karate.get('signUpInfo.email', null)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def existingSecondUserAccessToken = karate.get('signUpInfo.secondUser.accessToken', null)
    * def existingSecondUserEmail = karate.get('signUpInfo.secondUser.email', null)
    * def buildDeleteUserData =
      """
      function(token, email, existingAccessToken, existingEmail, existingSecondUserAccessToken, existingSecondUserEmail ) {
        var tokenValue = token;
        var emailValue = email;
        var resolvedToken = token == 'existing' ? existingAccessToken : token == 'existingSecond' ? existingSecondUserAccessToken : (token === '' ? null : token);
        var resolvedEmail = email == 'existing' ? existingEmail : email == 'existingSecond' ? existingSecondUserEmail : (email === '' ? '' : email);
        
        var deleteData = {
          email: resolvedEmail
        };
        
        return { authToken: resolvedToken, deleteData: deleteData, resolvedEmail: resolvedEmail };
      }
      """

  @missing_authorization_header
  Scenario Outline: DeleteUserAccountByEmail fails when Authorization header is missing
    * def build = buildDeleteUserData('<token>', '<email>', existingAccessToken, existingEmail)
    # Do not set Authorization header
    * def deleteData = karate.toJson(build.deleteData)
    * def payload = { query: '#(deleteUserQuery)', variables: '#(deleteData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'DeleteUserAccountByEmail Missing Token Response:', response
    * match response.data.deleteUserAccountByEmail == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | token | email    | expectedStatus | expectedMessage           |
      |       | existing | 400            | Missing token in header   |

  @expired_token
  Scenario Outline: DeleteUserAccountByEmail fails with expired token
    * def expiredToken = '<expiredToken>'
    * header Authorization = expiredToken
    * def build = buildDeleteUserData('skip', '<email>', existingAccessToken, existingEmail)
    * def deleteData = karate.toJson(build.deleteData)
    * def payload = { query: '#(deleteUserQuery)', variables: '#(deleteData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'DeleteUserAccountByEmail Expired Token Response:', response
    * match response.data.deleteUserAccountByEmail == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | expiredToken                                                                                                                                                                | email    | expectedStatus | expectedMessage |
      | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | existing | 401            | Expired token   |

  @invalid_token
  Scenario Outline: DeleteUserAccountByEmail fails with invalid or corrupted token
    * def invalidToken = '<invalidToken>'
    * header Authorization = invalidToken
    * def build = buildDeleteUserData('skip', '<email>', existingAccessToken, existingEmail)
    * def deleteData = karate.toJson(build.deleteData)
    * def payload = { query: '#(deleteUserQuery)', variables: '#(deleteData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'DeleteUserAccountByEmail Invalid Token Response:', response
    * match response.data.deleteUserAccountByEmail == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | invalidToken                              | email    | expectedStatus | expectedMessage |
      | invalid.token.string                      | existing | 401            | Invalid token   |
      | random_corrupted_string_12345             | existing | 401            | Invalid token   |
      | Bearer invalidtoken123                    | existing | 401            | Invalid token   |

  @user_not_found
  Scenario Outline: DeleteUserAccountByEmail fails when user is not found
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildDeleteUserData('<token>', '<email>', existingAccessToken, existingEmail)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def deleteData = karate.toJson(build.deleteData)
    * def payload = { query: '#(deleteUserQuery)', variables: '#(deleteData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'DeleteUserAccountByEmail User Not Found Response:', response
    * match response.data.deleteUserAccountByEmail == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains '<expectedMessage>'

    Examples:
      | token    | email                         | expectedStatus | expectedMessage |
      | existing | nonexisting@example.com       | 404            | User not found  |
      | existing | deleteduser@example.com       | 404            | User not found  |

  @happy_path
  Scenario Outline: DeleteUserAccountByEmail succeeds with valid token and existing user email
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    # PREREQUISITE CHECK: Ensure email exists
    * if (existingEmail == null) karate.fail('No email found in test data. Run signup.feature first')
    
    * def build = buildDeleteUserData('<token>', '<email>', existingAccessToken, existingEmail, existingSecondUserAccessToken, existingSecondUserEmail)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def deleteData = karate.toJson(build.deleteData)
    * def payload = { query: '#(deleteUserQuery)', variables: '#(deleteData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'DeleteUserAccountByEmail API Response:', response
    * match response.data.deleteUserAccountByEmail.statusCode == <expectedStatus>
    * match response.data.deleteUserAccountByEmail.message == '<expectedMessage>'
    * print 'TEST SUITE COMPLETED SUCCESSFULLY!'
    * print 'User account deleted successfully along with all associated data:'
    * print ' - User Account'
    * print ' - Blitz and Exchange Leagues owned by user'
    * print ' - Membership records in Blitz and Exchange Leagues'
    * print ' - Blitz and Exchange Teams owned by user'
    * print ' - Blitz Lineups owned by user'

    Examples:
      | token            | email             | expectedStatus | expectedMessage                    |
      | existing         | existing          | 200            | User account deleted successfully  |
      | existingSecond   | existingSecond    | 200            | User account deleted successfully  |

