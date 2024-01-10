const functions = require("firebase-functions");
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");

const adminApp = admin.initializeApp(functions.config().firebase);

const app = express();

// Enable CORS
app.use(cors());

// Parse request body as JSON
app.use(express.json());

const SUCCESSFUL_RES = 200;
const UNSUCCESSFUL_RES = 500;

function getCustomClaims(res, token) {
  admin.auth(adminApp).verifyIdToken(token).then((decodedToken) => {
    // Get user that made the req
    admin.auth(adminApp).getUser(decodedToken.uid).then((userRecord) => {
      return userRecord.customClaims;
    }).catch((error) => {
      return res.status(UNSUCCESSFUL_RES).send({'error': error});
    });
  }).catch((error) => {
    return res.status(UNSUCCESSFUL_RES).send({'error': error});
  });
}

app.post('/handleWebSignUpRole', async (req, res) => {

  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  const MANAGER_STR = "manager";
  const ADMIN_STR = "admin";

  //Global state varibles
  const reqInfo = {
    'body': req.body,
    'email': req.body.email,
    'password': req.body.password,
    'role': req.body.role,
    'token': req.body.adminToken
  };

  const createUserWithClaims = async () => {
    let managerBool = reqInfo['role'] === MANAGER_STR;
    let adminBool = reqInfo['role'] === ADMIN_STR;

    if(adminBool || managerBool){
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

        // Nothing went wrong, return success
        return res.status(SUCCESSFUL_RES).send({'data': userRecord});
      } 
      catch(error){
        return res.status(UNSUCCESSFUL_RES).send({'error': error});
      }
    }
    else{
      return res.status(UNSUCCESSFUL_RES).send({'error': "Not a correct role"});
    }
  }

  const claims = getCustomClaims(res,reqInfo['token']);
  if(claims !== null && claims[ADMIN_STR]) {
    createUserWithClaims();
  }
  else {
    return res.status(UNSUCCESSFUL_RES).send({'error': 'user not an admin'});
  }
});

// TODO: Test using local emulation
app.post('/getUsers', async (req,res) => {

  // TODO: Maybe split to a func
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');

  // Diff content type?
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  const reqInfo = {
    'body': req.body,
    'token': req.body.token
  };
  var userList = [];

  // https://firebase.google.com/docs/auth/admin/manage-users
  const listAllUsers = (nextPageToken) => {
    // Listen to 1000 users at a time
    getAuth().listUsers(1000, nextPageToken).then((listUsersResult) => {
        listUsersResult.users.forEach((userRecord) => {
          userList.append(userRecord);
        });

        if (listUsersResult.pageToken) {
          listAllUsers(listUsersResult.pageToken);
        }
        else{
          return userList;
        }
      }).catch((error) => {
        return res.status(UNSUCCESSFUL_RES).send({'error': error});
      });
  };

  const claims = getCustomClaims(res,reqInfo['token']);
  if(claims !== null) {
    return res.status(SUCCESSFUL_RES).send({'Users': listAllUsers()})
  }
  else {
    return res.status(UNSUCCESSFUL_RES).send({'error': 'unable to fetch'});
  }
});

// TODO: Disable user with custom claims


// exports.disableUsers = functions.https.onRequest(app);
exports.handleWebSignUpRole = functions.https.onRequest(app);
exports.getUsers = functions.https.onRequest(app);