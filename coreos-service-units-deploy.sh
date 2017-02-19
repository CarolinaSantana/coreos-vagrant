#!/bin/bash

sudo cp share/etc/sysctl/* /etc/systemd/system/

sudo systemctl enable volume-public.service
sudo systemctl enable postgresql.service
sudo systemctl enable app-job.service
sudo systemctl enable app-task.service
sudo systemctl enable nginx.service

sudo systemctl start volume-public.service
sudo systemctl start postgresql.service
sudo systemctl start app-job.service
sudo systemctl start app-task.service
sudo systemctl start nginx.service

