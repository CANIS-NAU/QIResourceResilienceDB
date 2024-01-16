const functions = require("firebase-functions");
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");

// TODO: Test locally: https://firebase.google.com/docs/functions/local-emulator
//       and possibly use postman

const adminApp = admin.initializeApp(functions.config().firebase);

const app = express();

// Enable CORS
app.use(cors());

// Parse request body as JSON
app.use(express.json());

const SUCCESSFUL_RES = 200;
const UNSUCCESSFUL_RES = 500;

// TODO: Investigate what res.status.send returns to caller here, may need to
//       return the error object itself to show error in func. 
function getCustomClaims(res, token) {
  admin.auth(adminApp).verifyIdToken(token).then((decodedToken) => {
    admin.auth(adminApp).getUser(decodedToken.uid).then((userRecord) => {
      return userRecord.customClaims;
    }).catch((error) => {
      return res.status(UNSUCCESSFUL_RES).send({'error': error});
    });
  }).catch((error) => {
    return res.status(UNSUCCESSFUL_RES).send({'error': error});
  });
}

// Set response attributes
// res -> Response to send back to client
// origins -> Allowed origins of response
// methods -> The method of the response: POST, GET, ect..
// headers -> The allowed headers of the response
function setResAttr(res,origins,methods,headers) {
  res.set('Access-Control-Allow-Origin',origins);
  res.set('Access-Control-Allow-Methods',methods);
  res.set('Access-Control-Allow-Headers',headers);
  return res;
}

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
          'disabled': false,
        });

        // Nothing went wrong, return success
        return res.status(SUCCESSFUL_RES).send({'data': userRecord});
      } 
      catch(error) {
        return res.status(UNSUCCESSFUL_RES).send({'error': error});
      }
    }
    else {
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

app.post('/getUsers', async (req,res) => {

  // TODO: Potentially change params here
  res = setResAttr(res,'*','POST','Content-Type, Authorization');

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

        if(listUsersResult.pageToken) {
          listAllUsers(listUsersResult.pageToken);
        }
        else {
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

// TODO: Check roles on client side
app.post('/updateAccountStatus', async (req,res) => { 
  
  // TODO: Potentially change params here
  res = setResAttr(res,'*','POST','Content-Type, Authorization');

  // Get info from req
  const reqInfo = {
    'body': req.body,
    'uid': req.body.uid,
    'token': req.body.token
  };

  // Get users claims 
  const claims = getCustomClaims(res,reqInfo['token']);

  // Check for valid claims
  if(claims !== null) {
    // TODO: May need to wrap in async arrow func
    await admin.auth().setCustomUserClaims(reqInfo['uid'], {
      // TODO: On already existing accounts, diabled field DNE
      'disabled': !claims['disabled']
    });
    
    return res.status(SUCCESSFUL_RES).send(
                                         {'Success': "changed account status"});
  }
  else {
    return res.status(UNSUCCESSFUL_RES).send(
                                  {'error': "could not change account status"});
  }
});

exports.handleWebSignUpRole = functions.https.onRequest(app);
exports.getUsers            = functions.https.onRequest(app);
exports.updateAccountStatus = functions.https.onRequest(app);