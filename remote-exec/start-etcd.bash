#!/bin/bash
set -e

sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
