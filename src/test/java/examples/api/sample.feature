Feature: Login API Testing

  Background:
    * url 'https://api.effportal.com'

  Scenario: Successful login with valid credentials
    Given path '/login'
    And request { email: 'temesgen.tiruneh@toptal.com', password: 'Temu@9503' }
    When method post
    Then status 200

  Scenario: Login fails with missing password
    Given path '/login'
    And request { email: 'temesgen.tiruneh@toptal.com' , password: 'Temu'}
    When method post
    Then status 402

