FROM filegator/filegator
LABEL description="This leverages filtgator original git repo at: https://github.com/filegator/filegator/tree/master"
MAINTAINER Syed Hassan <>
WORKDIR "/var/www/filegator/"
USER www-data
COPY configuration.php /var/www/filegator/
COPY users.json /var/www/filegator/private/
COPY filegator.jpeg /var/www/filegator/dist/
# RUN cp /filegator.jpeg /var/www/filegator/dist/filegator.jpeg; rm /filegator.jpeg; 
# RUN cp /configuration.php /var/www/filegator/configuration.php; rm /configuration.php;
CMD ["apache2-foreground"]
