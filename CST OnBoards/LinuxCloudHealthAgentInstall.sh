#!/bin/bash
#Download CloudHealth Agent
wget https://s3.amazonaws.com/remote-collector/agent/v18/install_cht_perfmon.sh -O /tmp/install_cht_perfmon.sh;

#Install CloudHealth Agent
sudo sh /tmp/install_cht_perfmon.sh 18 <API_Key> azure;