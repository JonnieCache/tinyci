FROM ruby:2.6.3-alpine3.9

RUN apk add --no-cache \
  build-base \
  git

RUN git config --global user.email "you@example.com"
RUN git config --global user.name "Your Name"

WORKDIR /tmp 
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
ADD tinyci.gemspec tinyci.gemspec
ADD lib/tinyci/version.rb lib/tinyci/version.rb
ADD lib/tinyci/logo.txt lib/tinyci/logo.txt

RUN gem update bundler

RUN bundle install --no-cache --jobs=4

ADD . /tinyci

WORKDIR /tinyci

CMD bin/tinyci
