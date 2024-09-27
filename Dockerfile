# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.3.3
FROM registry.docker.com/library/ruby:$RUBY_VERSION-alpine3.20 as base

# Rails app lives here
WORKDIR /usr/dev

# gcompat is for nokogiri
RUN apk update && apk upgrade --no-cache && apk add \
  build-base \
  vips \
  postgresql16-dev \
  sqlite-dev \
  tzdata \
  git \
  yarn \
  gcompat \
  vim \
  postgresql-client \
  npm \

