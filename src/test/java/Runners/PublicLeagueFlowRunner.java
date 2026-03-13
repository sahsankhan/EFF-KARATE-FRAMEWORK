package Runners;

import com.intuit.karate.junit5.Karate;
import org.junit.jupiter.api.AfterAll;

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
            "classpath:Features/auth/forgotPassword.feature",
            "classpath:Features/auth/verifyResetCode.feature",
            "classpath:Features/auth/validateToken.feature",
            "classpath:Features/auth/refreshToken.feature",

            // Step 2: User Management (Validates user data)
            "classpath:Features/user-management/getUser.feature",
            "classpath:Features/user-management/updateUser.feature",

            // Step 3: League Name Validations
            "classpath:Features/eff-data/blitzLeagues/checkBlitzLeagueName.feature",
            "classpath:Features/eff-data/exchangeLeagues/checkExchangeLeagueName.feature",

            // Step 4: Environment Setup (Set timeframe to preseason for all operations)
            "classpath:helpers/setTimeframeToPreSeason.feature",

            // Step 5: Fetch Available Public Leagues
            "classpath:Features/eff-data/leagues/getHomePagePublicExtremeLeagues.feature",
            "classpath:Features/eff-data/leagues/getAvailableLeagues.feature",
            
            // Step 6: Blitz Format Public League Flow - Complete End-to-End
            "classpath:Features/eff-data/blitzLeagues/joinPublicBlitzLeague.feature",
            "classpath:Features/eff-data/blitzTeams/createBlitzTeam.feature",
            "classpath:Features/eff-data/blitzTeams/checkBlitzTeamName.feature",
            "classpath:Features/eff-data/blitzTeams/getBlitzTeam.feature",
            "classpath:Features/eff-data/blitzTeams/getBlitzTeams.feature",
            "classpath:Features/eff-data/blitzTeams/getBlitzTeamsByLeague.feature",
            "classpath:Features/eff-data/blitzLeagues/getBlitzLeague.feature",
            "classpath:Features/eff-data/blitzLeagues/leavePublicBlitzLeague.feature",

            // Step 7: Exchange Format Public League Flow - Complete End-to-End
            "classpath:Features/eff-data/exchangeLeagues/joinPublicExchangeLeague.feature",
            "classpath:Features/eff-data/exchangeTeams/createExchangeTeam.feature",
            "classpath:Features/eff-data/exchangeTeams/checkExchangeTeamName.feature",
            "classpath:Features/eff-data/exchangeTeams/getExchangeTeam.feature",
            "classpath:Features/eff-data/exchangeTeams/getExchangeTeams.feature",
            "classpath:Features/eff-data/exchangeTeams/getExchangeTeamsByLeague.feature",
            "classpath:Features/eff-data/exchangeLeagues/getExchangeLeague.feature",
            "classpath:Features/eff-data/exchangeLeagues/leaveExchangeLeague.feature",

            // Step 8: Cleanup (Deletes test user and all associated data)
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

