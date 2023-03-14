# Resilience Resource Database (RRDB)

## About
The Resilience Resource Database is a sub-project of the larger Qöyangnuptu Intervention, a National Science Foundation funded project that seeks to increase measures of resilience and mental wellness in tribal communities. [Learn more here!](https://sites.google.com/nau.edu/qoyangnuptu/home) 

The goal of the Resilience Resource Database is to be a dynamic, searchable database that provides information about local, regional, and international resources that support individual resilience and community resilience. The RRDB provides four important features that distinguish it from other health resource databases:

> 1) Explicit communication about privacy protections provided by resources. 
> 2) Explicit communication about connectivity requirements associated with resources. 
> 3) Explicit communication about cultural relevance of resources. 
> 4) Process for collaboratively submitting and reviewing new resources for cultural relevance, privacy, affordability, and connectivity requirements.

Our hope is that this codebase would be a resource for a wider group of tribal communities and organizations that serve American Indian/Alaska Native communities and more resources for supporting the implementation of this resource in other settings will be forthcoming. 

## Flutter Installation
> Follow the instructions provided by the following link: https://docs.flutter.dev/get-started/install

## Run Web App
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
