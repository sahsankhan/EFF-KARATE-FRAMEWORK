Feature: Sign-Up API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def signUpQuery = read('classpath:resources/graphql/signup.graphql')

  Scenario Outline: Sign-Up with different user data
    * def userData =
      """
      {
        first_name: "<first_name>",
        last_name: "<last_name>",
        email: "<email>",
        address: {
          street: "<street>",
          suite: "<suite>",
          city: "<city>",
          state: "<state>",
          postal_code: "<postal_code>"
        },
        dob: "<dob>",
        phone: "<phone>",
        test_bypass: <test_bypass>
      }
      """

    * def payload = { query: '#(signUpQuery)', variables: '#(userData)' }
    Given request payload
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == <expectedStatus>
    * match response.data.signUp.message contains <expectedMessage>

    Examples:
      | first_name | last_name | email                   | street           | suite | city      | state | postal_code | dob        | phone        | test_bypass | expectedStatus | expectedMessage        |
      | User        | Example   | userexample1000@gmail.com  | 123 Main Street  | 3A    | New York  | NY    | 103044      | 1999-05-14 | +14191000000 | true         | 200            | 'Signup successful. Please check your email to set your password.'      |
      | User        | Example   |                         | 123 Main Street  | 3A    | New York  | NY    | 103044      | 1999-05-14 | +14191000000 | true         | 400            | 'Missing required fields!'      |
      | User        | Example   | userexample9@gmail.com  | 123 Main Street  | 3A    | New York  | NY    | 103044      | 1999-05-14 | +14191       | true         | 400            | 'Invalid phone number format!'   |


  