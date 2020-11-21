const { name } = require('./package.json');

module.exports = {
  apps: [{
    name: name,
    script: './app.js',
    watch: '.',
    env: {
      NODE_ENV: 'development',
    },
    env_production: {
      NODE_ENV: 'production',
    }
  }]
};
