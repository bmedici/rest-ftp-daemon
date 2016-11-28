# Docker headers
FROM ruby:2.3.0-slim
MAINTAINER Bruno MEDICI <rest-ftp-daemon@bmconseil.com>


# Install packages
RUN apt-get update && apt-get install -qq -y build-essential --fix-missing --no-install-recommends


# Environment
ENV LANG=C.UTF-8


# Install app gem
RUN gem install rest-ftp-daemon --no-rdoc --no-ri


# App run
EXPOSE 3000
CMD ["./bin/rest-ftp-daemon", "-p", "3000", "-f", "start"]
