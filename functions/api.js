const { onRequest } = require("firebase-functions/v2/https");
const { getAuth } = require("firebase-admin/auth");
const express = require("express");
const { v4: uuidv4 } = require("uuid");
const cookieParser = require("cookie-parser");

// docs:
// https://firebase.google.com/docs/functions/http-events?gen=2nd
// https://firebase.google.com/docs/reference/functions/2nd-gen/node/firebase-functions

// Create an express app which will respond to Firebase HTTP requests.
const baseApp = express();
// `cors: true` isn't very secure, but it is easy and I think sufficient for us.
exports.api = onRequest({ cors: true }, baseApp);

// The root of the application will live at /api, which we'll model with a nested router.
const app = express.Router();
baseApp.use("/api", app);

// Parse request body as JSON
app.use(express.json());
// Parse cookies
app.use(cookieParser());

/**********************************
 * Middleware for authn and authz *
 **********************************/

const ADMIN_ROLE = "admin";
const MANAGER_ROLE = "manager";

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
const requireAuth = async (req, res, next) => {
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
const requireAdmin = async (req, res, next) => {
  if (req.token[ADMIN_ROLE] !== true) {
    return res.sendStatus(403);
  }
  return next();
};

/*****************************
 * Endpoint request handlers *
 *****************************/

// Basic "ok" response (which can be used to verify the API is running).
app.get("/", async (req, res) => {
  return res.status(200).end();
});

const UUID_COOKIE = "uuid";
const SESSION_COOKIE = "session";

// Set unique user and session cookies.
app.get("/getSession", (req, res) => {
  let uuid = req.cookies[UUID_COOKIE];
  if (!uuid) {
    uuid = uuidv4();
    res.cookie(UUID_COOKIE, uuid, {
      maxAge: 31_536_000_000, // Expires in one year
      httpOnly: true, // Deny access from JavaScript
      secure: true, // Cookie sent only over HTTPS
      sameSite: "Strict", // Strict same-site policy
    });
  }

  let session = req.cookies[SESSION_COOKIE];
  if (!session) {
    session = uuidv4();
    res.cookie(SESSION_COOKIE, session, {
      // No maxAge means cookie only lives for this session
      httpOnly: true, // Deny access from JavaScript
      secure: true, // Cookie sent only over HTTPS
      sameSite: "Strict", // Strict same-site policy
    });
  }

  res.status(200).send({ uuid, session });
});

// Create a user.
app.post(
  "/handleWebSignUpRole",
  requireAuth,
  requireAdmin,
  async (req, res) => {
    try {
      const role = req.body.role;
      const makeAdmin = role === ADMIN_ROLE;
      const makeManager = role === MANAGER_ROLE;
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
  }
);

// Fetch RRDB users.
app.post("/getUsers", requireAuth, requireAdmin, async (req, res) => {
  // Only include manager accounts.
  const includeUser = (user) => {
    const claims = user?.customClaims;
    if (claims === null || claims === undefined) {
      return false;
    }
    return claims[MANAGER_ROLE] === true;
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
app.post(
  "/updateAccountStatus",
  requireAuth,
  requireAdmin,
  async (req, res) => {
    try {
      const modUid = req.body.uid;
      const modUser = await getAuth().getUser(modUid);
      await getAuth().updateUser(modUid, { disabled: !modUser.disabled });
      return res.sendStatus(200);
    } catch (error) {
      return res.status(500).send({ error: error });
    }
  }
);
