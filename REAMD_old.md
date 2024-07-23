# Filegator
Filegator is a simple GUI application that provides capability to upload and manage files on a server. It offers multiple tenants/users capability as well. 

This Git shares a simple set of steps to customize it to your own environment, rebuild it as a container image, and then launch it. 

## Building the Container:
Use the provided Dockerfile, place it in a directory where you also have `configuration.php`,  `users.json` , and `filegator.jpeg`(for logo of your personalized environment). 
Build using: 
```
docker build -t filegator:my -f ./Dockerfile .
```

## Preparing the Environment:
Lets say you want to store your files (managed by filegator) in `~/myfiles` , then create that directory and give it the right permissions using:
```
mkdir ~/myfiles
sudo chown  -R www-data ~/myfiles
```

## Running the Container: 
Assuming you want to run filegator on a custom port of 8888, use the followign example: 
```
docker run -d -p 8888:8080 -v ~/myfiles:/var/www/filegator/repository --name filegator --restart always filegator:my
```

## Logging in and backing up: 
To loginto the system, simply point your browser to the server's IP/url and port 8888. 

Once you create your own users (and delete existing users provided in the sample file), you can bacup your user database for any future use by using: 
```
docker cp filegator:/var/www/filegator/private/users.json ./users.json
docker cp filegator:/var/www/filegator/configuration.php ./configuration.php
```

