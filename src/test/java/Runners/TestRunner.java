package Runners;

import com.intuit.karate.junit5.Karate;

class TestRunner {

    @Karate.Test
    Karate runLoginTests() {
        return Karate.run( "classpath:Features/signup.feature" , "classpath:Features/setpassword.feature","classpath:Features/verifyEmail.feature", "classpath:Features/login.feature", "classpath:Features/forgotPassword.feature", "classpath:Features/verifyResetCode.feature", "classpath:Features/refreshToken.feature", "classpath:Features/validateToken.feature")
        .configDir("file:src/test"); 
    }
}
