#!/bin/bash

# Add cron job for automatic SSL renewal every 90 days
# Runs on the 1st of each quarter at 2:30 AM

CRON_JOB="30 2 1 */3 * /root/projects/reverse-proxy/reverse-proxy/renew-ssl.sh"

# Add to crontab if it doesn't exist
(crontab -l 2>/dev/null | grep -F "$CRON_JOB") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo "Cron job configured for automatic SSL renewal every 90 days"
echo "Running on the 1st of each quarter at 2:30 AM"