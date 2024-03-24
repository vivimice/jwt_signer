# jwt_signer

`jwt_signer` is a Lua hook script implemented for the Apache2 HTTP server. Its function is to compute the JWT's (JSON Web Tokens) signature section based on the header and payload portion received from the client. After assembling a complete JWT, it places it into the 'Authorization' header, and subsequently passes it along to the next Apache2 module.

# Quick Start

## Installation

To clone the repository and install jwt_signer, run:

```sh
git clone https://github.com/vivimice/jwt_signer.git
cd jwt_signer
sudo ./install.sh
```

## Configure

```apache
LuaHookAuthChecker /usr/local/lib/jwt_signer/jwt_signer.lua sign
SetEnvIf Host .*   JWT_SIGNER_SECRET=your-256-bit-secret
```

Replacing `your-256-bit-secret` with the shared secret between parties.

## Activation

Finally, to enable necessary modules, check the updated configuration, and reload your Apache2 instance for the changes to take effect, use the following commands:

```sh
sudo a2enmod lua setenvif
sudo apache2ctl configtest && sudo apache2ctl graceful
```

# Security Consideration

To avoid the unintended exposure of the secret used for signing the JWT token, ensure that the configuration file containing the `SetEnv-If` directive is not accessible by any unnecessary user on the server.

# Acknowledgments 

I would like to express my gratitude to [Egor Skriptunoff](https://github.com/Egor-Skriptunoff/) for creating the [`pure_lua_SHA`](https://github.com/Egor-Skriptunoff/pure_lua_SHA) library that plays a crucial role in the development of jwt_signer. I am truly thankful for the hard work and the open-source nature of the library, which has allowed me to build upon their foundation and achieve my project's objectives.
