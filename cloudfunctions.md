# Cloud functions
>### Install dependencies: 
> To get started and get the firebase functions tools installed please consider the following documentation:
> https://firebase.google.com/docs/functions/get-started

>### Creating cloud functons with HTTPS requests using express: 
> 1) Import the packages we will need:
> ``` javascript
> const functions = require("firebase-functions");
> const admin = require("firebase-admin");
> const express = require("express");
> const cors = require("cors");

> 2) Initalize the firebase pipeline:
> ``` javascript
> admin.initializeApp( functions.config().firebase );

> 3) We need to now tell the app that we want to use express built in json capabilities:
> ``` javascript
> app.use( express.json() );

> 4) If calling the functions for web, we must enable cors:
> ``` javascript 
> app.use( cors() );

> 5) Creating a cloud function:
> ``` javascript
> app.post( route , async (req, res) => {
> }

> route is where the request will be made from the client side. req is the incoming request. res is what is to be sent back to the client side. 

> 6) If req is from web we must declare that we are okay with the origin of the request. So inside our cloud functions we must declare:
> ``` javascript
> res.set('Access-Control-Allow-Origin', '*');
> res.set('Access-Control-Allow-Methods', 'POST');
> res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

> 7) Getting parameters from the client side request: 
> ``` javascript
> const requestBody = req.body;
> const email = requestBody.email;
> const pass = requestBody.pass;

> 8) Setting user custom claims
> ``` javascript
> await admin.auth().setCustomUserClaims(uid, {
>   'role': 'user',
>});
  

> 9) Returning the response to the client side:
> ``` javascript
> return res.status( 500 ).send( { 'error': "This is indicating an error being sent back to sender" } );
> return res.status( 200 ).send( { 'success': "This is indicating that the cloud function did what it was supposed to with no errors" } );

> 10) Declaring the cloud functions name
> ``` javascript
> exports.cloudFunctionName = functions.https.onRequest(app);

> 11) Deploying the cloud functions( must be in functions directory )
> ``` cmd 
> firebase deploy --only functions

> 12) Calling from the client side application( Dart ):
> ``` dart
>
>            // Hide before push
>            String url = "exampleUrl";
>            
>            final Map<String, dynamic> requestBody = {
>                'email': email,
>                'password': password,
>            };
>
>            final http.Response response = await http.post(
>                Uri.parse( url ),
>                headers: <String, String>{
>                'Content-Type': 'application/json; charset=UTF-8',
>                },
>                body: jsonEncode( requestBody ),
>            );
>
>            if( response.statusCode == 200 ) 
>            {
>               // Success
>               
>           } 
>            else
>            {
>                Map<String, dynamic> errorSpecs = json.decode( response.body )['error'];
>
>                String errorMessage = errorSpecs['code'];
>                
>               //DO SOMETHING WITH THE ERROR
>            }

>13) Getting users custom claims on client side ( Dart )
> ``` Dart
>     User? user = credential.user;
>     if( user != null )
>     {
>        IdTokenResult? userToken = await user?.getIdTokenResult();
>
>        Map<String, dynamic>? claims = userToken?.claims;
>
>        if( claims != null )
>        {
>           //Do something
>        }
>      }

># Conclusion 
> This was an example of post requests cloud functions using https.
> If you want to do the other kinds of requests, you can use the app.get and others but it might change the structure of the cloud function.
> The example simply sends a users email and password through the req object where it is then used in the cloud function. 
