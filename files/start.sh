#!/bin/bash

# Fail fast, including pipelines
set -e -o pipefail

# Set LOGSTASH_TRACE to enable debugging
[[ $LOGSTASH_TRACE ]] && set -x

# If you don't provide a value for the LOGSTASH_CONFIG_URL env
# var, your install will default to our very basic logstash.conf file.
#
LOGSTASH_DEFAULT_CONFIG_URL='https://gist.githubusercontent.com/shift/cd6dc5b83e889b634584/raw/05c1e07fe28a4a16c0cac8a288c022f3a6afb825/logstash-2.1.conf'
LOGSTASH_CONFIG_URL=${LOGSTASH_CONFIG_URL:-${LOGSTASH_DEFAULT_CONFIG_URL}}

LOGSTASH_SRC_DIR='/srv/logstash'

LOGSTASH_CONFIG_DIR="${LOGSTASH_SRC_DIR}/config"
LOGSTASH_CONFIG_FILE="${LOGSTASH_CONFIG_DIR}/logstash.conf"

LOGSTASH_BINARY="${LOGSTASH_SRC_DIR}/bin/logstash"

LOGSTASH_LOG_DIR='/var/log/logstash'
LOGSTASH_LOG_FILE="${LOGSTASH_LOG_DIR}/logstash.log"

# Create the logstash conf dir if it doesn't already exist
#
function logstash_create_config_dir() {
    local config_dir="$LOGSTASH_CONFIG_DIR"

    if ! mkdir -p "${config_dir}" ; then
        echo "Unable to create ${config_dir}" >&2
    fi
}

# Download the logstash config if the config directory is empty
#
function logstash_download_config() {
    local config_dir="$LOGSTASH_CONFIG_DIR"
    local config_file="$LOGSTASH_CONFIG_FILE"
    local config_url="$LOGSTASH_CONFIG_URL"

    if [ ! "$(ls -A $config_dir)" ]; then
        wget "$config_url" -O "$config_file"
    fi
}

function logstash_sanitize_config() {
    local host="${ELASTICSEARCH_PORT_9200_TCP_ADDR:-127.0.0.1}"
    local port="${ELASTICSEARCH_PORT_9200_TCP_PORT:-9200}"

    sed -e "s|ELASTICSEARCH_HOST|${host}|g" \
        -e "s|ELASTICSEARCH_PORT|${port}|g" \
        -i "$LOGSTASH_CONFIG_FILE"
}

function logstash_create_log_dir() {
    local log_dir="$LOGSTASH_LOG_DIR"

    if ! mkdir -p "${log_dir}" ; then
        echo "Unable to create ${log_dir}" >&2
    fi
}

function logstash_start_agent() {
    local binary="$LOGSTASH_BINARY"
    local config_dir="$LOGSTASH_CONFIG_DIR"
    local log_file="$LOGSTASH_LOG_FILE"

    case "$1" in
    # run just the agent
    'agent')
        exec "$binary" \
             agent \
             --config "$config_dir/logstash.conf" \
             --debug \
             --verbose \
             --
        ;;
    # test the logstash configuration
    'configtest')
        exec "$binary" \
             agent \
             --config "$config_dir/logstash.conf" \
             --configtest \
             --
        ;;
      'shell')
        exec /bin/bash
    esac
}


# Set LOGSTASH_TRACE to enable debugging
[[ $LOGSTASH_TRACE ]] && set -x

export SCRIPT_ROOT=$(readlink -f "$(dirname "$0")"/..)

function main() {
  logstash_create_config_dir
  logstash_download_config
  logstash_sanitize_config
  logstash_create_log_dir
  logstash_start_agent "$@"
}

main "$@"
