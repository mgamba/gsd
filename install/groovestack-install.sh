#!/usr/bin/env bash
cd $3;

echo "⚡️ Groovestack App Setup Complete";

bin/rails app:template LOCATION=$2/groovestack-rails-template.rb;