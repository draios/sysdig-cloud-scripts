# Configure LDAP auth

Remember to fill out your environment URL and the Monitor or Secure API token at `../env.sh`. Depending on which API token you choose, the script will configure the settings for one or the other product.

## Examples

Show command help

```
./login_config.sh --help
```

Get current configuration

```
./login_config.sh
```

Configure some default LDAP login following existing example

```
./login_config.sh --set settings_login_simple.json

```

Delete current settings:

```
./login_config.sh --delete
```
