# SSO onprem helper scripts

Under every folder you will find a helper script to configure and enable the following login methods:

* SAML
* OpenId
* Google Oauth
* LDAP

Probably you reached this repo coming from our documentation. If not, [this link to the docs](https://sysdigdocs.atlassian.net/wiki/spaces/Platform/pages/206503992/Authentication+and+Authorization+On-Prem+Options) should be helpful.

## How to run the scripts

* Edit `env.sh` file with your onprem instance URL and the API_TOKEN of the "super user" obtained from Sysdig Monitor or Sysdig Secure product. Depending on which token you take, the auth settings will be applied to Monitor or Secure (the exception is LDAP, as its configuration affects both products in the same way).
* Use the auth type of interest as the folder name (and take a look at the README file there)
* Run the script

```
cd SAML
./saml_config.sh -h
```
