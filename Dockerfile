# Docker headers
FROM ruby:2.3.0-slim
MAINTAINER Bruno MEDICI <rest-ftp-daemon@bmconseil.com>


# Environment
ENV LANG=C.UTF-8
ENV INSTALL_PATH /app/
ENV app /app/


# Install packages, and first app gem for caching history only
RUN apt-get update && apt-get install -y build-essential git --fix-missing --no-install-recommends
RUN gem install bundler --no-rdoc --no-ri


# Change to INSTALL_PATH and install base packages
WORKDIR                             $INSTALL_PATH
ADD Gemfile                         $INSTALL_PATH
ADD Gemfile.lock                    $INSTALL_PATH
ADD rest-ftp-daemon.gemspec 		$INSTALL_PATH
RUN bundle install --system --without="development test" -j4


# Install app code
RUN mkdir -p                        $INSTALL_PATH
ADD . $INSTALL_PATH


# App run
EXPOSE 3000
CMD ["bin/rest-ftp-daemon", "-p", "3000", "-f", "start"]
