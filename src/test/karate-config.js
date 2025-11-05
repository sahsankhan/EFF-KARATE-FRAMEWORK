function fn() {
    var Dotenv = Java.type('io.github.cdimascio.dotenv.Dotenv');
    var dotenv = Dotenv.load();
  
    var config = {};
    config.baseUrl = dotenv.get('BASE_URL');
    config.apiKey = dotenv.get('X_API_KEY');
  
    karate.configure('ssl', true);
    karate.configure('logPrettyRequest', true);
    karate.configure('logPrettyResponse', true);
    return config;
  }
  