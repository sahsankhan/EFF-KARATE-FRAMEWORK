Feature: Gmail OTP Fetcher

  Background:
    * def clientId = karate.get('GOOGLE_CLIENT_ID')
    * def clientSecret = karate.get('GOOGLE_CLIENT_SECRET')
    * def refreshToken = karate.get('GOOGLE_REFRESH_TOKEN')

  Scenario: Fetch OTP
    # STEP 1 — Access token
    Given url 'https://oauth2.googleapis.com/token'
    And request
    """
    {
      "client_id": #(clientId),
      "client_secret": #(clientSecret),
      "refresh_token": #(refreshToken),
      "grant_type": "refresh_token"
    }
    """
    When method post
    Then status 200
    * def accessToken = response.access_token

   # Fetch all matching messages
    Given url 'https://gmail.googleapis.com/gmail/v1/users/me/messages'
    And header Authorization = 'Bearer ' + accessToken
    And param q = 'subject:"Your EFF Password Reset Code"'
    And param maxResults = 5
    When method get
    Then status 200

    # Pick the latest by internalDate
    * def sorted = response.messages.sort((a, b) => b.internalDate - a.internalDate)
    * def messageId = sorted[0].id

    # STEP 3 — Read email
    Given url 'https://gmail.googleapis.com/gmail/v1/users/me/messages/' + messageId
    And header Authorization = 'Bearer ' + accessToken
    And param format = 'full'
    When method get
    Then status 200

    # STEP 4 — Extract OTP from snippet ONLY (guaranteed pure 6 digits)
    * def snippet = response.snippet
    * def otp = snippet.match(/\d{6}/)[0]
    * print '📩 Extracted OTP:', otp

    # Correct return object
    * def result = { code: #(otp) }

