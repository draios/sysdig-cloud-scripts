# User creation via API

The typical workflow for creating users in the Sysdig platform is via [email invite](https://docs.sysdig.com/en/docs/administration/administration-settings/user-and-team-administration/manage-users/). However, [on-premises deployments](https://docs.sysdig.com/en/docs/administration/on-premises-deployments/) may also choose to use the Sysdig platform API to directly create user records and set an initial password.

The `create_user.sh` helper script in this directory will assist you in hitting the correct API endpoints to:

1. Enable/disable the ability to create users via the API (this ability is enabled by default)
2. Create user records via the API

Access to the API endpoints needed to run `create_user.sh` is only permitted by the ["super" Admin](https://docs.sysdig.com/en/docs/administration/on-premises-deployments/find-the-super-admin-credentials-and-api-token/) for your environment. To prepare, modify `env.sh` to set the required values for the `API_TOKEN` of the "super" Admin user, the URL for accessing the Sysdig platform API (which will be the same URL that your users access for the Sysdig Monitor application), and review the `CUSTOMER_ID` setting (which should be `1`, but confirm this via the steps described in [Find Your Customer Number](https://docs.sysdig.com/en/docs/administration/administration-settings/find-your-customer-id-and-name/)).

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

# Change Default User Role in Team via API

The `update_default_user_role.sh` helper script in this directory will assist you in hitting the correct API endpoints to:

1. Display information about the available user roles and teams
2. Change the user role assigned by default to users in a team

To prepare, modify `env.sh` to set the required values for the `API_TOKEN` of the Admin user, the URL for accessing the Sysdig platform API (which will be the same URL that your users access for the Sysdig Monitor application).

# Usage examples:

To see usage information:

```
# ./update_default_user_role.sh --help
Usage: ./update_default_user_role.sh [OPTIONS]

Update the default user role for the specified team

If no OPTION is specified, available user roles and teams are displayed

General options:
  -h | --help             Print this Usage output

Options for updating a team:
  -t | --team             Team name
  -r | --role             Default user
```

To display information about user roles and teams:

```
# ./update_default_user_role.sh User roles:

Team Manager      ROLE_TEAM_MANAGER
Advanced User     ROLE_TEAM_EDIT
Standard User     ROLE_TEAM_STANDARD
View only         ROLE_TEAM_READ
Service Manager   ROLE_TEAM_SERVICE_MANAGER

Team names and current default user roles:

Monitor Operations          ROLE_TEAM_EDIT
Secure Operations           ROLE_TEAM_EDIT
Second team                 ROLE_TEAM_EDIT
Third team                  ROLE_TEAM_EDIT
```

To update the default user role for a given team
```
# ./update_default_user_role.sh -t "Secure Operations" -r ROLE_TEAM_STANDARD
{
  "team": {
    "userRoles": [],
    "version": 87,
    "origin": "SYSDIG",
    "description": "Immutable Secure team with full visibility",
    "show": "host",
    "customerId": 1,
    "theme": "#7BB0B2",
    "products": [
      "SDS"
    ],
    "entryPoint": {
      "module": "Explore"
    },
    "dateCreated": 1591191680000,
    "lastUpdated": 1591298554000,
    "defaultTeamRole": "ROLE_TEAM_STANDARD",
    "immutable": true,
    "canUseSysdigCapture": true,
    "canUseCustomEvents": true,
    "canUseAwsMetrics": true,
    "canUseBeaconMetrics": true,
    "userCount": 2,
    "name": "Secure Operations",
    "properties": {},
    "id": 2,
    "default": true
  }
}
```
