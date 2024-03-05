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

// Declare constants
const SUCCESSFUL_RES = 200;
const UNSUCCESSFUL_RES = 500;
const MANAGER_STR = 'manager';
const ADMIN_STR = 'admin';

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
  const role = req.body.role;

  var adminBool = false;
  var managerBool = false;

  const createUserWithClaims = async () => {
    managerBool = role === MANAGER_STR;
    adminBool = role === ADMIN_STR;
    if(adminBool || managerBool) {
      try {
        const userRecord = await admin.auth().createUser({
          email: req.body.email,
          password: req.body.password,
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

  try {
    const decodedToken = await admin.auth(adminApp).verifyIdToken(
                                                                req.body.token);
    if(decodedToken.admin) {
      createUserWithClaims();
    }
    else {
      return res.status(UNSUCCESSFUL_RES).send({'error': 'User not admin'});
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
        if(userRecord.customClaims && userRecord.customClaims !== null) {
          // Verify RRDB user
          if(userRecord.customClaims.hasOwnProperty(MANAGER_STR) || 
             userRecord.customClaims.hasOwnProperty(ADMIN_STR)) {
            // In current iteration, only send manager accounts
            if(userRecord.manager) {
              userList.push(userRecord);
            }
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

  // Verify sender and check that is an RRDB user
  try {
    const decodedToken = await admin.auth(adminApp).verifyIdToken(
                                                                req.body.token);
    // Could also try: typeof(decodedToken.admin) !== 'undefined' if too slow
    if(decodedToken.hasOwnProperty('admin') && 
                                       decodedToken.hasOwnProperty('manager')) {
      // Check that sender is an admin. Otherwise they cannot make the request.
      // May change if super role involved
      if(decodedToken.admin) {
        listAllUsers();
      }
      else {
        return res.status(UNSUCCESSFUL_RES).send(
                         {'error': "Not an authorized to make request."}).end();
      }
    }
    else {
      return res.status(UNSUCCESSFUL_RES).send(
                                    {'error': "Not an authorized user."}).end();
    }
  }
  catch(error) {
    return res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
  }
});

// Updates an account's disabled/enabled status
app.post('/updateAccountStatus', async (req,res) => { 
  res = setResAttr(res,'*','POST','Content-Type, application/json');

  try {
    // Verify the senders token
    const decodedToken = await admin.auth(adminApp).verifyIdToken(
                                                                req.body.token);
    if(decodedToken.admin) {
      // Get the user whose account we want to update
      const modUid = req.body.uid;
      const modUser = await admin.auth().getUser(modUid);
      // Update the account
      await admin.auth().updateUser(modUid, {
        disabled: !modUser.disabled
      });
      return res.status(SUCCESSFUL_RES).end()
    }
    else {
      return res.status(UNSUCCESSFUL_RES).send({'error': 
                                            "Not An Authenticated Role"}).end();
    }
  }
  catch(error) {
    return res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
  }
});

exports.handleWebSignUpRole = functions.https.onRequest(app);
exports.getUsers            = functions.https.onRequest(app);
exports.updateAccountStatus = functions.https.onRequest(app);