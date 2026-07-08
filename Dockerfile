FROM filegator/filegator
LABEL description="This leverages filtgator original git repo at: https://github.com/filegator/filegator/tree/master"
MAINTAINER Syed Hassan <shassan@cloudify.network>
WORKDIR "/var/www/filegator/"
USER www-data
# if you have a baseline configuration pre-created, then you can copy it in the container build by ucommenting the following line
# COPY configuration.php /var/www/filegator/
# to include a custom splashscreen, create a simple jpeg (320x120) and include that by uncommenting the following line
# COPY filegator.jpeg /var/www/filegator/dist/
CMD ["apache2-foreground"]
