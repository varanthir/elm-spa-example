var { createProxyMiddleware } = require('http-proxy-middleware');
var fallbackMiddleware = require('connect-history-api-fallback');

module.exports = {
  ui: false,
  watch: false,
  ghostMode: false,
  open: false,
  port: 8080,
  server: {
    baseDir: 'build',
    middleware: {
      1: createProxyMiddleware('/api', {
        target: 'http://localhost:3000',
        pathRewrite: { '^/api' : '' }
      }),

      2: fallbackMiddleware({
        index: '/index.html',
        verbose: true,
      })
    }
  }
};
