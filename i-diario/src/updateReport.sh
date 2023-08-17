#!/bin/bash
cd /app
bundle exec rake refresh_pedagogical_tracking_views
bundle exec rake ieducar_api:synchronize
