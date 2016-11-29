# Docker headers
FROM ruby:2.3.0-slim
MAINTAINER Bruno MEDICI <rest-ftp-daemon@bmconseil.com>
ENV LANG=C.UTF-8


# Install packages, and first app gem for caching history only
RUN apt-get update && apt-get install -y build-essential git --fix-missing --no-install-recommends
RUN gem install rest-ftp-daemon -v 0.400.0 --no-rdoc --no-ri


# Retry a gem install to get newer releases, if Gemfile.lock changed
ADD Gemfile.lock /dev/null
RUN gem install rest-ftp-daemon --no-rdoc --no-ri
# RUN rest-ftp-daemon -v


# App run
EXPOSE 3000
CMD ["/usr/local/bundle/bin/rest-ftp-daemon", "-p", "3000", "-d", "start"]

