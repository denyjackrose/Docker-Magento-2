# Pull base Image​
FROM ubuntu:16.04

# Change default shell to bash
SHELL ["/bin/bash","-c"]

# Prepare and Install the required package​
RUN apt-get update && apt-get install -y curl git unzip php apache2 libapache2-mod-php php-{mysql,json,mbstring,curl,mcrypt,gd,bcmath,intl,soap,xml,xdebug,zip} locales \
  && rm -rf /var/lib/apt/lists/* \
  ​&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8​

# Update the PHP.ini file, enable <? ?> tags and quieten logging.​
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php/7.0/apache2/php.ini
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php/7.0/apache2/php.ini

# Manually set up the apache environment variables​
ENV APACHE_RUN_USER www-data​
ENV APACHE_RUN_GROUP www-data​
ENV APACHE_LOG_DIR /var/log/apache2​
ENV APACHE_LOCK_DIR /var/lock/apache2​
ENV APACHE_PID_FILE /var/run/apache2.pid​
ENV LANG en_US.utf8​

# Expose apache.​
EXPOSE 80

# Share default web root
VOLUME /var/www/domain.com/public_html

# Update the default apache site with the config we've created.​
COPY config/apache/domain.com.conf /etc/apache2/sites-available/domain.com.conf

# Disable default configuration
RUN a2dissite 000-default.conf

# Enable new configuration and mod rewrite. Also setup for XDebug to work remotly
RUN a2ensite domain.com.conf && a2enmod rewrite
RUN echo "xdebug.remote_enable=on" >> /etc/php/7.0/mods-available/xdebug.ini
RUN echo "xdebug.remote_autostart=off" >> /etc/php/7.0/mods-available/xdebug.ini

# Download and install composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer

WORKDIR /var/www/domain.com/public_html

# Download and Setup PHP Code Quality Assurance​
RUN curl -LX GET -sSo /usr/local/bin/phpmd http://static.phpmd.org/php/latest/phpmd.phar
RUN curl -LX GET -sSo /usr/local/bin/phpcpd https://phar.phpunit.de/phpcpd.phar
RUN curl -LX GET -sSo /usr/local/bin/phpcs https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar
RUN curl -LX GET -sSo /usr/local/bin/phpcbf https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar
RUN chmod ugo+x /usr/local/bin/phpmd /usr/local/bin/phpcpd /usr/local/bin/phpcs /usr/local/bin/phpcbf
RUN composer require magento-ecg/coding-standard
RUN phpcs --config-set installed_paths vendor/magento-ecg/coding-standard

# By default start up apache in the foreground, override with /bin/bash for interative.​
CMD /usr/sbin/apache2ctl -D FOREGROUND
