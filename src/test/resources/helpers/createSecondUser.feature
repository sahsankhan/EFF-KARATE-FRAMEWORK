Feature: Helper - Create Second User for Private League Testing

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def signUpQuery = read('classpath:graphql/auth/signup.graphql')
    * def setPasswordQuery = read('classpath:graphql/auth/setpassword.graphql')
    * def verifyEmailQuery = read('classpath:graphql/auth/verifyEmail.graphql')
    * def loginQuery = read('classpath:graphql/auth/login.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def random = function() { return java.lang.Math.floor(java.lang.Math.random() * 100000); }

  @create_complete_second_user
  Scenario: Create and authenticate second user for private league testing
    # Generate unique credentials for second user
    * def secondUserEmail = 'user' + random() + '_secondary@gmail.com'
    * def secondUserUsername = 'seconduser' + random()
    * def secondUserPassword = 'SecondUser@12345'
    
    * print '========== CREATING SECOND USER =========='
    * print 'Second User Email:', secondUserEmail
    
    # STEP 1: Sign Up Second User
    * def signUpData = { first_name: 'Second', last_name: 'User', username: '#(secondUserUsername)', email: '#(secondUserEmail)', address: { state: 'NY' }, dob: '1995-03-15', phone: '9876543210', heard_about_us: 'Friend', profile_picture: 'icon_tiger' }
    * def signUpPayload = { query: '#(signUpQuery)', variables: '#(signUpData)' }
    Given request signUpPayload
    When method post
    Then status 200
    * print 'SignUp Response:', response
    * match response.data.signUp.statusCode == 200
    * def secondUserResetKey = response.data.signUp.temporarySignupKey
    
    # STEP 2: Set Password (Reset headers for new request)
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def setPasswordData = { email: '#(secondUserEmail)', resetKey: '#(secondUserResetKey)', password: '#(secondUserPassword)' }
    * def setPasswordPayload = { query: '#(setPasswordQuery)', variables: '#(setPasswordData)' }
    Given request setPasswordPayload
    When method post
    Then status 200
    * print 'SetPassword Response:', response
    * match response.data.setPassword.statusCode == 200
    
    # STEP 3: Verify Email (Reset headers for new request)
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def verifyKey = 'TEST_BYPASS::' + secondUserEmail
    * def verifyData = { verifyKey: '#(verifyKey)' }
    * def verifyPayload = { query: '#(verifyEmailQuery)', variables: '#(verifyData)' }
    Given request verifyPayload
    When method post
    Then status 200
    * print 'VerifyEmail Response:', response
    * match response.data.verifyEmail.statusCode == 200
    
    # STEP 4: Login Second User (Reset headers for new request)
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def loginData = { email: '#(secondUserEmail)', password: '#(secondUserPassword)' }
    * def loginPayload = { query: '#(loginQuery)', variables: '#(loginData)' }
    Given request loginPayload
    When method post
    Then status 200
    * print 'Login Response:', response
    * match response.data.login.statusCode == 200
    * def secondUserAccessToken = response.data.login.accessToken
    * def secondUserRefreshToken = response.data.login.refreshToken
    
    # STEP 5: Save both users to info.txt
    * signUpInfo.secondUser = { email: secondUserEmail, username: secondUserUsername, password: secondUserPassword, resetKey: secondUserResetKey, accessToken: secondUserAccessToken, refreshToken: secondUserRefreshToken, isVerified: true, passwordSet: true }
    * karate.write(signUpInfo, 'target/info.txt')
    * print 'First User Email:', signUpInfo.email
    * print 'Second User Email:', secondUserEmail

