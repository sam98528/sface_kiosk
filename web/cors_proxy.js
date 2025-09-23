// CORS 우회를 위한 프록시 설정
// 개발용으로만 사용

const corsAnywhere = require('cors-anywhere');
const host = 'localhost';
const port = 8080;

corsAnywhere.createServer({
  originWhitelist: [], // 모든 origin 허용
  requireHeaders: [],
  removeHeaders: []
}).listen(port, host, function() {
  console.log('Running CORS Anywhere on ' + host + ':' + port);
});