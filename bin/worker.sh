#!/bin/sh

if [ "$RACK_ENV" != "development" ]; then
  bundle exec rake api:status
else
  echo "Skipping api service in development!!"
  while(true)
  do
    sleep 60m # limits CPU usage
  done
fi
