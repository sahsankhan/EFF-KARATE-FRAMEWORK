function fn() {
  var config = {
    baseUrl: 'https://api.effportal.com'
  };
  karate.configure('ssl', true);
  karate.configure('logPrettyRequest', true);
  karate.configure('logPrettyResponse', true);
  return config;
}
