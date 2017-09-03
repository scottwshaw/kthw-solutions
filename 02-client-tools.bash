#!/bin/bash
# No set -e since errors if tools already installed by homebrew

# Instead of sudoing my local machine as in tutorial, use homebrew to install cloudflare
echo cfssl should be version 1.2.0 or greater
brew install cfssl

echo kubectl should be version 1.7.4 or greater

brew install kubectl

kubectl version --client
