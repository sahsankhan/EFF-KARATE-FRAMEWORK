package Runners;

import com.intuit.karate.junit5.Karate;

class TestRunner {

    @Karate.Test
    Karate runLoginTests() {
        return Karate.run("classpath:features/signup.feature");
    }
}
