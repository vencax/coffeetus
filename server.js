
require('coffee-script/register');

var port = process.env.PORT || 1080;

require('./lib/db')(function(err, db) {

  if(err) { console.log(err); return; }

  var app = require('express')();
  require('./index')(db).initApp(app)

  app.listen(port, function() {
    console.log('gandalf does magic on ' + port);
  });

});
