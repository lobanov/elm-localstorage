const path = require('path');

module.exports = {
  entry: './js/index.js',
  mode: 'production',
  output: {
    filename: 'localstorage.min.js',
    path: path.resolve(__dirname, 'dist'),
    clean: true,
    library: {
      name: 'LocalStorage',
      type: 'global',
    },
  },
  externals: {
    'elm-taskport': 'root TaskPort',
  },
};
