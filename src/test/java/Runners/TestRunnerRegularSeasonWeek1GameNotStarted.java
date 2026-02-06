package Runners;

import com.intuit.karate.junit5.Karate;

/**
 * Test Suite for REGULAR SEASON WEEK 1 - LAST GAME NOT STARTED
 * Timeframe: Season 2025, SeasonType 1 (Regular Season), Week 1
 * Scenario: Last game of the week has NOT started yet
 **/

class TestRunnerRegularSeasonWeek1GameNotStarted {

    @Karate.Test
    Karate runRegularSeasonWeek1GameNotStartedTests() {
        return Karate.run(
            // Auth Module Tests (Run First)
            "classpath:Features/auth/checkUsername.feature",
            "classpath:Features/auth/signup.feature",
            "classpath:Features/auth/setpassword.feature",
            "classpath:Features/auth/verifyEmail.feature",
            "classpath:Features/auth/login.feature",

            // User Management Module Tests
            "classpath:Features/user-management/getUser.feature",
            "classpath:Features/user-management/updateUser.feature",

            // ⏰ TIMEFRAME SETUP - Set to Regular Season Week 1 (Last Game Not Started)
            "classpath:helpers/setTimeframeToRegularSeasonWeek1GameNotStarted.feature",

            "classpath:Features/user-management/deleteUserAccountByEmail.feature"
            )
        .configDir("file:src/test"); 
    }
}
