package Runners;

import com.intuit.karate.junit5.Karate;

/**
 * Private League Flow Runner - Complete end-to-end flow for private league testing
 * 
 * Flow: Auth Setup → User Management → Private League Creation → Second User → Private League Join
 * 
 * Use this runner when you want to test the complete private league journey
 */
public class PrivateLeagueFlowRunner {

    @Karate.Test
    Karate runPrivateLeagueFlow() {
        return Karate.run(
            // Step 1: Auth Module (Setup - Creates test user and authenticates)
            "classpath:Features/auth/checkUsername.feature",
            "classpath:Features/auth/signup.feature",
            "classpath:Features/auth/setpassword.feature",
            "classpath:Features/auth/verifyEmail.feature",
            "classpath:Features/auth/login.feature",

            // Step 2: User Management (Validates user data)
            "classpath:Features/user-management/getUser.feature",

            // Step 3: Blitz League Name Validation
            "classpath:Features/eff-data/blitzLeagues/checkBlitzLeagueName.feature",

            // Step 4: Private League Flow (Main Test Focus)
            "classpath:Features/eff-data/blitzLeagues/createBlitzLeague.feature",

            // Step 5: Create Second User (Required for testing private league invite/join)
            "classpath:helpers/createSecondUser.feature",

            // Step 6: Private League Join (Second user joins via invite code)
            "classpath:Features/eff-data/blitzLeagues/joinPrivateBlitzLeague.feature",

            // Step 7: Cleanup (Deletes test user and all associated data)
            "classpath:Features/user-management/deleteUserAccountByEmail.feature"
        )
        .configDir("file:src/test")
        .outputCucumberJson(true)
        .outputJunitXml(true);
    }
}

