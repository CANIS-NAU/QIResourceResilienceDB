const functions = require("firebase-functions");
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");

const adminApp = admin.initializeApp( functions.config().firebase );

const app = express();

// Enable CORS
app.use( cors() );

// Parse request body as JSON
app.use( express.json() );

app.post('/handleWebSignUpRole', async (req, res) => {

  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  const successfulResponse = 200;
  const unsucessfulResponse = 500;

  //Global state varibles
  const reqBody = req.body;
  const email = reqBody.email;
  const password = reqBody.password;
  const role = reqBody.role;
  const adminToken = reqBody.adminToken;
  var adminBool = false;
  var managerBool = false;

  const setRoleBool = () => {
    if( role === "manager" )
    {
      managerBool = true;
    }
    else if( role === "admin" )
    {
      adminBool = true;
    }
  }

  const createUserWithClaims = async () => {
    setRoleBool();
    if( adminBool || managerBool )
    {
      try 
      {
        const userRecord = await admin.auth().createUser({
          email: email,
          password: password,
        });
    
        const uid = userRecord.uid;
    
        await admin.auth().setCustomUserClaims( uid, {
          'manager': managerBool,
          'admin': adminBool,
        });
        
        return res.status( successfulResponse ).send( { 'data': userRecord } );
    
      } 
      catch( error )
      {
        return res.status( unsucessfulResponse ).send({ 'error': error });
      }
    }
    else
    {
      return res.status( unsucessfulResponse ).send( { 'error': "Not a correct role" } );
    }
  }

  admin.auth( adminApp ).verifyIdToken( adminToken )
  .then( ( decodedToken ) => {
    
    admin.auth( adminApp )
    .getUser(decodedToken.uid)
    .then((userRecord) => {
      const claims = userRecord.customClaims;
      
      if( claims != null && claims['admin'] )
      {
        createUserWithClaims();
      }
      else
      {
        console.error('user is not an admin');
        return res.status( unsucessfulResponse ).send({ 'error': 'User not admin' });
      }

    })
    .catch( ( error ) => {
      return res.status( unsucessfulResponse ).send({ 'error': error });
    });
  })
  .catch( (error) => {
    console.error( error );
    return res.status( unsucessfulResponse ).send({ 'error': error });
  });
});

exports.handleWebSignUpRole = functions.https.onRequest(app);
