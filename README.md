![Metabase](metabase.png)

# Deploying Metabase to Scalingo

## Deploying Using Scalingo's One-click Button

Click on the button below to deploy Metabase to Scalingo within minutes.

[![Deploy](https://cdn.scalingo.com/deploy/button.svg)](https://my.scalingo.com/deploy?source=https://github.com/Scalingo/metabase-scalingo#master)

## Deploying Using Scalingo's Command Line Tool

1. Create an application on Scalingo:

```bash
$ scalingo create my-metabase
```

2. Add a PostgreSQL for the internal usage of Metabase:

```bash
$ scalingo --app my-metabase addons-add postgresql postgresql-starter-512
```

3. Configure your application to use the appropriate buildpack for deployments:

```bash
$ scalingo --app my-metabase env-set 'BUILDPACK_URL=https://github.com/Scalingo/multi-buildpack'
```

4. Clone this repository:

```bash
$ git clone https://github.com/Scalingo/metabase-scalingo
```

5. Configure `git`:

```bash
$ cd metabase-scalingo
$ scalingo --app my-metabase git-setup
```

6. Deploy the application:

```bash
$ git push scalingo master
```

# Configuring the Application Deployment Environment

The following environment variables are available for you to adjust, depending
on your needs:

| Name                 | Description                                                                              | Default value                                   |
| -------------------- | ---------------------------------------------------------------------------------------- | ----------------------------------------------- |
| `BUILDPACK_URL`      | URL of the buildpack to use.                                                             | https://github.com/Scalingo/multi-buildpack.git |
| `DATABASE_URL`       | URL of your database addon. **Only available if you have a database addon provisioned**. | Provided by Scalingo                            |
| `MAX_METASPACE_SIZE` | Maximum amount of memory allocated to Java Metaspace[^1].                                | `512m` (512MB)                                  |

Metabase also [supports many environment variables](https://www.metabase.com/docs/latest/operations-guide/environment-variables.html).

[^1]: See https://wiki.openjdk.org/display/HotSpot/Metaspace for further details about Java Metaspace.

# Updating Metabase on Scalingo

To upgrade to the latest version of Metabase, you only need to redeploy it,
this will retrieve the latest version avaible on [the Metabase buildpack](https://github.com/metabase/metabase-buildpack).

## Updating After Deploying Using Scalingo's One-click Button

If you deployed your Metabase instance via our One-click button, you can update
it with the following command:

```bash
$ scalingo --app my-metabase deploy https://github.com/Scalingo/metabase-scalingo/archive/refs/heads/master.tar.gz
```

If you are facing the `create archive deployment: * git_ref → can't be blank` error, you may need to specify the version explicitly:

```bash
$ scalingo --app my-metabase deploy https://github.com/Scalingo/metabase-scalingo/archive/refs/heads/master.tar.gz v1.0.0
```

## Updating After Deploying Using Scalingo's Command Line Tool

```bash
$ cd metabase-scalingo
$ git pull origin master
$ git push scalingo master
```

# Restricting Access by IP

Scalingo and Metabase (open source) have no built-in IP allowlist. This app
runs two process types (see `Procfile`):

- `web`: an Nginx reverse proxy ([nginx-buildpack](https://github.com/Scalingo/nginx-buildpack)),
  the only one reachable from the internet, filtering requests by IP
  (`nginx.conf.erb`).
- `metabase`: the actual Metabase JVM process, kept off the `web`/`tcp`/`postdeploy`
  process-type names so Scalingo never routes public traffic to it directly.
  It's only reachable from `web` over the project's
  [private network](https://doc.scalingo.com/platform/networking/private/overview).

```
Internet → [web: nginx, IP allowlist] → private network → [metabase: JVM]
```

## Prerequisite: Private Networks

This relies on Scalingo's Private Networks, which is a private beta at the
time of writing: the project this app lives in must have it enabled by
Scalingo support first (`support@scalingo.com`), or `SCALINGO_PRIVATE_NETWORK_ID`
won't be set and `nginx.conf.erb` won't be able to build the `metabase`
process's internal domain name. Confirm this is enabled before deploying.

## Required env vars

In addition to the existing `BUILDPACK_URL` (must point to
`https://github.com/Scalingo/multi-buildpack`, see `.buildpacks`) and
`DATABASE_URL`:

| Name          | Description                                                          |
| ------------- | --------------------------------------------------------------------- |
| `ALLOWED_IPS` | Comma-separated list of IPs/CIDRs allowed through the proxy.          |
| `ACME_CHALLENGE_URL` | Optional. Base URL of the app issuing this app's custom domain certificate (e.g. `http://copilot-refresh.osc-secnum-fr1.scalingo.io`): `/.well-known/acme-challenge/` is proxied to it, bypassing `ALLOWED_IPS`. |

Update `ALLOWED_IPS` and redeploy whenever the list changes — no code change
needed.

Requests from outside `ALLOWED_IPS` get a 403 with `rie.html`, explaining that
this instance is only reachable from the RIE.

## Closing the bypass

Metabase's own `*.scalingo.io` URL only served the `web` process before this
change, so once `web` is the Nginx proxy, that URL is naturally filtered too
— there's no separate direct-access URL to close.

# Login with ProConnect

On top of the IP allowlist, the `web` process can require a
[ProConnect](https://www.proconnect.gouv.fr/) login before anything reaches
Metabase. It runs [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/)
(installed by [betagouv/oauth2-proxy-buildpack](https://github.com/betagouv/oauth2-proxy-buildpack))
next to Nginx, and Nginx checks every request against it with `auth_request`:

```
Internet → [web: nginx, IP allowlist ─auth_request→ oauth2-proxy (127.0.0.1:4180)] → private network → [metabase: JVM]
```

It's off until `OAUTH2_PROXY_CLIENT_ID` is set: without it, `bin/web` doesn't
start oauth2-proxy and `nginx.conf.erb` doesn't add the check, so the app
behaves exactly as before.

## This is a gate, not single sign-on

Metabase open source ignores identity headers from a proxy (that's the paid
JWT/OIDC SSO), so after ProConnect, agents still log in to Metabase with their
Metabase account. What ProConnect adds: only the agents you allow ever see
Metabase's login page.

## Setup

1. Declare the app in the [ProConnect partner space](https://partenaires.proconnect.gouv.fr/apps),
   with `https://<your-domain>/oauth2/callback` as redirect URL, and get a
   client ID and secret. Start with the integration environment.
2. Set the env vars below, then redeploy.

| Name | Example / description |
| ---- | --------------------- |
| `OAUTH2_PROXY_PROVIDER` | `oidc` |
| `OAUTH2_PROXY_OIDC_ISSUER_URL` | ProConnect's issuer, from the partner space (integration: `https://fca.integ01.dev-agentconnect.fr/api/v2`). |
| `OAUTH2_PROXY_CLIENT_ID` | From ProConnect. Setting it turns the login on. |
| `OAUTH2_PROXY_CLIENT_SECRET` | From ProConnect. |
| `OAUTH2_PROXY_COOKIE_SECRET` | 32 random characters: `openssl rand -base64 32 \| head -c 32` |
| `OAUTH2_PROXY_REDIRECT_URL` | `https://<your-domain>/oauth2/callback` |
| `OAUTH2_PROXY_SCOPE` | `openid email given_name usual_name` |
| `OAUTH2_PROXY_SKIP_PROVIDER_BUTTON` | `true` to go straight to ProConnect instead of oauth2-proxy's sign-in page. |
| `OAUTH2_PROXY_COOKIE_EXPIRE` | Optional, e.g. `8h`: how often agents must go back through ProConnect. |

Who gets in, using one of these (oauth2-proxy lets everyone through who matches
either, so set only one):

| Name | Description |
| ---- | ----------- |
| `OAUTH2_ALLOWED_EMAILS` | Comma-separated emails, e.g. `jean.dupont@interieur.gouv.fr,marie.martin@finances.gouv.fr`. Read by the buildpack's start script. |
| `OAUTH2_PROXY_EMAIL_DOMAINS` | Comma-separated domains, e.g. `interieur.gouv.fr`. Never `*`: that lets in every ProConnect user. |

With neither set, nobody gets in. Changing either takes a restart, no code change.

`OAUTH2_PROXY_HTTP_ADDRESS`, `OAUTH2_PROXY_UPSTREAMS` and
`OAUTH2_PROXY_REVERSE_PROXY` are set by `bin/web`, since `nginx.conf.erb`
depends on them.

Logging out of Metabase doesn't end the ProConnect session; `/oauth2/sign_out`
clears oauth2-proxy's cookie.

## Public links and embeds

Metabase's public links (`/public/…`) and embeds go through the same check, so
they need a ProConnect login too. To exempt them, set
`OAUTH2_PROXY_SKIP_AUTH_ROUTES`, e.g. `^/public/,^/api/public/,^/app/` (they
remain behind the IP allowlist).
