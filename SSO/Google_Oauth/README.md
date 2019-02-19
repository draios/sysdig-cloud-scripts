# Configure Google OAUTH

Remember to fill out your environment URL and the Monitor or Secure API token at `../env.sh`. Depending on which API token you choose, the script will configure the settings for one or the other product.

## Examples

Show command help

```
./google_oauth_config.sh --help
```

Get current configuration

```
./google_oauth_config.sh
```

Configure some settings

```
./google_oauth_config.sh --set --clientid "foobar.apps.googleusercontent.com" --clientsecret "foobar" -r "https://sysdig.example.org:443/api/oauth/google/auth" --alloweddomains "[\"yourdomain.com\"]"

```

Delete current settings:

```
./google_oauth_config.sh --delete
```
