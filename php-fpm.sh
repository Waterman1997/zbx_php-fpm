#!/usr/bin/env bash

################################################################################

APP="php-fpm.sh"
VER="1.0.0"
DESC="Program which provides values for Zabbix agent checks"

################################################################################

# PHP-FPM status page URL availabie via HTTP/HTTPS
ZBX_STATUS_PAGE_URL="http://localhost/php-fpm-status"

# PHP-FPM status format (e.g. json, xml, full). Only json is supported for now.
ZBX_STATUS_PAGE_FORMAT="json"

# Path to cache file to store temporary data
ZBX_STATUS_CACHE_PATH="/var/tmp/zbx-php-fpm.cache"

# Current time in seconds
ZBX_TIME_NOW=$(date '+%s')

# Time To Live (TTL) of cached temporary data in seconds
ZBX_CACHE_TTL=55

################################################################################

# Validates if cache is expired or not
# 
# Code: No
# Echo: No
function isCacheExpired() {
    local timecache

    timecache=0

    if [[ -s "$ZBX_STATUS_CACHE_PATH" ]] ; then
        timecache=$(stat -c "%Y" "$ZBX_STATUS_CACHE_PATH")
    fi

    if [[ "$((ZBX_TIME_NOW - timecache))" -gt "$ZBX_CACHE_TTL" ]] ; then
        echo "ZBX_CACHE_IS_EXPIRED"
    else
        echo "ZBX_CACHE_IS_ACTIVE"
    fi
}

# Updates cache with given temporary status page data
# 
# Code: No
# Echo: No
function updateStatusCache() {
    echo "" > "$ZBX_STATUS_CACHE_PATH"
    payload=$(curl -sL "$ZBX_STATUS_PAGE_URL?$ZBX_STATUS_PAGE_FORMAT") || exit 1
    echo "$payload" > "$ZBX_STATUS_CACHE_PATH"
    chmod 640 "$ZBX_STATUS_CACHE_PATH"
}

# Parses and returns cached data to Zabbix agent by given property name
#
# 1: PropertyName (String)
# 
# Code: No
# Echo: No
function getStatusCachedItem() {
    jq '."'"$1"'"' < "$ZBX_STATUS_CACHE_PATH"
}

# Returns item depending on validity of the cache
#
# 1: PropertyName (String)
# 
# Code: No
# Echo: No
function getStatusItem() {
    local item
    item=$(echo "$1" | sed 's/-/ /g')

    if [[ "$(isCacheExpired)" == "ZBX_CACHE_IS_EXPIRED" ]] ; then
        updateStatusCache
    fi

    result=$(getStatusCachedItem "$item")

    if [[ "$result" == "null" ]] ; then
        echo "ZBX_NOT_SUPPORTED"
    else
        echo "$result"
    fi
}

################################################################################

# Main method
#
# *: All unparsed arguments
# 
# Code: No
# Echo: No
function main() {
    getStatusItem "$1"
}

################################################################################

main "$@"

