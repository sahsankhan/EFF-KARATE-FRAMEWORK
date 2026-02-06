package Runners;

import com.intuit.karate.junit5.Karate;

/**
 * Test Suite for REGULAR SEASON WEEK 10
 * Timeframe: Season 2025, SeasonType 1 (Regular Season), Week 10
 **/
class TestRunnerRegularSeasonWeek10 {

    @Karate.Test
    Karate runRegularSeasonWeek10Tests() {
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

            // ⏰ TIMEFRAME SETUP - Set to Regular Season Week 10
            "classpath:helpers/setTimeframeToRegularSeasonWeek10.feature",

            "classpath:Features/user-management/deleteUserAccountByEmail.feature"
            )
        .configDir("file:src/test"); 
    }
}
