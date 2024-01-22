const functions = require("firebase-functions");
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");

// TODO: Test locally: https://firebase.google.com/docs/functions/local-emulator
//       and possibly use postman

// .end() terimates the response cycle
// we only really contact client side once per cycle so we end on each response

const adminApp = admin.initializeApp(functions.config().firebase);

const app = express();

// Enable CORS
app.use(cors());

// Parse request body as JSON
app.use(express.json());

const SUCCESSFUL_RES = 200;
const UNSUCCESSFUL_RES = 500;

/**
 * @param {*} token - user token used to get custom claims
 * @returns {object} - Contains user claims and errors that occured
 *                                                       (to be check at caller)
 */ 
function getCustomClaims(token) {
  let returnError = null;
  let claims = null;
  admin.auth(adminApp).verifyIdToken(token).then((decodedToken) => {
    admin.auth(adminApp).getUser(decodedToken.uid).then((userRecord) => {
      claims = userRecord.customClaims;
    }).catch((error) => {
      returnError = error;
    });
  }).catch((error) => {
    returnError = error;
  });
  return {'claims':claims, 'error':returnError};
}

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
  res.set('Access-Control-Allow-Origin',origins);
  res.set('Access-Control-Allow-Methods',methods);
  res.set('Access-Control-Allow-Headers',headers);
  return res;
}

// Sign up a user with claims
app.post('/handleWebSignUpRole', async (req, res) => {

  res = setResAttr(res,'*','POST','Content-Type, Authorization');

  const MANAGER_STR = "manager";
  const ADMIN_STR = "admin";
  const reqInfo = {
    'body': req.body,
    'email': req.body.email,
    'password': req.body.password,
    'role': req.body.role,
    'token': req.body.adminToken
  };

  // Creates a new user with correct claims 
  const createUserWithClaims = async () => {
    let managerBool = reqInfo['role'] === MANAGER_STR;
    let adminBool = reqInfo['role'] === ADMIN_STR;

    if(adminBool || managerBool) {
      try {
        // Create a new user with provided creds
        const userRecord = await admin.auth().createUser({
          email: email,
          password: password,
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
  };

  const claims = getCustomClaims(reqInfo['token']);
  if(claims['claims'] !== null && claims['claims'][ADMIN_STR]) {
    createUserWithClaims();
  }
  else {
    return res.status(UNSUCCESSFUL_RES).send({'error': claims['error']}).end();
  }
});

// Gets all users in firebase
app.post('/getUsers', async (req,res) => {
  // TODO: Check correct params
  res = setResAttr(res,'*','POST','Content-Type, application/json');

  // Global scope, no need to return in arrow func
  var userList = [];

  // https://firebase.google.com/docs/auth/admin/manage-users
  const listAllUsers = (nextPageToken) => {
    // Listen to 1000 users at a time
    getAuth().listUsers(1000, nextPageToken).then((listUsersResult) => {
        // Add each user to the user list
        listUsersResult.users.forEach((userRecord) => {
          userList.append(userRecord);
        });
        // Recurse for next 1000 users
        if(listUsersResult.pageToken) {
          listAllUsers(listUsersResult.pageToken);
        }
        else {
          return true;
        }
      }).catch((error) => {
        console.log(error);
        return false;
      });
  };

  // Check for valid user token
  const claims = getCustomClaims(req.body.adminToken);
  if(claims['claims'] !== null) {
    // Check for errors on getting users
    let getUsersStatus = listAllUsers();
    // TODO: See if we need to return user records as json
    return getUsersStatus ? 
      res.status(SUCCESSFUL_RES).send({'Users': userList}).end() :
      res.status(UNSUCCESSFUL_RES).send({'error': 'unable to get users'}).end();
  }
  else {
    return res.status(UNSUCCESSFUL_RES).send({'error': 'Not authorized'}).end();
  }
});

// TODO: Check roles on client side

// Updates an account's disabled/enabled status
app.post('/updateAccountStatus', async (req,res) => { 
  
  // TODO: Check params
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

  // Check for valid user token
  const claims = getCustomClaims(reqInfo['token']);
  if(claims['claims'] !== null) {
    // Get user and set disabled status
    admin.auth()
      .getUser(reqInfo['uid'])
      .then((userRecord) => {
        // Set user disabled to opposite of currently set. 
        setDisabled(!userRecord.disabled);
      })
      .catch((error) => {
        return res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
      });   
    return res.status(SUCCESSFUL_RES).send(
                                  {'Success': "changed account status"}).end();
  }
  else {
    return res.status(UNSUCCESSFUL_RES).send({'error': 'Not authorized'}).end();
  }
});

exports.handleWebSignUpRole = functions.https.onRequest(app);
exports.getUsers            = functions.https.onRequest(app);
exports.updateAccountStatus = functions.https.onRequest(app);