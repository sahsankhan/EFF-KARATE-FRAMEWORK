Feature: Login API

  Background:
    * url 'https://api.effportal.com'
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'

  Scenario: Successful login
    Given path '/login'
    And request { email: 'temesgen.tiruneh@toptal.com', password: 'Temu@1234' }
    When method post
    Then status 200
    * print '🔹 Response:', response
    * print '🔹 Access Token:', response.accessToken
    * print '🔹 User Email:', response.user.email
    And match response contains { accessToken: '#string', refreshToken: '#string', user: '#object' }
    And match response.user contains { email: 'temesgen.tiruneh@toptal.com' }

  Scenario: Invalid login
    Given path '/login'
    And request { email: 'temesgen.tiruneh@toptal.com', password: 'Temu@123' }
    When method post
    Then status 401
    And match response.error == 'The password is incorrect!'
