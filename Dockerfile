FROM alpine:3.8

RUN mkdir -p /etc \
  && { \
    echo 'install: --no-document'; \
    echo 'update: --no-document'; \
  } >> /etc/gemrc

RUN apk add --no-cache -u \
  ruby \
  ruby-dev \
  ruby-irb \
  ruby-etc \
  libffi-dev \
  build-base \
  git

RUN git config --global user.email "you@example.com"
RUN git config --global user.name "Your Name"

# RUN ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime

RUN gem install bundler
RUN bundle config --global silence_root_warning 1

WORKDIR /tmp 
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
ADD tinyci.gemspec tinyci.gemspec
ADD lib/tinyci/version.rb lib/tinyci/version.rb
ADD lib/tinyci/logo.txt lib/tinyci/logo.txt
RUN bundle install 

ADD . /tinyci

WORKDIR /tinyci

CMD bin/tinyci
