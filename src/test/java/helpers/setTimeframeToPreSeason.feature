Feature: Helper - Setup Default Timeframe to Preseason Week 1

  # This helper sets the timeframe to Preseason Week 1
  # This allows all operations (create, join, leave) to work
  # Called once at the beginning of TestRunner

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
      function(season, seasonType, week) {
        var variables = {
          Season: parseInt(season),
          SeasonType: parseInt(seasonType),
          Week: parseInt(week)
        };
        return variables;
      }
      """

  @set_timeframe_to_preseason
  Scenario Outline: Setup Preseason Week 1 as default timeframe
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def variables = buildTimeframeData('<season>', '<seasonType>', '<week>')
    * header Authorization = existingAccessToken
    * def payload = { query: '#(setTimeframeQuery)', variables: '#(variables)' }
    
    Given request payload
    When method post
    Then status 200
    * print 'Setup Default Timeframe Response:', response
    * match response.data.setTimeframe.statusCode == <expectedStatus>
    * match response.data.setTimeframe.message == '<expectedMessage>'
    * match response.data.setTimeframe.current_timeframe.Season == <season>
    * match response.data.setTimeframe.current_timeframe.SeasonType == <seasonType>
    * match response.data.setTimeframe.current_timeframe.Week == <week>
    * print '⏰ Default timeframe set: Season <season>, Preseason Week <week> (All league operations ALLOWED)'

    Examples:
      | season | seasonType | week | expectedStatus | expectedMessage      |
      | 2025   | 2          | 1    | 200            | Timeframe updated    |
