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

The Firebase CLI will help you interact with Firebase features, testing Cloud Functions locally, deploying application components, etc. If you will be doing this sort of work, you can follow [Firebase CLI's installation instructions](https://firebase.google.com/docs/cli) for your platform. We've already configured the project, so once you've done `firebase login` you completed the necessary steps from that document.

You should also run `firebase experiments:enable webframeworks` to enable Flutter integration.

Know that we use two separate Firebase Projects for RRDB -- one to host a development environment (for us to use as developers) and the other for production (for real users to interact with). When using the Firebase CLI, you'll want to be sure your currently active project is the correct one. If you enter command `firebase use`, it should list the configured projects and indicate which is currently active. (It should use the "default"/"development" project by default.) If you need to switch, for instance to the development project, you can enter the command `firebase use development`. Any subsequent Firebase CLI command will affect that project (unless you specify an override for the command).

### Environment Files

Environment files contain secret values the app uses to communicate with the server back-end. Because they're supposed to be secret, it's bad practice to commit them to git! So you'll have to download these files yourself and put them in the right spot with the right name.

Open the [SUNRISE Google Drive, in the RRDB Secrets folder](https://drive.google.com/drive/folders/1FZ4E5xWmeBb3uxIzHn8gFQy_Qw24IMOq). You should be developing against the dev environment, so download the `dev.env` file. Place it in the project, then rename it `env` -- careful: no dot.

`prod.env` contains keys used by the production server, which is why there are two files, but you won't need that file for normal development. We configured git to ignore env files, but take care never to commit them accidentally.

### Site Deployment

The firebase CLI provides commands for deploying project components. This can include the web site, Cloud Functions, file storage buckets, and so on -- any component that is configured in firebase.json. (For example, here's [the web hosting config documentation](https://firebase.google.com/docs/hosting/full-config).) For right now though, let's just focus on the web site (front-end) itself.

First double check that you have updated git to the code you want to deploy, are "use"-ing the correct Firebase project, and that you configured your environment file. Then, all you need to do is `firebase deploy --only hosting`. ("hosting" refers to the web hosting component of Firebase.) If all goes well, this will build the flutter site and then deploy the contents. (You may need to do a complete refresh in your browser to see the changes.)

### Testing

Flutter provides packages for unit, widget and integration testing. All tests and relevant files are located withing the 'test' directory.

#### Widget Testing
Widget testing is primarily done by verifying the presence of widgets within the build tree. This can be done either by text or by key. Widget tests are located within the directory 'test/widget'. Widget tests can be run either in VS Code's debugging mode or via the CLI. For testing via the CLI, use the command: `flutter test` followed by the location of the testing file. For example:
>`flutter test test/widget/custom_text_field_test.dart`

For additional help see the [widget testing documentation](https://docs.flutter.dev/cookbook/testing/widget/introduction).

#### Integration Testing
Integration testing is similar to widget testing in that you searching for widgets in the build tree but with simulation of user actions. This is accomplished through the use of several methods of the WidgetTester class such as `.tap()`. To setup integration testing download chromedriver according to the instructions [here](https://docs.flutter.dev/testing/integration-tests#test-in-a-web-browser).<br>

>**Note:** This will require the user to at least have Node.js v18. It is recommended to have nvm to assist with installations of Node.<br>

Before starting integration testing run the command:

>`chromedriver --port=4444`

Once chrome driver is started use the command:

>`flutter drive --driver=test/test_driver/integration_test.dart --target=path/to/test/file -d chrome`

Set the target to the path of testing file you would like to run. This will run the tests in a chrome browser. In order to run the tests headless replace 'chrome' with 'web-server'. For additional help see flutter's [integration testing documentation](https://docs.flutter.dev/cookbook/testing/integration/introduction).

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
