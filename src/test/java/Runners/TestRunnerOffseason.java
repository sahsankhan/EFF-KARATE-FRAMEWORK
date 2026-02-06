package Runners;

import com.intuit.karate.junit5.Karate;

/**
 * Test Suite for OFFSEASON
 * Timeframe: Season 2025, SeasonType 4 (Offseason)
 **/
class TestRunnerOffseason {

    @Karate.Test
    Karate runOffseasonTests() {
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

            // ⏰ TIMEFRAME SETUP - Set to Offseason
            "classpath:helpers/setTimeframeToOffseason.feature",

            "classpath:Features/user-management/deleteUserAccountByEmail.feature"
            )
        .configDir("file:src/test"); 
    }
}
