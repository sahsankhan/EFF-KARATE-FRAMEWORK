package Runners;

import com.intuit.karate.junit5.Karate;

/**
 * Test Suite for ALL-STAR WEEK 1
 * Timeframe: Season 2025, SeasonType 5 (All-Star), Week 1
 **/
class TestRunnerAllStarWeek1 {

    @Karate.Test
    Karate runAllStarWeek1Tests() {
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

            // ⏰ TIMEFRAME SETUP - Set to All-Star Week 1
            "classpath:helpers/setTimeframeToAllStarWeek1.feature",

            "classpath:Features/user-management/deleteUserAccountByEmail.feature"
            )
        .configDir("file:src/test"); 
    }
}
