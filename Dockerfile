# Docker headers
FROM ruby:2.6.2-alpine3.9
MAINTAINER Bruno MEDICI <opensource@bmconseil.com>

# Environment
ENV LANG=C.UTF-8
ENV INSTALL_PATH /app/
ENV app /app/


# Dependencies
RUN \
  # update packages
  apk update && \
  apk upgrade && \
  apk --no-cache add make g++ && \
  apk --no-cache add ruby ruby-dev ruby-bundler ruby-json ruby-rake ruby-bigdecimal && \
  apk --no-cache add git && \
  apk --no-cache add libressl-dev && \

  # clear after installation
  rm -rf /var/cache/apk/*

# Change to INSTALL_PATH and install base packages
RUN mkdir -p                        $INSTALL_PATH
WORKDIR                             $INSTALL_PATH
ADD Gemfile                         $INSTALL_PATH
ADD rest-ftp-daemon.gemspec 	    	$INSTALL_PATH

# Prepare bundler
RUN gem install bundler && bundle config git.allow_insecure true && bundle install --system --without="development test" -j4

# Install app code
ADD . $INSTALL_PATH

# App run
EXPOSE 3000
CMD ["bundle", "exec", "bin/rest-ftp-daemon", "-e", "docker", "-c", "/config.yml", "-f", "start"]
