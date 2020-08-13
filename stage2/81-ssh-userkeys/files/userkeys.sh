#!/bin/bash
export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
curl -sf https://SSH_KEYS_SERVER/users/$1/keys
