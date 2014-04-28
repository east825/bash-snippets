#!/usr/bin/env bash
# vim: ft=sh

set -e

PROG_NAME="$(basename $0)"

DEBUG=true
if [[ -n "$DEBUG" ]]; then
    set -x
    TEMP_DIR="tmp"
    mkdir -p "$TEMP_DIR"
else
    TEMP_DIR="$(mktemp -d --suffix=$PROG_NAME)" 
fi

USAGE="\
Usage:
    $PROG_NAME [--self-signed|--CA|--signed-by CERT KEY] NAME

Options:
    -C, --country COUNTRY               Country (C) field. Two letter code. [default: RU]
    --ST, --state STATE                 State (S) field [default: St.Petersburg]
    -L, --locality LOCALITY             Locality (L) field. [default: St.Petersburg]
    -O, --organization ORGANIZATION]    Organization (O) field. [default: JetBrains]
    --OU, --organizational-unit UNIT    Organizational unit field. [default: Certificates Tests]
    --CN, --common-name NAME            Common name (CN) field. Mandatory field.
    --email EMAIL                       Email specified in certificate. [default: mikhail.golubev@jetbrains.com]

    --start-date DATE                   End date of certificate legibility in format YYYYMMDDHHMMSSZ.
    --end-date DATE                     Start date of certificate legibility in format YYYYMMDDHHMMSSZ.
                                        These options are useful for generating expired certificates.

    --self-signed                       Generate self-signed certificate.
    --CA                                Generate self-signed certificate authority.
    --signed-by CERT KEY                Generate certificate signed by authority specified by certificate
                                        and private key pair.
                                        If neither of modes specified generated certificate will be signed
                                        by system default authority.

    --pkcs12                            Export genearated certificate/key pair in PKCS12 format (.p12)

Arguments:
    NAME                                Name of output certificate, private key or CSR without extension.

Example:
    ${PROG_NAME} --pkcs12 --signed-by root.crt root.key --CN client.unit-371 --OU 'Client Authentication' client-auth
"

COUNTRY="RU"
STATE="St.Petersburg"
LOCALITY="St.Petersburg"
ORGANIZATION="JetBrains"
ORGANIZATIONAL_UNIT="Certificates Tests"
EMAIL="mikhail.golubev@jetbrains.com"

MODE="default"

if [[ -n "$DEBUG" ]]; then
    DEFAULT_KEY_LENGTH=1024
else
    DEFAULT_KEY_LENGTH=8192
fi
DEFAULT_PERIOD=3650 # days

error() {
    echo "Error: $1" >&2
    exit 2
}

message() {
    echo ">> $1"
}

debug() {
    if [[ -n "$DEBUG" ]]; then
        cat
    else
        cat &>/dev/null
    fi
}

while (( $# > 0 )); do
    case "$1" in 
        -h|--help)
            echo "$USAGE"; exit;; 
        -C|--country) 
            COUNTRY="${2:? Error: Country expected}"; shift 2;;
        -L|--locality)
            LOCALITY="${2:? Error: Locality expected}"; shift 2;;
        --ST|--state)
            STATE="${2:? Error: State expected}"; shift 2;;
        -O|--organization)
            ORGANIZATION="${2:? Error: Organization expected}"; shift 2;;
        --OU|--organizational-unit)
            ORGANIZATIONAL_UNIT="${2:? Error: Organizational unit expected}"; shift 2;;
        --CN|--common-name)
            COMMON_NAME="${2:? Error: Common name (domain pattern) expected}"; shift 2;;
        --email)
            EMAIL="${2:? Error: Email expected}"; shift 2;;
        --start-date)
            START_DATE="${2:? Error: Start date expected}"; shift 2;;
        --end-date)
            END_DATE="${2:? Error: End date expected}"; shift 2;;
        --self-signed)
            MODE="self-signed"; shift;;
        --pkcs12)
            PKCS12=true; shift;;
        --CA)
            MODE="CA"; shift;;
        --signed-by)
            MODE="signed"
            shift
            if (( $# < 2 )); then
                error "CA should be set as pair path/to/certificate.crt path/to/key.key"
            fi
            CA_CERTIFICATE="$1"
            CA_KEY="$2"
            shift 2;;
        -*)
            error "Unknown option: $1";;
        *)  
            # positionals next
            break;;
    esac
done

if [[ $# == 0 || -z "$1" ]]; then
    error "Result file is mandatory"
fi
# Strip possible extension
NAME="${1%.*}"

if [[ -z "$COMMON_NAME" ]]; then
    error "Common name is mandatory"
fi

if [[ "$MODE" == "signed-by" ]]; then
    [[ ! -r "$CA_CERTIFICATE" ]] && error "Cannot read CA certificate"
    [[ ! -r "$CA_KEY" ]] && error "Cannot read CA private key"
fi

SERIAL_FILE="${TEMP_DIR}/serial.srl"
RAND_FILE="${TEMP_DIR}/rand"
INDEX_FILE="${TEMP_DIR}/index.txt"

CONFIG="\
[ ca ]
default_ca      = CA_default           # The default ca section

[ CA_default ]

dir            = ${TMP_DIR}            # top dir
database       = ${INDEX_FILE}         # index file.
new_certs_dir  = .                     # new certs dir

certificate    = ${CA_CERTIFICATE}     # The CA cert
serial         = ${SERIAL_FILE}        # serial no file
private_key    = ${CA_KEY}             # CA private key
RANDFILE       = ${RAND_FILE}          # random number file

default_days   = ${DEFAULT_PERIOD}     # how long to certify for
default_crl_days= 30                   # how long before next CRL
default_md     = sha512                # md to use

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

[ req ]
default_bits           = ${DEFAULT_KEY_LENGTH}
distinguished_name     = req_distinguished_name
default_keyfile        = ${NAME}.key
prompt                 = no

[ req_distinguished_name ]
C                      = ${COUNTRY}
ST                     = ${STATE}
L                      = ${LOCALITY}
O                      = ${ORGANIZATION}
OU                     = ${ORGANIZATIONAL_UNIT}
CN                     = ${COMMON_NAME}
# emailAddress           = ${EMAIL}

[ v3_ca ]

subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer:always
basicConstraints = CA:true
"


# May be specified instead of config file
# SUBJECT="C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${ORGANIZATIONAL_UNIT}/CN=${COMMON_NAME}/emailAddress=${EMAIL}"


message "Writing stub config to config.cfg"
echo "$CONFIG" > config.cfg

if [[ ! -e "$SERIAL_FILE" || -z "$DEBUG" ]]; then
    echo "1000" > "$SERIAL_FILE"
fi

if [[ ! -e "$INDEX_FILE" || -z "$DEBUG" ]]; then
    > "$INDEX_FILE"
fi

if [[ ! -e "$RAND_FILE" || -z "$DEBUG" ]]; then
    > "$RAND_FILE"
fi

if [[ "$MODE" == "self-signed" ]]; then
    message "Generating self-signed certificate for ${COMMON_NAME}..."
    openssl req -verbose -x509 -nodes -sha512 -newkey rsa:${DEFAULT_KEY_LENGTH} \
        -days "$DEFAULT_PERIOD" \
        -config "config.cfg" \
        -keyout "${NAME}.key" -out "${NAME}.crt" 2>&1 | debug

elif [[ "$MODE" == "CA" ]]; then
    message "Generating certificate authority for ${COMMON_NAME}..."
    openssl req -verbose -x509 -nodes -sha512 -newkey rsa:${DEFAULT_KEY_LENGTH} \
        -days "$DEFAULT_PERIOD" \
        -extensions v3_ca \
        -config "config.cfg" \
        -keyout "${NAME}.key" -out "${NAME}.crt" 2>&1 | debug

else
    message "Generating CSR for ${COMMON_NAME}..."
    openssl req -verbose -nodes -newkey rsa:${DEFAULT_KEY_LENGTH} \
        -config "config.cfg" \
        -keyout "${NAME}.key" -out "${NAME}.csr" 2>&1 | debug
    if [[ "$MODE" == "default" ]]; then
        message "Using default CA to sign CSR..."
        openssl ca -md sha512 -verbose -notext \
            ${START_DATE:+ -startdate $START_DATE} ${END_DATE:+ -enddate $END_DATE} \
            -infiles "${NAME}.csr" -out "${NAME}.crt" 2>&1 | debug
    else 
        message "Using CA ${CA_CERTIFICATE} to sign CSR..."
        # Alternative variant. Simpler, but not so versatile.
        # yes | openssl x509 -req \
            # -CA "$CA_CERTIFICATE" -CAkey "$CA_KEY" -CAserial serial.srl \
            # -in "${NAME}.csr" -out "${NAME}.crt"
        yes | openssl ca -md sha512 -verbose -notext -config config.cfg \
            ${START_DATE:+ -startdate $START_DATE} ${END_DATE:+ -enddate $END_DATE} \
            -out "${NAME}.crt" -infiles "${NAME}.csr" 2>&1 | debug
    fi
fi    

if [[ -n "$PKCS12" ]]; then
    message "Exporting PKCS #12 archive ${NAME}.p12..."
    openssl pkcs12 -export -in "${NAME}.crt" -inkey "${NAME}.key" -out "${NAME}.p12"
fi

if [[ -z "$DEBUG" ]]; then    
    rm -rf "$TEMP_DIR"
    rm -rf *.csr
fi

