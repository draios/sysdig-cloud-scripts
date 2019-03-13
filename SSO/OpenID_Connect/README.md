# Configure OpenID auth

Remember to fill out your environment URL and the Monitor or Secure API token at `../env.sh`. Depending on which API token you choose, the script will configure the settings for one or the other product.

## Examples

Show command help

```
./oidc_config.sh -h
```

Get current configuration

```
./oidc_config.sh
```

Configure some settings

```
./oidc_config.sh -s -u https://foo.oktapreview.com -i foobar -e foobar

```

Delete current settings:

```
./oidc_config.sh -d
```
