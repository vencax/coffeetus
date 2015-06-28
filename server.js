
require('coffee-script/register');

var port = process.env.PORT || 1080;

var app = require('express')();

require('./lib/db')(function(db) {

  require('./index').initApp(app, db)

  app.listen(port, function() {
    console.log('gandalf does magic on ' + port);
  });
});
