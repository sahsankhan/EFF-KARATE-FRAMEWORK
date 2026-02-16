function fn() {

  var config = {};

  // try reading from system env first (GitHub pipeline)
  var baseUrl = java.lang.System.getenv('BASE_URL');

  if (baseUrl) {
    // ===== CI/CD (GitHub) =====
    config.baseUrl = baseUrl;
    config.apiKey = java.lang.System.getenv('X_API_KEY');
    config.GOOGLE_CLIENT_ID = java.lang.System.getenv('GOOGLE_CLIENT_ID');
    config.GOOGLE_CLIENT_SECRET = java.lang.System.getenv('GOOGLE_CLIENT_SECRET');
    config.GOOGLE_REFRESH_TOKEN = java.lang.System.getenv('GOOGLE_REFRESH_TOKEN');

  } else {
    // ===== LOCAL (.env file) =====
    var Dotenv = Java.type('io.github.cdimascio.dotenv.Dotenv');
    var dotenv = Dotenv.configure().ignoreIfMissing().load();

    config.baseUrl = dotenv.get('BASE_URL');
    config.apiKey = dotenv.get('X_API_KEY');
    config.GOOGLE_CLIENT_ID = dotenv.get('GOOGLE_CLIENT_ID');
    config.GOOGLE_CLIENT_SECRET = dotenv.get('GOOGLE_CLIENT_SECRET');
    config.GOOGLE_REFRESH_TOKEN = dotenv.get('GOOGLE_REFRESH_TOKEN');
  }

  karate.configure('ssl', true);
  karate.configure('logPrettyRequest', true);
  karate.configure('logPrettyResponse', true);

  karate.configure('afterScenario', function () {
    java.lang.Thread.sleep(200);
  });

  karate.configure('retry', { count: 2, interval: 1200 });

  return config;
}
