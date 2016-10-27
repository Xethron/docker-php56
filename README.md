# (DEV ONLY) PHP docker image

This is a little docker image I use for development. It has a few features to make your life easier. Not sure about security, but wouldn't trust it in Production.

## Building the image
`docker build -ti xethron/php56 .` (note the period at the end)

## Running the image
```bash
#!/bin/bash
docker run --name phpdev --rm \
-v /home/xethron/projects:/var/www \
-v /home/xethron/php56/data:/data/ \
-v /home/xethron/php56/config:/config/ \
-p 80:80 \
-p 242:22 \
-i -t xethron/php56
```
Personally, my life is a mess, so I link in every project individually:
```
-v /some/path/to/project:/var/www/project1 \
-v /another/path/whoo:/var/www/better_project \
-v /some/structured/path/my-first-project:/var/www/my_project \
```

## Setting up hosts files
I search for any *.site file in /var/www/*/*.site, so simply add a .site file in the root of every project, and it will automatically be enabled. It will also add all the domain names specified to the dockers /etc/hosts file incase one application calls another, or perhaps even itself... Every project's .site file name must be unique!

Here is one I created for my Symposiumapp dev called symposium.site
```apache
<VirtualHost *:80>
    DocumentRoot /var/www/symposium/public
    ServerName symposiumapp.local
    ServerAlias www.symposiumapp.local

    TransferLog /var/log/apache2/symposium_access.log
    ErrorLog /var/log/apache2/symposium_error.log

    <Directory /var/www/symposium/public>
        RewriteEngine On

        # Redirect Trailing Slashes...
        RewriteRule ^(.*)/$ /$1 [L,R=301]

        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^ index.php [L]
    </Directory>
</VirtualHost>
```

You'll have to point symposiumapp.local to localhost in the host machine's /etc/hosts file, but inside the docker, it is already done...
