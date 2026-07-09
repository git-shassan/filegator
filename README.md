# Purpose of this doc: 
Deploy an interface that would allow upload/download of files from your local server, while meeting the following key requirements: 
* any application used is not allowed to access anything on the internet
* users shoudl be authenticated before they can upload/download
* the applicaiton should follow strict security guidelies
* accessible via HTTPS
* looks and cosmetics can be customized

One application that meets these needs is "FileGator". Additionally, to restict its access, I will recommmend running it in an isolated root-less container. This Repo shows you all the steps you need to take to achieve that 

# Filegator
Filegator is a simple GUI application that provides capability to upload and manage files on a server. It offers multiple tenants/users capability as well. 

This Git shares a simple set of steps to customize it to your own environment, rebuild it as a container image, and then launch it. 

## Configuring your filegator container:
The file 'configuration.php' is (obviously) the file where configuration resides. You can edit this file to suit your own requirements and restrictions for your custom built container. Following are a few things you can tweak:

### Maximum file size:
The default for this field is 100MB. You can change it if you find it acceptable to upload larger files

### Simultaneous uploads:
Default is 3 for 'upload_simultaneous'. 

### Custom splash screen:
You can replace the splash screen and logo in filegator by using your own image (JPEG, SVG etc.) The default file can be replaced by your own, and the name of the file to be used is provided in the field `logo`. 
For example, if the new file is called 'filegator.jpeg', it needs to be placed into the '/var/www/filegator/dist/' directory (don't worry, the Dockerbuild file will take care of this) and then the logo variable needs to say : 
```
        'logo' => './filegator.jpeg',
```

### Other configurations:
You can checkout [this FAQ](https://filegator.io/faq/)  page for many other configuraiton items - though this page is for an older version its still quite userufl. 
For more details on the new versions configuration.php file, refer to [this github page](https://github.com/filegator/filegator/tree/master/docs)

## Building the Container:
Now that the configuration is defined, use the provided Dockerfile, place it in a directory where you also have `configuration.php`,  and `filegator.jpeg`(for logo of your personalized environment). 
Build using: 
```
docker build -t filegator:my -f ./Dockerfile .
```

## Preparing the Environment:
Lets say you want to store your files (managed by filegator) in `~/myfiles` , then create that directory and give it the right permissions using:
```
mkdir ~/myfiles
```

## Creating your container network:
To restrict filegator container from accessing the outside world on its own, use a custom created docker bride that can be restricted in what it accesses: 
```
podman network create --disable-dns=false --internal=true media_net
```

## Running the Container: 
Assuming you want to run filegator on a custom port of 8080, use the followign example: 
```
podman run -d -p 127.0.0.1:8080:8080 --network media_net -v ~/myfiles:/var/www/filegator/repository:Z --name filegator --restart always filegator:my
```
You can use a different port here instead of "8080", for example `127.0.0.1:8888:8080` will make filegator accessible on port 8888

## Open up firewall port: 
Since RHEL/Centos systems have firewalld running by default, it will block the port that you expect to reach filegator on. To open up this port: 
```
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
```

## HTTP Proxy:
At this point, your filegator server is locally accessible. You can also make it publicly accessible by using 0.0.0.0 (or your node's IP) instead of `127.0.0.1' in the podman run command.
But that will add the added complexity of enabling https on filegator (you surely dont want anyone to access it over http, do you?). 

The best way to achieve that is to use a web server (apache/nginx etc.) to perfrom HTTPS functionality. We will go with Apache. 

### Install HTTP Server: 

Lets go ahead and install it: 
```
sudo dnf install httpd -y
```

### Get a domain name: 
If you already have a domainname, then go ahead and make the change in your public DNS records. However, if you don't have one, then you can get a free domain name from [no-ip.com](https://www.noip.com/)

Lets assume that the DNS address you obtained is 'filegator.ddns.net', then the configuration for apache to proxy to your docker container whenever it receives an https reqquest would look like:

```
sudo mkdir /etc/httpd/sites-available/
sudo cat << EOF > /etc/httpd/sites-available/filegator.conf
<VirtualHost *:80>
    ServerName myfilegator.ddns.net
    ServerAlias myfilegator.ddns.net
    ErrorLog /var/log/httpd/proxy/error.log
    CustomLog /var/log/httpd/proxy/requests.log combined
    ProxyPass "/"  "http://127.0.0.1:8080/"
    ProxyPassReverse "/" "http://127.0.0.1:8080/"
    RewriteEngine On
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
</VirtualHost>
EOF
```
Go ahead and enable this config using the following:
```
sudo ln -s /etc/httpd/sites-available/filegator.conf /etc/httpd/sites-enabled/filegator.conf
sudo echo "IncludeOptional /etc/httpd/sites-enabled/*.conf" >> /etc/httpd/conf/httpd.conf
```
Restart apache for changes to take effect: 
```
sudo systemctl restart httpd
```

### Configure SSL certs: 
I wouldn't cover the details here, but you can follow the simple steps provided at: `https://certbot.eff.org/instructions?ws=apache&os=snap`

### Configure Apache to serve HTTPS: 
Modify your virtual host configuraiton in apache to serve https: 
```
sudo cat << EOF >> /etc/httpd/sites-available/filegator.conf
<IfModule mod_ssl.c>
<VirtualHost *:8443>
    ServerName myfilegator.ddns.net
    ErrorLog /var/log/httpd/proxy/error.log
    CustomLog /var/log/httpd/proxy/requests.log combined
    ProxyPass "/"  "http://127.0.0.1:8080/"
    ProxyPassReverse "/" "http://127.0.0.1:8080/"
Include /etc/letsencrypt/options-ssl-apache.conf
SSLCertificateFile /etc/letsencrypt/live/myfilegator.ddns.net/fullchain.pem
SSLCertificateKeyFile /etc/letsencrypt/live/myfilegator.ddns.netmyfilegator.ddns.net/privkey.pem
</VirtualHost>
</IfModule>
```
Restart apache for changes to take effect: 
```
sudo systemctl restart httpd
```

## Allow HTTP to access port with SELinux:
SELinux is another security mechanism that restricts the ports an application can listen on. To allow port 8080 to be used by http, use the folllowing: 
```
sudo semanage port -a -t http_port_t -p tcp 8080
```
You can verify that this port is added by using the following:
```
sudo semanage port -l | grep http
```
## All set:
you can now access your filegator server using its public ip address. Default credentials are `admin/admin123', and you should certainly change that to something that is more secure and meaningful to you

# Logging in and backing up: 
To loginto the system, simply point your browser to the server's IP/url and port 8888. 

Once you create your own users (and delete existing users provided in the sample file), you can extract the changes by using: 
```
podman cp filegator:/var/www/filegator/private/users.json ./users.json
podman cp filegator:/var/www/filegator/configuration.php ./configuration.php
```
This data can be used to rebuild the container image, or launch a new instance. 
