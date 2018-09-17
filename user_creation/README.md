# User creation via API

The typical workflow for creating users in the Sysdig platform is via [email invite](https://sysdigdocs.atlassian.net/wiki/spaces/Platform/pages/206405831/Manage+Users). However, [on-premises deployments](https://sysdigdocs.atlassian.net/wiki/spaces/Platform/pages/13598894/On-Premises+Deployments) may also choose to use the Sysdig platform API to directly create user records and set an initial password.

The `create_user.sh` helper script in this directory will assist you in hitting the correct API endpoints to:

1. Enable/disable the ability to create users via the API (this ability is enabled by default)
2. Create user records via the API

Access to the API endpoints needed to run `create_user.sh` is only permitted by the ["super" Admin](https://sysdigdocs.atlassian.net/wiki/spaces/Platform/pages/206569685/Access+the+Super+Admin+User+Token) for your environment. To prepare, modify `env.sh` to set the required values for the `API_TOKEN` of the "super" Admin user, the URL for accessing the Sysdig platform API (which will be the same URL that your users access for the Sysdig Monitor application), and review the `CUSTOMER_ID` setting (which should be `1`, but confirm this via the steps described in [Find Your Customer Number](https://sysdigdocs.atlassian.net/wiki/spaces/Platform/pages/208994483/Find+Your+Customer+Number)).

# Usage examples:

To see usage information:

```
# ./create_user.sh --help
Usage: ./create_user.sh [OPTION]

Create a user record, or change permissions for API-based user creation

If no OPTION is specified, the current API User Creation settings are printed

General options:
  -h | --help             Print this Usage output

Options for changing permissions:
  -e | --enable           Enable API-based user creation (it's enabled by default)
  -d | --disable          Disable API-based user creation

Options for creating a user record:
  -u | --username         Username for the user record to create
  -p | --password         Password for the user record to create
  -f | --firstname        (optional) First name for the user record to create
  -l | --lastname         (optional) Last name for the user record to create
```

To see whether user creation is currently enabled/disabled, invoke with no options:

```
# ./create_user.sh
{
    "apiPermissionSettings": {
        "allowApiUserCreation": true,
        "version": 1
    }
}
```

To create a user record, at minimum, you must specify a username and password. The username should be a valid email address, unless you have LDAP authentication enabled in which case a simple username is also permitted. If successful, the call to the API will echo back a JSON object for the successfully-created user.

```
# ./create_user.sh -u jdoe@example.local -p JoeInitPasswd
{"user":{"termsAndConditions":true, ... ,"username":"jdoe@example.local","dateCreated":1536878606750,"status":"confirmed","systemRole":"ROLE_USER"}}
```

Optional parameters to specify a first name and/or last name for the user record are also available.

```
# ./create_user.sh -u msmith@example.local -p MsmithInitPasswd -f Mary -l Smith
{"user":{"termsAndConditions":true, ... ,"username":"msmith@example.local","dateCreated":1536878724933,"status":"confirmed","systemRole":"ROLE_USER","firstName":"Mary","lastName":"Smith"}}
```

To disable the ability to create users via the API:

```
# ./create_user.sh -d
{
    "apiPermissionSettings": {
        "allowApiUserCreation": false,
        "version": 2
    }
}

# ./create_user.sh -u failure@example.local -p ThisWontWork
{"errors":[{"reason":"Cannot add user","message":"User API creation is not enabled"}]}
```

To re-enable the ability to create users via the API:

```
# ./create_user.sh -e
{
    "apiPermissionSettings": {
        "allowApiUserCreation": true,
        "version": 3
    }
}
```
