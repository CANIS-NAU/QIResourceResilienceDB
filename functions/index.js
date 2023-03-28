const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp( functions.config().firebase );

exports.handleSignUpRole = functions.auth.user().onCreate( (user) => {
    
    // Test user agent info is accurate. ( Shouldn't trigger for mobile applications )
    const userAgent = user.metadata.userAgent || '';

    if( !userAgent.includes('Android') || !userAgent.includes('iOS') )
    {
      return admin.auth().setCustomUserClaims(user.uid, {
        'admin': false,
        'manager': true,
      })
      .then(() => {
          console.log("Successful");
      })
      .catch((error) => {
          console.log( error );
      });
    }
  });
  

/*
    // Keep app and web roles seperate
    if( userAgent.includes('Mozilla') || userAgent.includes('Chrome') )
    {
    }
*/
