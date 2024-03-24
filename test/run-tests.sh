#!/bin/bash -e

# Copyright 2024 vivimice@gmail.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cd "$(dirname $0)"
export SCRIPT_ROOT="$(readlink -f ..)"
export CONFIG_ROOT="$(readlink -f .)"
export SERVER_ROOT=/usr/lib/apache2
export SERVER_PORT=28280
export HTTP_USER=foo
export HTTP_PASSWD=bar
export HTTP_REALM=wonderland
export PASSWD_FILE="${CONFIG_ROOT}/var/passwd"

export VAR_ROOT="${CONFIG_ROOT}/var"
rm -rf "${VAR_ROOT}"
mkdir -p "${VAR_ROOT}" || true

CONFIG_FILE="${CONFIG_ROOT}/var/apache2.conf"

echo "Generating mime types ..."
echo "text/html					html htm shtml" > "${VAR_ROOT}/mime.types"

echo "Generating password file: ${PASSWD_FILE} ..."
printf "%s:%s:%s\n" "${HTTP_USER}" "${HTTP_REALM}" "$(printf "%s:%s:%s" "${HTTP_USER}" "${HTTP_REALM}" "${HTTP_PASSWD}" | md5sum | awk '{print $1}')" > "${PASSWD_FILE}"

echo "Generating configuration file: ${CONFIG_FILE} ..."
envsubst < "${CONFIG_ROOT}/apache2.conf" > "${CONFIG_FILE}"

echo "Starting apache2 at port ${SERVER_PORT} ..."
_cleanExit() {
    kill "${APACHE2_PID}"
    exit 1
}
trap "_cleanExit" EXIT
/usr/sbin/apache2 -D FOREGROUND -d "${SERVER_ROOT}" -f "${CONFIG_FILE}" -X 2>&1 &
APACHE2_PID=$!

echo "Running test cases ..."

if ! curl -vs "http://localhost:${SERVER_PORT}/?case=1" \
        -H "X-JwtSigner-Msg: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ" \
        -o /dev/null 2>&1 | grep "HTTP/1.1 401 " >/dev/null; then
    echo "Test [no_auth] failed. should return 401."
    exit 1
fi

if ! curl -vs --digest "http://${HTTP_USER}:${HTTP_PASSWD}@localhost:${SERVER_PORT}/?case=2" \
        -H "X-JwtSigner-Msg: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ" \
        2>&1 | grep "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c" >/dev/null; then
    echo "Test [digest_auth] failed. should return correct Bearer text."
    exit 1
fi

if ! curl -vs --digest "http://${HTTP_USER}:${HTTP_PASSWD}@localhost:${SERVER_PORT}/?case=3" \
        2>&1 | grep -v "Bearer " >/dev/null; then
    echo "Test [digest_auth_without_header] failed. should not return Bearer text."
    exit 1
fi

echo "Test success."
