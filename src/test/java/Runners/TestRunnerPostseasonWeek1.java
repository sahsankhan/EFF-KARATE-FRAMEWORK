package Runners;

import com.intuit.karate.junit5.Karate;

/**
 * Test Suite for POSTSEASON WEEK 1
 * Timeframe: Season 2025, SeasonType 3 (Postseason), Week 1
 **/
class TestRunnerPostseasonWeek1 {

    @Karate.Test
    Karate runPostseasonWeek1Tests() {
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

            // ⏰ TIMEFRAME SETUP - Set to Postseason Week 1
            "classpath:helpers/setTimeframeToPostseasonWeek1.feature",

            "classpath:Features/user-management/deleteUserAccountByEmail.feature"
            )
        .configDir("file:src/test"); 
    }
}
