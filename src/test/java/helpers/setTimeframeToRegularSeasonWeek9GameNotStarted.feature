Feature: Helper - Setup Timeframe to Regular Season Week 9 (Last Game Not Started)

  # This helper sets the timeframe to Regular Season Week 9
  # Scenario: Last game of the week has NOT started yet
  # Called at the beginning of TestRunnerRegularSeasonWeek9GameNotStarted

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

  @set_timeframe_to_regular_season_week9_game_not_started
  Scenario Outline: Setup Regular Season Week 9 - Last Game Not Started
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def variables = buildTimeframeData('<season>', '<seasonType>', '<week>')
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
    * match response.data.setTimeframe.current_timeframe.Week == <week>
    * print 'Timeframe set: Season <season>, Regular Season Week <week> - LAST GAME NOT STARTED'

    Examples:
      | season | seasonType | week | expectedStatus | expectedMessage      |
      | 2025   | 1          | 9    | 200            | Timeframe updated    |
