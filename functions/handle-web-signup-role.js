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

const MANAGER_STR = "manager";
const ADMIN_STR = "admin";

/**
 * @param {*} token - user token used to get custom claims
 * @returns {object} - Contains user claims and errors that occured
 *                                                       (to be check at caller)
 */ 
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

  const createUserWithClaims = async () => {
    managerBool = role === MANAGER_STR;
    adminBool = role === ADMIN_STR;
    if(adminBool || managerBool) {
      try {
        const userRecord = await admin.auth().createUser({
          email: email,
          password: password,
        });
    
        const uid = userRecord.uid;
    
        await admin.auth().setCustomUserClaims(uid, {
          'manager': managerBool,
          'admin': adminBool,
        });
        return res.status(successfulResponse).send({'data': userRecord});
      } 
      catch(error) {
        return res.status(unsucessfulResponse).send({'error': error});
      }
    }
    else {
      return res.status(unsucessfulResponse).send(
                                               {'error': "Not a correct role"});
    }
  }

  admin.auth(adminApp).verifyIdToken(adminToken).then((decodedToken) => {
    admin.auth(adminApp).getUser(decodedToken.uid).then((userRecord) => {
      const claims = userRecord.customClaims;
      if(claims !== null && claims['admin']) {
        createUserWithClaims();
      }
      else {
        return res.status( unsucessfulResponse ).send(
                                                   {'error': 'User not admin'});
      }
    }).catch((error) => {
      return res.status( unsucessfulResponse ).send({'error': error });
    });
  })
  .catch( (error) => {
    return res.status(unsucessfulResponse).send({ 'error': error});
  });
});

// Gets all users in firebase
app.post('/getUsers', async (req,res) => {
  res = setResAttr(res,'*','POST','Content-Type, application/json');

  // Global scope, no need to return in arrow func
  var userList = [];

  // https://firebase.google.com/docs/auth/admin/manage-users
  const listAllUsers = (nextPageToken) => {
    // Listen to 1000 users at a time
    admin.auth(adminApp).listUsers(1000, nextPageToken)
                                                    .then((listUsersResult) => {
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
    }).catch((error) => {
      res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
    });
  };
  

  // Check for valid user token
  admin.auth(adminApp).verifyIdToken(req.body.token).then((decodedToken) => {
    admin.auth(adminApp).getUser(decodedToken.uid).then((userRecord) => {
      let claims = userRecord.customClaims;
      if(claims !== null && (ADMIN_STR in claims && MANAGER_STR in claims)) {
        listAllUsers();
      }
    }).catch((error) => {
      return res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
    });
  }).catch((error) => {
    return res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
  });
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

  // Check for valid user token
  admin.auth(adminApp).verifyIdToken(req.body.token).then((decodedToken) => {
    admin.auth(adminApp).getUser(decodedToken.uid).then((userRecord) => {
      let claims = userRecord.customClaims;
      if(claims !== null && (ADMIN_STR in claims && MANAGER_STR in claims)) {
        // Get user and set disabled status
        admin.auth().getUser(reqInfo['uid']).then((userRecord) => {
          // Set user disabled to opposite of currently set. 
          setDisabled(!userRecord.disabled);
        }).catch((error) => {
          return res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
        });   
        return res.status(SUCCESSFUL_RES).send(
                                   {'Success': "changed account status"}).end();
      }
      else {
        return res.status(UNSUCCESSFUL_RES).send(
                                             {'error': 'Not authorized'}).end();
      }
    }).catch((error) => {
      return res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
    });
  }).catch((error) => {
    return res.status(UNSUCCESSFUL_RES).send({'error': error}).end();
  });
});

exports.handleWebSignUpRole = functions.https.onRequest(app);
exports.getUsers            = functions.https.onRequest(app);
exports.updateAccountStatus = functions.https.onRequest(app);