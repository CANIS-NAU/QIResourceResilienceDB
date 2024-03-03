const functions = require("firebase-functions");
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");

// .end() terimates the response cycle
// we only really contact client side once per cycle so we end on each response

const adminApp = admin.initializeApp(functions.config().firebase);

const app = express();

// Enable CORS
app.use(cors());

// Parse request body as JSON
app.use(express.json());

// Declare responses
// TODO: May need to evaluate the different return codes
const SUCCESSFUL_RES = 200;
const UNSUCCESSFUL_RES = 500;

const MANAGER_STR = 'manager';
const ADMIN_STR = 'admin';

/**
 * @param {*} token - user token used to get custom claims
 * @returns {object} - Contains user claims and errors that occured
 *                                                       (to be check at caller)
 */ 
/*
async function getCustomClaims(token) {
  let returnError = null;
  let claims = null;
  admin.auth(adminApp).verifyIdToken(token).then((decodedToken) => {
    admin.auth(adminApp).getUser(decodedToken.uid).then((userRecord) => {
      console.log(userRecord.customClaims)
      claims = userRecord.customClaims;
    }).catch((error) => {
      returnError = error;
    });
  }).catch((error) => {
    returnError = error;
  });
  return {'claims':claims, 'error':returnError};
}
*/

/**
 * Sets attr for res 
 * @param {object} res - Response object
 * @param {string} origins - Allowed origins of response and req
 * @param {string} methods - The method of the response: POST, GET, ect..
 * @param {string} headers - The allowed headers of the response
 * @returns {object} - Returns the res object back to caller
 */
function setResAttr(res,origins,methods,headers) {
  // TODO: Investigate if built in methods more sufficient. Ex: res.setHeader()
  res.setHeader('Access-Control-Allow-Origin', origins);
  res.setHeader('Access-Control-Allow-Methods', methods);
  res.setHeader('Access-Control-Allow-Headers', headers);
  return res;
}

app.post('/handleWebSignUpRole', async (req, res) => {

  //res.set('Access-Control-Allow-Origin', '*');
  //res.set('Access-Control-Allow-Methods', 'POST');
  //res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res = setResAttr('*','POST','Content-Type, Authorization');

  // Information in the request
  const reqInfo = {
    'email': req.body.email,
    'pass': req.body.password,
    'role': req.body.role,
    'token': req.body.token 
  }

  var adminBool = false;
  var managerBool = false;

  const createUserWithClaims = async () => {
    managerBool = reqInfo['role'] === MANAGER_STR;
    adminBool = reqInfo['role'] === ADMIN_STR;
    if(adminBool || managerBool) {
      try {
        const userRecord = await admin.auth().createUser({
          email: reqInfo['email'],
          password: reqInfo['pass'],
        });
    
        const uid = userRecord.uid;
        await admin.auth().setCustomUserClaims(uid, {
          MANAGER_STR: managerBool,
          ADMIN_STR: adminBool,
        });
        return res.status(SUCCESSFUL_RES).send({'data': userRecord}).end();
      } 
      catch(error) {
        return res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
      }
    }
    else {
      return res.status(UNSUCCESSFUL_RES).send(
                                         {'error': "Not a correct role"}).end();
    }
  }

  // Check for valid user token
  try {
    decodedToken = await admin.auth(adminApp).verifyIdToken(reqInfo['token']);
    try {
      userRecord = await admin.auth(adminApp).getUser(decodedToken.uid);
      let claims = userRecord.customClaims;
      if(claims !== null && claims[ADMIN_STR]) {
        createUserWithClaims();
      }
      else {
        return res.status(UNSUCCESSFUL_RES).send(
                                                   {'error': 'User not admin'});
      }
    }
    catch(error) {
      return res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
    }
  }
  catch(error) {
    return res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
  }
});

// Gets all users in firebase
app.post('/getUsers', async (req,res) => {
  // Set response attributes
  res = setResAttr(res,'*','POST','Content-Type, application/json');

  // Global scope, no need to return in arrow func
  var userList = [];

  // Resource Ref: https://firebase.google.com/docs/auth/admin/manage-users
  const listAllUsers = async (nextPageToken) => {
    try {
      listUsersResult = await admin.auth(adminApp).listUsers(
                                                           1000, nextPageToken);
      listUsersResult.users.forEach((userRecord) => {
        if (userRecord.customClaims && userRecord.customClaims !== null) {
          if (userRecord.customClaims.hasOwnProperty(MANAGER_STR) || 
              userRecord.customClaims.hasOwnProperty(ADMIN_STR)) {
            userList.push(userRecord);
          }
        }
      });
      // Recurse for next 1000 users
      if (listUsersResult.pageToken) {
        listAllUsers(listUsersResult.pageToken);
      }
      else {
        res.status(SUCCESSFUL_RES).send({'Users': userList}).end();
      }
    }
    catch(error) {
      res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
    }
  };
  
  // Check for valid user token
  try {
    decodedToken = await admin.auth(adminApp).verifyIdToken(req.body.token);
    try {
      userRecord = await admin.auth(adminApp).getUser(decodedToken.uid);
      let claims = userRecord.customClaims;
      if(claims !== null && (ADMIN_STR in claims && MANAGER_STR in claims)) {
        listAllUsers();
      }
      else {
        return res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
      }
    }
    catch(error) {
      return res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
    }
  }
  catch(error) {
    return res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
  }
});

// Updates an account's disabled/enabled status
app.post('/updateAccountStatus', async (req,res) => { 
  res = setResAttr(res,'*','POST','Content-Type, application/json');

  // Get info from req
  const reqInfo = {
    'body': req.body,
    'uid': req.body.uid,
    'token': req.body.adminToken
  };

  // Set the user disabled status
  const setDisabled = async (disValue) => {
    await admin.auth().updateUser(reqInfo['uid'], {
      disabled: disValue
    });
  };

  try {
    decodedToken = await admin.auth(adminApp).verifyIdToken(req.body.token);
    try {
      userRecord = await admin.auth(adminApp).getUser(decodedToken.uid);
      let claims = userRecord.customClaims;
      if(claims !== null && (ADMIN_STR in claims && MANAGER_STR in claims)) {
        try {
          userRecord = await admin.auth().getUser(reqInfo['uid']);
          setDisabled(!userRecord.disabled);
        }
        catch(error) {
          return res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
        }
      }
      else {
        return res.status(UNSUCCESSFUL_RES).send(
                                             {'error': 'Not authorized'}).end();
      }
    }
    catch(error) {
      return res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
    }
  }
  catch(error) {
    return res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
  }
});

exports.handleWebSignUpRole = functions.https.onRequest(app);
exports.getUsers            = functions.https.onRequest(app);
exports.updateAccountStatus = functions.https.onRequest(app);