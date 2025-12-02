function fn() {
    var Dotenv = Java.type('io.github.cdimascio.dotenv.Dotenv');
    var dotenv = Dotenv.load();
  
    var config = {};
    config.baseUrl = dotenv.get('BASE_URL');
    config.apiKey = dotenv.get('X_API_KEY');
    config.GOOGLE_CLIENT_ID = dotenv.get('GOOGLE_CLIENT_ID');
    config.GOOGLE_CLIENT_SECRET = dotenv.get('GOOGLE_CLIENT_SECRET');
    config.GOOGLE_REFRESH_TOKEN = dotenv.get('GOOGLE_REFRESH_TOKEN');
  
    karate.configure('ssl', true);
    karate.configure('logPrettyRequest', true);
    karate.configure('logPrettyResponse', true);
    return config;
  }
  