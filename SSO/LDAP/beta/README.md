# Configure LDAP auth

Remember to fill out your environment URL and the Monitor or Secure API token at `../../env.sh`. Depending on which API token you choose, the script will configure the settings for one or the other product.

## Examples

Show command help

```
./mapping_config.sh -h
```

Get current configuration

```
./mapping_config.sh
```

Configure users/teams sync settings

```
./mapping_config.sh -s settings_mapping_simple.json

```

Force synchronisation job

```
./mapping_config.sh -f
```

Get last synchronisation report

```
./mapping_config.sh -r
```

Configure users/teams sync settings and force synchronisation after that

```
./mapping_config.sh -f -s settings_mapping_simple.json

```

Delete current settings:

```
./mapping_config.sh -d
```
