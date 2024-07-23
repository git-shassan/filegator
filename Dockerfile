FROM filegator/filegator

# Copy demo files
COPY configuration.php /var/www/filegator/
COPY users.json /var/www/filegator/private/
COPY filegator.jpeg /var/www/filegator/dist/

# Fix permissions so that demo is read-only
USER www-data

CMD ["apache2-foreground"]
