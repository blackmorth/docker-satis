#!/usr/bin/env sh
sudo -u www-data sh -c 'id; cd /satisfy && /satisfy/bin/satis build --skip-errors --no-ansi --verbose'
