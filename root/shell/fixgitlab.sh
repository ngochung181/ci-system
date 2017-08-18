#!/bin/bash
gitlab-ctl stop 
echo "  unicorn['port'] = 8081"  >> /etc/gitlab/gitlab.rb
gitlab-ctl reconfigure 
gitlab-ctl restart 

