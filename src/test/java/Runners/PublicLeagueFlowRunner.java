package Runners;

import com.intuit.karate.junit5.Karate;

/**
 * Public League Flow Runner - Complete end-to-end flow for public league testing
 * 
 * Flow: Auth Setup → User Management → Public League Operations
 * 
 * Use this runner when you want to test the complete public league journey
 */
public class PublicLeagueFlowRunner {

    @Karate.Test
    Karate runPublicLeagueFlow() {
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

            // Step 4: Public League Flow (Main Test Focus)
            "classpath:Features/eff-data/blitzLeagues/getHomePagePublicExtremeLeagues.feature",
            "classpath:Features/eff-data/blitzLeagues/joinPublicBlitzLeague.feature",
            
            // Step 5: Blitz Team Operations
            "classpath:Features/eff-data/blitzTeams/createBlitzTeam.feature",
            "classpath:Features/eff-data/blitzTeams/checkBlitzTeamName.feature",
            "classpath:Features/eff-data/blitzTeams/getBlitzTeam.feature",
            "classpath:Features/eff-data/blitzTeams/getBlitzTeams.feature",
            
            // Step 6: Continue League Operations
            "classpath:Features/eff-data/blitzLeagues/getBlitzLeague.feature",
            "classpath:Features/eff-data/blitzLeagues/leavePublicBlitzLeague.feature",

            // Step 7: Cleanup (Deletes test user and all associated data)
            "classpath:Features/user-management/deleteUserAccountByEmail.feature"
        )
        .configDir("file:src/test")
        .outputCucumberJson(true)
        .outputJunitXml(true);
    }
}

