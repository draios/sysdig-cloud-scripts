# Configure OpenID auth

Remember to fill out your environment URL and the Monitor or Secure API token at `../env.sh`. Depending on which API token you choose, the script will configure the settings for one or the other product.

## Examples

Show command help

```
./oidc_config.sh --help
```

Get current configuration

```
./oidc_config.sh
```

Configure some settings

```
./oidc_config.sh --set --issuerurl https://foo.oktapreview.com --clientid foobar --clientsecret foobar

```

Delete current settings:

```
./oidc_config.sh --delete
```
