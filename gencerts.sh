#!/usr/bin/env bash
set -e

CA_UNIT="Certificate Authority"
CA_DOMAIN="${1:-certificates-tests.labs.intellij.net}"

EXPIRED_SUBDOMAIN="expired"
EXPIRED_UNIT="Expired Certificate Test"

SELF_SIGNED_SUBDOMAIN="self-signed"
SELF_SIGNED_UNIT="Self-signed Certificate Test"

TRUSTED_SUBDOMAIN="trusted"
TRUSTED_UNIT="Trusted Certificate Signed by CA Test"

WRONG_HOSTNAME_SUBDOMAIN="illegal"
WRONG_HOSTNAME_UNIT="Certificate With Wrong Hostname Test"

CLIENT_AUTH_SUBDOMAIN="client-auth"
CLIENT_AUTH_UNIT="Client Authentication Tests" 

echo ">> Generating CA..."
./gencert.sh --keep --CA --OU "$CA_UNIT" --CN "$CA_DOMAIN" ca 

echo ">> Generating certificate signed by CA..."
./gencert.sh --keep --signed-by ca.crt:ca.key --OU "$TRUSTED_UNIT" \
    --CN "${TRUSTED_SUBDOMAIN}.${CA_DOMAIN}" "$TRUSTED_SUBDOMAIN"

echo ">> Generating expired certificate signed by CA..."
./gencert.sh --keep --signed-by ca.crt:ca.key --OU "$EXPIRED_UNIT" \
    --start-date 20010101000000Z --end-date 20000101000000Z \
    --CN "${EXPIRED_SUBDOMAIN}.${CA_DOMAIN}" "$EXPIRED_SUBDOMAIN"

echo ">> Generating certificate signed by CA with wrong hostname..."
./gencert.sh --keep --signed-by ca.crt:ca.key --OU "$WRONG_HOSTNAME_UNIT" \
    --CN "${WRONG_HOSTNAME_SUBDOMAIN}.${CA_DOMAIN}" wrong-hostname

echo ">> Generating self-signed certificate..."
./gencert.sh --keep --self-signed --OU "$SELF_SIGNED_UNIT" \
    --CN "${SELF_SIGNED_SUBDOMAIN}.${CA_DOMAIN}" "$SELF_SIGNED_SUBDOMAIN"

echo ">> Generating certificate signed by CA for client authentication..."
./gencert.sh --keep --signed-by ca.crt:ca.key --OU "$CLIENT_AUTH_UNIT" \
    --CN "${CLIENT_AUTH_SUBDOMAIN}.${CA_DOMAIN}" "$CLIENT_AUTH_SUBDOMAIN"

echo ">> Generating client certificate..."
./gencert.sh --keep --pkcs12 --signed-by ca.crt:ca.key --OU "User certificate used for client authentication" \
    --CN "user@${CLIENT_AUTH_SUBDOMAIN}.${CA_DOMAIN}" user






