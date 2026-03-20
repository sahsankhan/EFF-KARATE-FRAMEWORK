package Runners;

import com.intuit.karate.junit5.Karate;
import org.junit.jupiter.api.AfterAll;

/**
 * Private League Flow Runner - Complete end-to-end flow for private league testing
 * 
 * Flow: Auth Setup → User Management → Private League Creation (Blitz & Exchange) → Second User → Private League Join → Leave League
 * 
 * Use this runner when you want to test the complete private league journey for both Blitz and Exchange formats
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

            // Step 3: League Name Validations
            "classpath:Features/eff-data/blitzLeagues/checkBlitzLeagueName.feature",
            "classpath:Features/eff-data/exchangeLeagues/checkExchangeLeagueName.feature",

            // Step 4: Blitz Format Private League Flow - Complete End-to-End
            "classpath:Features/eff-data/blitzLeagues/createBlitzLeague.feature",

             // Step 5: Create Second User for Private League Testing
             "classpath:helpers/createSecondUser.feature",

            "classpath:Features/eff-data/blitzLeagues/joinPrivateBlitzLeague.feature",
            "classpath:Features/eff-data/blitzTeams/createBlitzTeamPrivateLeague.feature",
            "classpath:Features/eff-data/blitzTeams/getBlitzTeamPrivateLeague.feature",
            "classpath:Features/eff-data/blitzTeams/getBlitzTeamsPrivateLeague.feature",
            "classpath:Features/eff-data/blitzTeams/getBlitzTeamsByPrivateLeague.feature",
            "classpath:Features/eff-data/blitzLeagues/getPrivateBlitzLeague.feature",
            "classpath:Features/eff-data/blitzLeagues/leavePrivateBlitzLeague.feature",

            // Step 6: Exchange Format Private League Flow - Complete End-to-End
            "classpath:Features/eff-data/exchangeLeagues/createExchangeLeague.feature",
            "classpath:Features/eff-data/exchangeLeagues/joinPrivateExchangeLeague.feature",
            "classpath:Features/eff-data/exchangeTeams/createExchangeTeamPrivateLeague.feature",
            "classpath:Features/eff-data/exchangeTeams/getExchangeTeamPrivateLeague.feature",
            "classpath:Features/eff-data/exchangeTeams/getExchangeTeamsPrivateLeague.feature",
            "classpath:Features/eff-data/exchangeTeams/getExchangeTeamsByPrivateLeague.feature",
            "classpath:Features/eff-data/exchangeLeagues/getPrivateExchangeLeague.feature",
            "classpath:Features/eff-data/exchangeLeagues/leavePrivateExchangeLeague.feature",

            // Step 7: Cleanup (Deletes test user and all associated data)
            "classpath:Features/user-management/deleteUserAccountByEmail.feature"
        )
        .configDir("file:src/test")
        .outputCucumberJson(true)
        .outputJunitXml(true);
    }
    
    @AfterAll
    static void enhanceReports() {
        System.out.println("\n🔧 Auto-enhancing Karate reports with scenario counts...");
        try {
            ReportEnhancer.main(new String[]{});
            System.out.println("Reports automatically enhanced! Check karate-summary.html");
        } catch (Exception e) {
            System.err.println("Failed to enhance reports: " + e.getMessage());
        }
    }
}

