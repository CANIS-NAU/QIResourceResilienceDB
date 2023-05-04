const functions = require("firebase-functions");
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");

admin.initializeApp( functions.config().firebase );

const app = express();

// Enable CORS
app.use( cors() );

// Parse request body as JSON
app.use( express.json() );

app.post('/handleWebSignUpRole', async (req, res) => {

  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  const reqBody = req.body;
  const email = reqBody.email;
  const password = reqBody.password;
  const role = reqBody.role;

  var adminBool = false;
  var managerBool = false;

  if( role === "manager" )
  {
    managerBool = true;
  }
  else if( role === "admin" )
  {
    adminBool = true;
  }
  else
  {
    return res.status( 500 ).send( { 'error': "Not a correct role" } );
  }

  try 
  {
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
    });

    const uid = userRecord.uid;

    await admin.auth().setCustomUserClaims(uid, {
      'manager': managerBool,
      'admin': adminBool,
    });
  
    return res.status( 200 ).send( { 'data': 'User record created successfully' } );

  } 
  catch( error )
  {
    return res.status(500).send({ 'error': error });
  }
});

exports.handleWebSignUpRole = functions.https.onRequest(app);
