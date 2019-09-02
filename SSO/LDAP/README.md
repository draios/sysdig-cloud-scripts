# Configure LDAP auth

Remember to fill out your environment URL and the Monitor or Secure API token at `../env.sh`. Depending on which API token you choose, the script will configure the settings for one or the other product.

## Examples

Show command help

```
./login_config.sh -h
```

Get current configuration

```
./login_config.sh
```

Configure some default LDAP login following existing example

```
./login_config.sh -s settings_login_simple.json

```

Delete current settings:

```
./login_config.sh -d
```

Once settings have been set, information existing at LDAP tree regarding an existing user can be retrieved:

Show command help

```
./ verify_user.sh -h
```

Get user information (test LDAP configuration)

```
./verify_user.sh -u john.doe
```
