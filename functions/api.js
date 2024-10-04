const { onRequest } = require("firebase-functions/v2/https");
const { getAuth } = require("firebase-admin/auth");
const express = require("express");

const app = express();
exports.api = onRequest({ cors: true }, app);

// Parse request body as JSON
app.use(express.json());

// Declare constants
const MANAGER_STR = "manager";
const ADMIN_STR = "admin";

app.get("/", async (req, res) => {
  return res.status(200).end();
});

function getAuthHeader(req) {
  // get the auth token from header; "Authorization: Bearer <token>"
  const auth = req.get("authorization");
  if (auth === null || auth === undefined) {
    return null;
  }
  const [authType, authToken] = auth.split(" ");
  if (authType !== "Bearer" || typeof authToken !== "string") {
    return null;
  }
  return authToken;
}

function getAuthBody(req) {
  // for legacy reasons, auth token might be in the request body
  return req.body.adminToken;
}

// Check that the requester has a valid auth token.
// If so, attach the token to the request and continue processing.
const auth = async (req, res, next) => {
  try {
    // Prefer header token, fall back to request body.
    const unverified = getAuthHeader(req) ?? getAuthBody(req);
    if (typeof unverified !== "string") {
      return res.sendStatus(401);
    }

    const token = await getAuth().verifyIdToken(unverified);
    req.token = token;
    return next();
  } catch (error) {
    console.log(error);
    return res.send(500);
  }
};

// Verify that the requester has the "admin" custom claim.
const roleAdmin = async (req, res, next) => {
  const roleAdmin = req.token[ADMIN_STR] === true;
  if (!roleAdmin) {
    return res.sendStatus(403);
  }
  return next();
};

// Create a user.
app.post("/handleWebSignUpRole", auth, roleAdmin, async (req, res) => {
  try {
    const role = req.body.role;
    const makeAdmin = role === ADMIN_STR;
    const makeManager = role === MANAGER_STR;
    if (!makeAdmin && !makeManager) {
      return res.sendStatus(400);
    }

    const user = await getAuth().createUser({
      email: req.body.email,
      password: req.body.password,
    });

    const uid = user.uid;
    await getAuth().setCustomUserClaims(uid, {
      manager: makeManager,
      admin: makeAdmin,
    });

    return res.status(200).send({ data: user });
  } catch (error) {
    return res.status(500).send({ error: error });
  }
});

// Fetch RRDB users.
app.post("/getUsers", auth, roleAdmin, async (req, res) => {
  // Only include manager accounts.
  const includeUser = (user) => {
    const claims = user?.customClaims;
    if (claims === null || claims === undefined) {
      return false;
    }
    return claims[MANAGER_STR] === true;
  };

  // Resource Ref: https://firebase.google.com/docs/auth/admin/manage-users
  const userList = [];
  const listAllUsers = async (nextPageToken) => {
    // Get up to 1000 users, filter to RRDB users, then add to the result list.
    const result = await getAuth().listUsers(1000, nextPageToken);
    result.users.filter(includeUser).forEach((user) => {
      userList.push(user);
    });
    // Recurse for next 1000 users
    if (result.pageToken) {
      await listAllUsers(result.pageToken);
    }
  };

  try {
    await listAllUsers();
    return res.status(200).send({ Users: userList });
  } catch (error) {
    return res.status(500).send({ error: error });
  }
});

// Updates an account's disabled/enabled status
app.post("/updateAccountStatus", auth, roleAdmin, async (req, res) => {
  try {
    const modUid = req.body.uid;
    const modUser = await getAuth().getUser(modUid);
    await getAuth().updateUser(modUid, { disabled: !modUser.disabled });
    return res.sendStatus(200);
  } catch (error) {
    return res.status(500).send({ error: error });
  }
});
