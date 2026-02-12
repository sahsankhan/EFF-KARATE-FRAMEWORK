Feature: Helper - Setup Timeframe to Offseason

  # This helper sets the timeframe to Offseason
  # Note: Offseason does not require a Week parameter
  # Called at the beginning of TestRunnerOffseason

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def setTimeframeQuery = read('classpath:resources/graphql/admin/setTimeframe.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)
    * def buildTimeframeData =
      """
      function(season, seasonType) {
        var variables = {
          Season: parseInt(season),
          SeasonType: parseInt(seasonType)
        };
        return variables;
      }
      """

  @set_timeframe_to_offseason
  Scenario Outline: Setup Offseason
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def variables = buildTimeframeData('<season>', '<seasonType>')
    * header Authorization = existingAccessToken
    * def payload = { query: '#(setTimeframeQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'Setup Timeframe Response:', response
    * match response.data.setTimeframe.statusCode == <expectedStatus>
    * match response.data.setTimeframe.message == '<expectedMessage>'
    * match response.data.setTimeframe.current_timeframe.Season == <season>
    * match response.data.setTimeframe.current_timeframe.SeasonType == <seasonType>
    * print 'Timeframe set: Season <season>, Offseason (No week required)'

    Examples:
      | season | seasonType | expectedStatus | expectedMessage      |
      | 2025   | 4          | 200            | Timeframe updated    |
