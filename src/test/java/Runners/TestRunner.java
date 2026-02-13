package Runners;

import com.intuit.karate.junit5.Karate;

class TestRunner {

    @Karate.Test
    Karate runAllTests() {
        return Karate.run(
            // Auth Module Tests (Run First)
            "classpath:Features/auth/checkUsername.feature",
            "classpath:Features/auth/signup.feature",
            "classpath:Features/auth/setpassword.feature",
            "classpath:Features/auth/verifyEmail.feature",
            "classpath:Features/auth/login.feature",
            "classpath:Features/auth/forgotPassword.feature",
            "classpath:Features/auth/validateToken.feature",
            "classpath:Features/auth/refreshToken.feature",

            // User Management Module Tests (Run After Auth)
            "classpath:Features/user-management/getUser.feature",
            "classpath:Features/user-management/updateUser.feature",

            // ⏰ TIMEFRAME SETUP - Set to Preseason Week 1 (allows all operations)
            "classpath:helpers/setTimeframeToPreSeason.feature",

             // Eff Data Module Tests (Run After User Management)
            "classpath:Features/eff-data/blitzLeagues/checkBlitzLeagueName.feature",
            "classpath:Features/eff-data/exchangeTeams/checkExchangeTeamName.feature",
            "classpath:Features/eff-data/exchangeLeagues/checkExchangeLeagueName.feature",

            // Public Blitz League Module Tests
            "classpath:Features/eff-data/blitzLeagues/getHomePagePublicExtremeLeagues.feature",
            "classpath:Features/eff-data/blitzLeagues/joinPublicBlitzLeague.feature",

            // Blitz Team Operations
            "classpath:Features/eff-data/blitzTeams/checkBlitzTeamName.feature",
            "classpath:Features/eff-data/blitzTeams/getBlitzTeam.feature",
            "classpath:Features/eff-data/blitzTeams/getBlitzTeams.feature",
            "classpath:Features/eff-data/blitzTeams/getBlitzTeamsByLeague.feature",

        

            // Private Blitz League Module Tests 
             "classpath:Features/eff-data/blitzLeagues/createBlitzLeague.feature",
             "classpath:helpers/createSecondUser.feature",
             "classpath:Features/eff-data/blitzLeagues/joinPrivateBlitzLeague.feature",
             "classpath:Features/eff-data/blitzLeagues/leavePrivateBlitzLeague.feature",

           
            )
        .configDir("file:src/test"); 
    }
}
