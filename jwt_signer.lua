-- Copyright 2024 vivimice@gmail.com
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

require 'apache2'

sha2 = require('sha2')
header_name = 'x-jwtsigner-msg'

function sign(r)
    local secret = r.subprocess_env['JWT_SIGNER_SECRET']
    if not secret then
        r:err('JWT_SIGNER_SECRET not set.')
        return apache2.DECLINED
    end

    local message = r.headers_in[header_name]
    r.headers_in[header_name] = nil
    if not message then
        return apache2.DECLINED
    end

    local hex_sign = sha2.hmac(sha2.sha256, secret, message)
    local bin_sign = sha2.hex_to_bin(hex_sign)
    local base64_sign = sha2.bin_to_base64(bin_sign)
    base64_sign = string.gsub(base64_sign, '+', '-')
    base64_sign = string.gsub(base64_sign, '/', '_')
    base64_sign = string.gsub(base64_sign, '=', '')
    r.headers_in['Authorization'] = 'Bearer '..message..'.'..base64_sign
    return apache2.OK
end
