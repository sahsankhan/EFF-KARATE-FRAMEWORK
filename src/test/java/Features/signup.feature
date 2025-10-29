Feature: Sign-Up API Automation
  Purpose: Register a new user by securely storing details, validating inputs, and handling duplicate records.

  Background:
    * url 'https://5uu6v5eh2vbvdjjzzhzrt7ewdi.appsync-api.us-east-1.amazonaws.com/graphql'
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = 'da2-ly43dxgsljaohkedp3qi5ze5ba'
    * text signUpQuery =
      """
      mutation SignUp(
        $first_name: String,
        $last_name: String,
        $email: String,
        $address: AddressInput,
        $dob: String,
        $phone: String,
        $test_bypass: Boolean
      ) {
        signUp(
          first_name: $first_name,
          last_name: $last_name,
          email: $email,
          address: $address,
          dob: $dob,
          phone: $phone,
          test_bypass: $test_bypass
        ) {
          ... on SignUpResponse {
            message
            email
            statusCode
          }
          ... on ErrorResponse {
            message
            statusCode
          }
        }
      }
      """
  Scenario: Successful registration of a new user
    Given request
      """
      {
        "query": "#(signUpQuery)",
        "variables": {
          "first_name": "User",
          "last_name": "Example",
          "email": "userexample_#(karate.randomInt(10000,99999))@gmail.com",
          "address": {
            "street": "123 Main Street",
            "suite": "3A",
            "city": "New York",
            "state": "NY",
            "postal_code": "103044"
          },
          "dob": "1999-05-14",
          "phone": "+14191000000",
          "test_bypass": true
        }
      }
      """
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == 200
    * match response.data.signUp.message contains 'Signup successful. Please check your email to set your password.'

  Scenario: Registration fails when email already exists
    Given request
      """
      {
        "query": "#(signUpQuery)",
        "variables": {
          "first_name": "User",
          "last_name": "Example",
          "email": "userexample9@gmail.com",
          "address": {
            "street": "123 Main Street",
            "suite": "3A",
            "city": "New York",
            "state": "NY",
            "postal_code": "103044"
          },
          "dob": "1999-05-14",
          "phone": "+14191000000",
          "test_bypass": true
        }
      }
      """
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == 409
    * match response.data.signUp.message contains 'Email already exists!'

  Scenario: Registration fails when required fields are missing
    Given request
      """
      {
        "query": "#(signUpQuery)",
        "variables": {
          "email": "userexample9@gmail.com",
          "address": {
            "street": "123 Main Street",
            "suite": "3A",
            "city": "New York",
            "state": "NY",
            "postal_code": "103044"
          },
          "dob": "1999-05-14",
          "phone": "+14191000000",
          "test_bypass": true
        }
      }
      """
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == 400
    * match response.data.signUp.message contains 'Missing required fields!'
