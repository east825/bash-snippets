#!/usr/bin/env bash
set -e

COUNTRY="RU" # 2-letter code
STATE="Russia"
LOCATION="St.Petersburg"

CA_ORGANIZATION="Trackers Test"
CA_UNIT="Certificate Authority"
CA_DOMAIN="trackers-tests.labs.intellij.net"

EXPIRED_SUBDOMAIN="expired"
EXPIRED_UNIT="Expired Certificate Test"

SELF_SIGNED_SUBDOMAIN="self-signed"
SELF_SIGNED_UNIT="Self-signed Certificate Test"

TRUSTED_SUBDOMAIN="trusted"
TRUSTED_UNIT="Trusted Certificate Signed by CA Test"

WRONG_HOSTNAME_SUBDOMAIN="wrong-hostname"
WRONG_HOSTNAME_UNIT="Certificate with Wrong Hostname Test"

CONFIG="\
[ ca ]
default_ca      = CA_default            # The default ca section

[ CA_default ]

dir            = ./tmp                 # top dir
database       = \$dir/index.txt       # index file.
new_certs_dir  = \$dir                 # new certs dir

certificate    = ca.crt                # The CA cert
serial         = \$dir/serial          # serial no file
private_key    = ca.key                # CA private key
RANDFILE       = \$dir/.rand           # random number file

default_days   = 3650                  # how long to certify for
default_crl_days= 30                   # how long before next CRL
default_md     = md5                   # md to use

policy         = policy_any            # default policy
email_in_dn    = no                    # Don't add the email into cert DN

name_opt       = ca_default            # Subject name display option
cert_opt       = ca_default            # Certificate display option
copy_extensions = none                 # Don't copy extensions from request

[ policy_any ]
countryName            = supplied
stateOrProvinceName    = optional
organizationName       = optional
organizationalUnitName = optional
commonName             = supplied
emailAddress           = optional
"

generate() {
    local domain="${1:?domain name not specified}"
    local org_unit="${2:-Certificate Tests}"
    # in YYMMDDHHMMSSZ format
    local start_date="$3"
    local end_date="$4"
    local common_name="${domain}.${CA_DOMAIN}"

    echo "Generating CSR for $common_name..."
    openssl req -nodes -newkey rsa:2048 \
        -keyout "${domain}.key" -out "${domain}.csr" \
        -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCATION}/O=${CA_ORGANIZATION}/OU=${org_unit}/CN=${common_name}" &>/dev/null
    echo "Signing certificate for $common_name by CA..."
    # can also set CA credential explicitly by -cert ca.crt -keyfile ca.key
    yes | openssl ca -verbose -notext -config config.txt \
        ${start_date:+ -startdate $start_date} ${end_date:+ -enddate $end_date} \
        -out "${domain}.crt" -infiles "${domain}.csr" &>/dev/null
}

generate-self-signed() {
    local domain="${1:?domain name not specified}"
    local org_unit="${2:-Certificate Tests}"
    local common_name="${domain}.${CA_DOMAIN}"

    echo "Generating self-signed certificate for $common_name..."
    openssl req -x509 -nodes -newkey rsa:2048 -config config.txt \
        -keyout "${domain}.key" -out "${domain}.crt" \
        -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCATION}/O=${CA_ORGANIZATION}/OU=${org_unit}/CN=${common_name}" &>/dev/null
}

cleanup() {
    if [[ -d tmp ]]; then
        rm -rf tmp
    fi
    if [[ -e config.txt ]]; then
        rm config.txt
    fi
}

echo "Cleaning up..."
cleanup
echo "Creating OpenSSL configuration..."
echo "$CONFIG" > config.txt
mkdir -p tmp
echo 1000 > tmp/serial
touch tmp/index.txt
touch tmp/.rand

echo "Generating CA..."
# generate private key separately
# openssl genrsa -out ca.key 8192
openssl req -new -x509 -extensions v3_ca -nodes -newkey rsa:2048 \
    -keyout ca.key -out ca.crt \
    -days 3650 \
    -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCATION}/O=${CA_ORGANIZATION}/OU=${CA_UNIT}/CN=${CA_DOMAIN}" &>/dev/null

echo ">> Generating certificate signed by CA..."
generate "$TRUSTED_SUBDOMAIN" "$TRUSTED_UNIT"

echo ">> Generating expired certificate signed by CA..."
generate "$EXPIRED_SUBDOMAIN" "$EXPIRED_UNIT" 20000101000000Z 20010101000000Z

echo ">> Generating certificate signed by CA with wrong hostname..."
generate "$WRONG_HOSTNAME_SUBDOMAIN" "$WRONG_HOSTNAME_UNIT"

echo ">> Generating self-signed certificate..."
generate-self-signed "$SELF_SIGNED_SUBDOMAIN" "$SELF_SIGNED_UNIT"


# rm config.txt
# rm -rf tmp




 
