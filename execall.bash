#!/bin/bash
set -e

. ./03-compute-resources.bash
. ./04-certificate-authority.bash
. ./05-kubernetes-configuration-files.bash
. ./06-data-encryption-keys.bash
. ./07-bootstrapping-etcd.bash
. ./08-bootstrapping-kubernetes-controllers.bash
