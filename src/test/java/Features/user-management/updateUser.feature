Feature: User Management - Update User API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def updateUserQuery = read('classpath:resources/graphql/user-management/updateUser.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def existingEmail = karate.get('signUpInfo.email', null)
    * def random = function() { return java.lang.Math.floor(java.lang.Math.random() * 100000); }
    * def buildUpdateUserData =
      """
      function(token, first_name, last_name, username, dob ,state, profile_picture, existingAccessToken) {
        var tokenValue = token;
        var resolvedToken = tokenValue == 'existing' ? existingAccessToken : (tokenValue == '' ? null : tokenValue);
        var dynamicUsername = username == 'random' ? 'k' + random() : username;
         
        var userData = {};
        if (first_name !== undefined && first_name !== 'skip') userData.first_name = first_name;
        if (last_name !== undefined && last_name !== 'skip') userData.last_name = last_name;
        if (username !== undefined && username !== 'skip') userData.username = dynamicUsername;
        if (state !== undefined && state !== 'skip') userData.address = { state: state };
        if (dob !== undefined && dob !== 'skip') userData.dob = dob;
        if (profile_picture !== undefined && profile_picture !== 'skip') userData.profile_picture = profile_picture;
        
        return { authToken: resolvedToken, userData: userData, dynamicUsername: dynamicUsername };
      }
      """

  @missing_authorization_header
  Scenario Outline: UpdateUser fails when Authorization header is missing
    * def build = buildUpdateUserData('<token>', '<first_name>', 'skip', 'skip', 'skip', 'skip', 'skip', 'skip', existingAccessToken)
    * def resolvedToken = build.authToken
    # Do not set Authorization header
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(updateUserQuery)', variables: '#(userData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'UpdateUser Missing Token Response:', response
    * match response.data.updateUser == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | token | first_name | expectedStatus | expectedMessage           |
      |       | User1      | 400            | 'Missing token in header' |

  @expired_token
  Scenario Outline: UpdateUser fails with expired token
    * def expiredToken = '<expiredToken>'
    * header Authorization = expiredToken
    * def build = buildUpdateUserData('skip', '<first_name>', 'skip', 'skip', 'skip', 'skip', 'skip', 'skip', existingAccessToken)
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(updateUserQuery)', variables: '#(userData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'UpdateUser Expired Token Response:', response
    * match response.data.updateUser == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | expiredToken                                                                                                                                                                | first_name | expectedStatus | expectedMessage       |
      | eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2YWx1ZSI6InVzZXJleGFtcGxlMjI1QGdtYWlsLmNvbSIsInJvbGUiOiJ1c2VyIiwiZXhwIjoxNzY0MTcyOTE2fQ.cQmknZ_etOJ9Fw-YJYHLscbqD4XoXWFdQYSJd7czypo | User-c     | 401            | 'Expired token'       |

  @invalid_token
  Scenario Outline: UpdateUser fails with invalid or corrupted token
    * def invalidToken = '<invalidToken>'
    * header Authorization = invalidToken
    * def build = buildUpdateUserData('skip', '<first_name>', 'skip', 'skip', 'skip', 'skip', 'skip', 'skip', existingAccessToken)
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(updateUserQuery)', variables: '#(userData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'UpdateUser Invalid Token Response:', response
    * match response.data.updateUser == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
      | invalidToken                              | expectedStatus | expectedMessage    |
      | invalid.token.string                      | 401            | 'Invalid token'    |
      | random_corrupted_string_12345             | 401            | 'Invalid token'    |
      | Bearer invalidtoken123                    | 401            | 'Invalid token'    |

  @happy_path
  Scenario Outline: UpdateUser succeeds with valid token and valid user profile data update
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildUpdateUserData('<token>', '<first_name>' , '<last_name>' , '<username>' , '<dob>', '<state>' , '<profile_picture>', existingAccessToken)
    * def resolvedToken = build.authToken
    * def dynamicUsername = build.dynamicUsername
    * header Authorization = resolvedToken
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(updateUserQuery)', variables: '#(userData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'UpdateUser API Response:', response
    * match response.data.updateUser.statusCode ==  <expectedStatus>
    * match response.data.updateUser.message == <expectedMessage>
    * match response.data.updateUser.user != null
    * match response.data.updateUser.user.email == existingEmail
    * match response.data.updateUser.user.username == dynamicUsername
    * match response.data.updateUser.user.address.state == '<state>'

    Examples:
      | token    | first_name | last_name | username | dob        | state  | profile_picture | expectedStatus | expectedMessage              |
      | existing | user       | example   | random   | 1987-05-21 |  IL    | icon_lion       | 200            | 'User updated successfully.' | 


  @partial_update_address
  Scenario Outline: UpdateUser succeeds with partial update - only state
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildUpdateUserData('<token>', 'skip', 'skip', 'skip', 'skip', '<state>', 'skip', existingAccessToken)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(updateUserQuery)', variables: '#(userData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'UpdateUser Partial (Address) Response:', response
    * match response.data.updateUser.statusCode == <expectedStatus>
    * match response.data.updateUser.message == <expectedMessage>
    * match response.data.updateUser.user.address.state == '<state>'

    Examples:
     | token     | state | expectedStatus | expectedMessage              |
     | existing  | CA    | 200            | 'User updated successfully.' |

  @partial_update_first_name
  Scenario Outline: UpdateUser succeeds with partial update - only first name
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildUpdateUserData('<token>', '<first_name>', 'skip', 'skip', 'skip', 'skip', 'skip', existingAccessToken)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(updateUserQuery)', variables: '#(userData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'UpdateUser Partial (Username) Response:', response
    * match response.data.updateUser.statusCode == <expectedStatus>
    * match response.data.updateUser.message == <expectedMessage>
    * match response.data.updateUser.user.first_name == '<first_name>'

     Examples:
     | token     | first_name       | expectedStatus | expectedMessage              |
     | existing  | updatedFirstName | 200            | 'User updated successfully.' |

  @partial_update_last_name
  Scenario Outline: UpdateUser succeeds with partial update - only last name
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildUpdateUserData('<token>', 'skip', '<last_name>', 'skip', 'skip', 'skip', 'skip', existingAccessToken)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(updateUserQuery)', variables: '#(userData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'UpdateUser Partial (Username) Response:', response
    * match response.data.updateUser.statusCode == <expectedStatus>
    * match response.data.updateUser.message == <expectedMessage>
    * match response.data.updateUser.user.last_name == '<last_name>'

     Examples:
     | token     | last_name          | expectedStatus | expectedMessage              |
     | existing  | updatedLastName    | 200            | 'User updated successfully.' |

  @partial_update_username
  Scenario Outline: UpdateUser succeeds with partial update - only username
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildUpdateUserData('<token>', 'skip', 'skip', '<username>', 'skip', 'skip', 'skip', existingAccessToken)
    * def resolvedToken = build.authToken
    * def dynamicUsername = build.dynamicUsername
    * header Authorization = resolvedToken
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(updateUserQuery)', variables: '#(userData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'UpdateUser Partial (Username) Response:', response
    * match response.data.updateUser.statusCode == <expectedStatus>
    * match response.data.updateUser.message == <expectedMessage>
    * match response.data.updateUser.user.username == dynamicUsername

     Examples:
     | token     | username             | expectedStatus | expectedMessage              |
     | existing  | random               | 200            | 'User updated successfully.' |

  @partial_update_dob
  Scenario Outline: UpdateUser succeeds with partial update - only dob
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildUpdateUserData('<token>','skip', 'skip', 'skip', '<dob>', 'skip', 'skip',  existingAccessToken)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(updateUserQuery)', variables: '#(userData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'UpdateUser Partial (Address) Response:', response
    * match response.data.updateUser.statusCode == <expectedStatus>
    * match response.data.updateUser.message == <expectedMessage>
    * match response.data.updateUser.user.dob == '<dob>'

    Examples:
     | token     | dob           | expectedStatus | expectedMessage              |
     | existing  | 2000-05-21    | 200            | 'User updated successfully.' |

  @partial_update_profile_picture
  Scenario Outline: UpdateUser succeeds with partial update - only profile picture
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildUpdateUserData('<token>','skip', 'skip', 'skip', 'skip', 'skip', '<profile_picture>', existingAccessToken)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(updateUserQuery)', variables: '#(userData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'UpdateUser Partial (Address) Response:', response
    * match response.data.updateUser.statusCode == <expectedStatus>
    * match response.data.updateUser.message == <expectedMessage>
    * match response.data.updateUser.user.profile_picture == '<profile_picture>'

    Examples:
     | token     | profile_picture  | expectedStatus | expectedMessage              |
     | existing  | icon_panda       | 200            | 'User updated successfully.' |

  @invalid_first_name_structure
  Scenario Outline: UpdateUser fails with invalid first name structure
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildUpdateUserData('<token>', '<first_name>', 'skip', 'skip', 'skip', 'skip', 'skip', existingAccessToken)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(updateUserQuery)', variables: '#(userData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'UpdateUser Invalid Address Response:', response
    * match response.data.updateUser == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
     | token     | first_name                                              | expectedStatus | expectedMessage                                                                                       |
     | existing  | 12345                                                   | 400            | 'First name must contain at least one letter.'                                                        |
     | existing  | ---                                                     | 400            | 'First name must contain at least one letter.'                                                        |
     | existing  | A@                                                      | 400            | 'Invalid first name! Must contain at least 1 letter and may include spaces, hyphens or apostrophes.'  |
     | existing  | A!                                                      | 400            | 'Invalid first name! Must contain at least 1 letter and may include spaces, hyphens or apostrophes.'  |
     | existing  | A.                                                      | 400            | 'Invalid first name! Must contain at least 1 letter and may include spaces, hyphens or apostrophes.'  |
     | existing  | Itisaverylongfirstnameofusertobeenteredinsignuppayl     | 400            | 'First name cannot be more than 50 characters.'                                                       |
     | existing  | Itisaverylongfirstnameofusertobeenteredinsignuppayload  | 400            | 'First name cannot be more than 50 characters.'                                                       |

  @invalid_last_name_structure
  Scenario Outline: UpdateUser fails with invalid last name structure
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildUpdateUserData('<token>', 'skip', '<last_name>', 'skip', 'skip', 'skip', 'skip', existingAccessToken)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(updateUserQuery)', variables: '#(userData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'UpdateUser Invalid Address Response:', response
    * match response.data.updateUser == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
     | token     | last_name                                               | expectedStatus | expectedMessage                                                                                      |
     | existing  | 12345                                                   | 400            | 'Last name must contain at least one letter.'                                                        |
     | existing  | ---                                                     | 400            | 'Last name must contain at least one letter.'                                                        |
     | existing  | A@                                                      | 400            | 'Invalid last name! Must contain at least 1 letter and may include spaces, hyphens or apostrophes.'  |
     | existing  | A!                                                      | 400            | 'Invalid last name! Must contain at least 1 letter and may include spaces, hyphens or apostrophes.'  |
     | existing  | A.                                                      | 400            | 'Invalid last name! Must contain at least 1 letter and may include spaces, hyphens or apostrophes.'  |
     | existing  | Itisaverylonglastnameofusertobeenteredinsignuppaylo     | 400            | 'Last name cannot be more than 50 characters.'                                                       |
     | existing  | Itisaverylonglastnameofusertobeenteredinsignuppayload   | 400            | 'Last name cannot be more than 50 characters.'                                                       |

  @invalid_user_name_structure
  Scenario Outline: UpdateUser fails with invalid username structure
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildUpdateUserData('<token>', 'skip', 'skip', '<username>', 'skip', 'skip', 'skip', existingAccessToken)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(updateUserQuery)', variables: '#(userData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'UpdateUser Invalid Address Response:', response
    * match response.data.updateUser == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
     | token     | username                        | expectedStatus | expectedMessage                                                     |
     | existing  | ab                              | 400            | 'Username cannot be less than 3 characters.'                        |
     | existing  | 12                              | 400            | 'Username cannot be less than 3 characters.'                        |
     | existing  | ---                             | 400            | 'Username must contain at least one letter.'                        |
     | existing  | 123                             | 400            | 'Username must contain at least one letter.'                        |
     | existing  | A@@                             | 400            | 'can only contain letters, numbers, underscores, hyphens and dots'  |
     | existing  | A!!                             | 400            | 'can only contain letters, numbers, underscores, hyphens and dots'  |
     | existing  | Itisaverylongusernameforuser123 | 400            | 'Username cannot be more than 30 characters.'                       |

  @invalid_address_structure
  Scenario Outline: UpdateUser fails with invalid address structure
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildUpdateUserData('<token>', 'skip', 'skip', 'skip', 'skip', '<state>', 'skip', existingAccessToken)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(updateUserQuery)', variables: '#(userData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'UpdateUser Invalid Address Response:', response
    * match response.data.updateUser == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
     | token     | state  | expectedStatus | expectedMessage  
     | existing  |  123   | 400            | 'Invalid U.S. state. Must be a valid state name or abbreviation.'
     | existing  |  abc   | 400            | 'Invalid U.S. state. Must be a valid state name or abbreviation.'
     | existing  | state  | 400            | 'Invalid U.S. state. Must be a valid state name or abbreviation.'

  @invalid_dob_structure
  Scenario Outline: UpdateUser fails with invalid dob structure
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildUpdateUserData('<token>', 'skip', 'skip', 'skip', '<dob>', 'skip', 'skip', existingAccessToken)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(updateUserQuery)', variables: '#(userData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'UpdateUser Invalid Address Response:', response
    * match response.data.updateUser == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
     | token     |  dob          | expectedStatus | expectedMessage  
     | existing  |  1987/05/21   | 400            | 'Invalid date format! Expected YYYY-MM-DD format'
     | existing  |  20/05/1987   | 400            | 'Invalid date format! Expected YYYY-MM-DD format'
  
  @invalid_profile_picture_structure
  Scenario Outline: UpdateUser fails with invalid profile picture structure
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def build = buildUpdateUserData('<token>', 'skip', 'skip', 'skip', 'skip', 'skip', '<profile_picture>', existingAccessToken)
    * def resolvedToken = build.authToken
    * header Authorization = resolvedToken
    * def userData = karate.toJson(build.userData)
    * def payload = { query: '#(updateUserQuery)', variables: '#(userData)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'UpdateUser Invalid Address Response:', response
    * match response.data.updateUser == null
    * match response.errors[0].errorInfo.statusCode == <expectedStatus>
    * match response.errors[0].message contains <expectedMessage>

    Examples:
     | token     | profile_picture  | expectedStatus | expectedMessage  
     | existing  |  abc             | 400            | "Invalid profile image. Must be a valid icon name like 'icon_tiger' or 'icon_person'."
     | existing  |  1234            | 400            | "Invalid profile image. Must be a valid icon name like 'icon_tiger' or 'icon_person'."

