Feature: Helper - Check and Ensure Preseason

  # This helper checks current season and ensures it's preseason
  # If not preseason, automatically sets it to preseason
  # Returns immediately if already preseason
  # Called to verify timeframe before operations

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * header Content-Type = 'application/json'
    * header x-api-key = apiKey
    * def getEFFTimeframeQuery = read('classpath:graphql/admin/getEFFTimeframe.graphql')
    * def rawSignUpInfo = karate.read('file:target/target/info.txt')
    * def signUpInfo = JSON.parse(rawSignUpInfo)
    * def existingAccessToken = karate.get('signUpInfo.accessToken', null)

  @check_ensure_preseason
  Scenario Outline: Check current season and ensure preseason
    # PREREQUISITE CHECK: Ensure access token exists
    * if (existingAccessToken == null) karate.fail('No access token found in test data. Run login.feature first')
    
    * def seasonCheck = { query: '#(getEFFTimeframeQuery)' }
    * header Authorization = existingAccessToken
    
    Given request seasonCheck
    When method post
    Then status 200
    * print 'Current Timeframe Check Response:', response
    * match response.data.getEFFTimeframe.statusCode == <expectedStatus>
    * match response.data.getEFFTimeframe.message == '<expectedMessage>'
    * def currentSeasonType = response.data.getEFFTimeframe.current_timeframe.SeasonType
    * print 'Current Season Type:', currentSeasonType, 'Expected Preseason Type:', <expectedSeasonType>
    
    # If not preseason, set to preseason
    * if (currentSeasonType != <expectedSeasonType>) karate.call('classpath:helpers/setTimeframeToPreSeason.feature')
    * if (currentSeasonType == <expectedSeasonType>) karate.log('Already in preseason - no action needed')
    * if (currentSeasonType != <expectedSeasonType>) karate.log('Season type changed to preseason (SeasonType: ' + <expectedSeasonType> + ')')

    Examples:
      | expectedSeasonType | expectedStatus | expectedMessage         |
      | 2                  | 200            | EFF timeframe retrieved |