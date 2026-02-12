Feature: Helper - Setup Timeframe to Regular Season Week 1 (Last Game Started)

  # This helper sets the timeframe to Regular Season Week 1
  # Scenario: Last game of the week HAS started
  # Called at the beginning of TestRunnerRegularSeasonWeek1GameStarted

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def setTimeframeQuery = read('classpath:resources/graphql/admin/setTimeframe.graphql')
    * def setNowQuery = read('classpath:resources/graphql/admin/setNow.graphql')
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

  @set_timeframe_to_regular_season_week1_game_started
  Scenario Outline: Setup Regular Season Week 1 - Last Game Started
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    # Step 1: Set the timeframe to Regular Season Week 1
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
    * print 'Step 1: Timeframe set to Season <season>, Regular Season Week <week>'
    
    # Step 2: Get the LastGameStart_UTC from the response
    * def lastGameStartUTC = response.data.setTimeframe.current_timeframe.LastGameStart_UTC
    * print 'Last Game Start UTC:', lastGameStartUTC
    
    # Step 3: Set current time to be AFTER the last game start (simulate game started)
    * def nowUTC = '<now_utc>'
    * def nowVariables = ({ now_utc: nowUTC })
     
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * header Authorization = existingAccessToken
    * def nowPayload = { query: '#(setNowQuery)', variables: '#(nowVariables)' }
    
    Given request nowPayload
    When method post
    * print 'Set Now Response:', response
    * match response.data.setNow.statusCode == 200
    * match response.data.setNow.message == 'Current date and time updated'
    * match response.data.setNow.current_timeframe.LastGameStarted == true
    * print 'Step 2: Current time set to', nowUTC
    * print 'LAST GAME STARTED - Simulation Complete'

    Examples:
      | season | seasonType | week | expectedStatus | expectedMessage   | now_utc                    |
      | 2025   | 1          | 1    | 200            | Timeframe updated | 2025-09-09T02:00:00+00:00  |
