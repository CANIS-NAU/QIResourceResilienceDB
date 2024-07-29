# Resilience Resource Database (RRDB)

## About
The Resilience Resource Database is a sub-project of the larger Qöyangnuptu Intervention, a National Science Foundation funded project that seeks to increase measures of resilience and mental wellness in tribal communities. [Learn more here!](https://sites.google.com/nau.edu/qoyangnuptu/home) 

The goal of the Resilience Resource Database is to be a dynamic, searchable database that provides information about local, regional, and international resources that support individual resilience and community resilience. The RRDB provides four important features that distinguish it from other health resource databases:

> 1) Explicit communication about privacy protections provided by resources. 
> 2) Explicit communication about connectivity requirements associated with resources. 
> 3) Explicit communication about cultural relevance of resources. 
> 4) Process for collaboratively submitting and reviewing new resources for cultural relevance, privacy, affordability, and connectivity requirements.

Our hope is that this codebase would be a resource for a wider group of tribal communities and organizations that serve American Indian/Alaska Native communities and more resources for supporting the implementation of this resource in other settings will be forthcoming. 

## Development Setup

### Flutter Installation

Follow the instructions provided by the following link: https://docs.flutter.dev/get-started/install

### Firebase CLI

The Firebase CLI will help you interact with Firebase features, testing Cloud Functions locally, deploying application components, etc. If you will be doing this sort of work, you can follow [Firebase CLI's installation instructions](https://firebase.google.com/docs/cli) for your platform. We've already configured the project, so once you've done `firebase login` you have completed the setup.

Know that we use two separate Firebase Projects for RRDB -- one to host a development environment (for us to use as developers) and the other for production (for real users to interact with). When using the Firebase CLI, you'll want to be sure your currently active project is the correct one. If you enter command `firebase use`, it should list the configured projects and indicate which is currently active. (It should use the "default"/"development" project by default.) If you need to switch, for instance to the development project, you can enter the command `firebase use development`. Any subsequent Firebase CLI command will affect that project (unless you override that).

### Environment Files

Environment files contain secret values the app uses to communicate with the server back-end. Because they're supposed to be secret, it's bad practice to commit them to git! So you'll have to download these files yourself and put them in the right spot with the right name.

Open the [SUNRISE Google Drive, in the RRDB Secrets folder](https://drive.google.com/drive/folders/1FZ4E5xWmeBb3uxIzHn8gFQy_Qw24IMOq). You should be developing against the dev environment, so download the `dev.env` file. Place it in the project, then rename it `env` -- careful: no dot.

`prod.env` contains keys used by the production server, which is why there are two files, but you won't need that file for normal development. We configured git to ignore env files, but take care never to commit them accidentally.

### Site Deployment

The firebase CLI provides commands for deploying project components. This can include the web site, Cloud Functions, file storage buckets, and so on -- any component that is configured in firebase.json. (For example, here's [the web hosting config documentation](https://firebase.google.com/docs/hosting/full-config).) For right now though, let's just focus on the web site (front-end) itself.

First double check that you have updated git to the code you want to deploy, are "use"-ing the correct Firebase project, and that you configured your environment file. Then, all you need to do is `firebase deploy --only hosting`. ("hosting" refers to the web hosting component of Firebase.) If all goes well, this will build the flutter site and then deploy the contents. (You may need to do a complete refresh in your browser to see the changes.)

## Run Web App Locally
> Once the installation is complete:
> 1) Clone or download the repository.
> 2) Change into the web directory within the cloned or downloaded repository.
> 3) Run the app with your browser of choice using: flutter -d run { browser }. For example using chrome: flutter run -d chrome.
> 4) When testing newly added or fixed code, you can apply changes to the browser by entering 'r' within the command line while the app is running.

## Important Files and Folders
> 1) lib: This is where the web app source code is kept(screens and such). Any changes to be made to the flutter application will be in this folder.
> 2) test: This directory is for tests in the application. There needs to be more tests in the future. 
> 3) assets: Where resources such as images are to be kept for organization.
> 4) web: Do Not Mess With This Directory. This directory may not look important but houses flutter engine initalization. This is why we need to be in this directory to start the web app.
> 5) Firebase Files: Do not touch unless you need to mess with the firebase configuration. These link the backend db. 
> Nothing else is specifically important but I would suggest not touching anything else unless needed. The files are likly to be flutter default configs.

## Help with flutter or dart
> It will sound very cliche but the flutter documentation is very helpful for learning: https://docs.flutter.dev/development/ui/widgets-intro. The development tab is very useful.
