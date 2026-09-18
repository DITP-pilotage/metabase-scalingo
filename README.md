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

Update `ALLOWED_IPS` and redeploy whenever the list changes — no code change
needed.

## Closing the bypass

Metabase's own `*.scalingo.io` URL only served the `web` process before this
change, so once `web` is the Nginx proxy, that URL is naturally filtered too
— there's no separate direct-access URL to close.
