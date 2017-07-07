# Docker headers
FROM ruby:2.3.0-slim
MAINTAINER Bruno MEDICI <rest-ftp-daemon@bmconseil.com>


# Environment
ENV LANG=C.UTF-8
ENV INSTALL_PATH /app/
ENV app /app/


# Install base packages
RUN apt-get update && apt-get install -y --fix-missing --no-install-recommends build-essential git && apt-get clean


# Prepare bundler
RUN gem install bundler --no-rdoc --no-ri


# Change to INSTALL_PATH and install base packages
RUN mkdir -p                        $INSTALL_PATH
WORKDIR                             $INSTALL_PATH
ADD Gemfile                         $INSTALL_PATH
ADD rest-ftp-daemon.gemspec 		$INSTALL_PATH
RUN bundle install --system --without="development test" -j4


# Install app code
# ADD $CODE_ARCHIVE					/tmp/$CODE_ARCHIVE
# RUN ls -lah
# RUN tar xf /tmp/$CODE_ARCHIVE
ADD . $INSTALL_PATH


# App run
EXPOSE 3000
CMD ["bin/rest-ftp-daemon", "-e", "docker", "-c", "/etc/rftpd.yml", "-f", "start"]
