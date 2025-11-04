Feature: Sign-Up API Automation

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
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
          ... on SignUpResponse { message email statusCode }
          ... on ErrorResponse { message statusCode }
        }
      }
      """

  Scenario: Successful registration of a new user
    * def randomEmail = 'userexample' + java.util.UUID.randomUUID() + '@gmail.com'
    * print 'Generated email:', randomEmail
    Given request
      """
      {
        "query": "#(signUpQuery)",
        "variables": {
          "first_name": "User",
          "last_name": "Example",
          "email": #(randomEmail),
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
    * match response.data.signUp.message contains 'Signup successful'

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

  Scenario: Registration fails when required first_name and last_name fields are missing
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

  Scenario: Registration fails when required email field is missing
    Given request
      """
      {
        "query": "#(signUpQuery)",
        "variables": {
         "first_name": "User",
         "last_name": "Example",
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

  Scenario: Registration fails when required address field is missing
    Given request
      """
      {
        "query": "#(signUpQuery)",
        "variables": {
         "first_name": "User",
         "last_name": "Example",
          "email": "userexample9@gmail.com",
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

  Scenario: Registration fails when required dob field is missing
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

  Scenario: Registration fails when first_name, last_name fields are containing invalid values
    Given request
      """
      {
        "query": "#(signUpQuery)",
        "variables": {
         "first_name": "-",
         "last_name": "-",
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
    * match response.data.signUp.message contains 'Invalid first name! Must contain at least 2 letters and may include spaces or hyphens.'

  Scenario: Registration fails when email is invalid
    Given request
      """
      {
        "query": "#(signUpQuery)",
        "variables": {
         "first_name": "User",
         "last_name": "Example",
          "email": "a@b",
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
    * match response.data.signUp.message contains 'Invalid email format!'

  Scenario: Registration fails when phone number is invalid
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
          "phone": "+14191",
          "test_bypass": true
        }
      }
      """
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == 400
    * match response.data.signUp.message contains 'Invalid phone number format!'

  Scenario: Registration fails when postal code is invalid
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
            "postal_code": "abc"
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
    * match response.data.signUp.message contains 'Invalid postal code!'

  Scenario: Registration fails when dob is invalid
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
          "dob": "1999/05/14",
          "phone": "+14191000000",
          "test_bypass": true
        }
      }
      """
    When method post
    Then status 200
    * print response
    * match response.data.signUp.statusCode == 400
    * match response.data.signUp.message contains 'Invalid date format! Expected YYYY-MM-DD format'

  Scenario: Registration fails when city is invalid
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
            "city": "12345",
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
    * match response.data.signUp.message contains 'Invalid city! Only alphabetic characters, spaces, and hyphens are allowed.'
