# ===============================================================
# Rails container for Nabu application
# - uses volumes for bundler and gem cache
# - uses entrypoint script to handle bundling and starting Solr
# =============================================================== 

FROM ruby:2.3.8

ENV BUNDLE_PATH /bundler
ENV BUNDLE_HOME /gems

ENV GEM_HOME /gems
ENV GEM_PATH /gems

ENV PATH /gems/bin:$PATH


RUN apt-get update
RUN apt-get install -y \
  net-tools \
  ruby-kgio \
  git-core \
  curl \
  zlib1g-dev \
  build-essential \
  libssl-dev \
  libreadline-dev \
  libyaml-dev \
  libsqlite3-dev \
  sqlite3 \
  libxml2-dev \
  libxslt1-dev \
  libcurl4-openssl-dev \
  software-properties-common \
  libffi-dev \
  nodejs \
  libmagic-dev \
  openjdk-8-jre \
  phantomjs

RUN gem install bundler

# Fix wierd phantmJS bug
ENV QT_QPA_PLATFORM offscreen

VOLUME /app
WORKDIR /app

CMD ./entrypoint.sh

