# IP-restricted reverse proxy for Metabase

A standalone Nginx app that sits in front of the Metabase app and only lets
through requests from an allowed IP list. Scalingo has no built-in IP
allowlist and Metabase (open source) doesn't either, so this is a second app
using the [Scalingo Nginx buildpack](https://github.com/Scalingo/nginx-buildpack).

```
Internet → [proxy app: nginx, IP allowlist] → [Metabase app]
```

## Deploying

1. Create the proxy app (see `terraform/modules/copilot/main.tf` for the
   `copilot_metabase_proxy` resource — Terraform creates the app and its `web`
   container, but leaves `environment` unmanaged, same as the Metabase app).

2. Set the required env vars on the proxy app:

   ```bash
   scalingo --app copilot-metabase-proxy env-set \
     BUILDPACK_URL=https://github.com/Scalingo/nginx-buildpack.git \
     PROJECT_DIR=proxy \
     BACKEND_HOST=copilot-metabase.osc-secnum-fr1.scalingo.io \
     ALLOWED_IPS=203.0.113.10,198.51.100.0/24
   ```

   `ALLOWED_IPS` is a comma-separated list of IPs/CIDRs, turned into `allow`
   nginx directives by `nginx.conf.erb`. Update it and redeploy (or
   `scalingo --app copilot-metabase-proxy restart`, if a plain env change is
   enough to re-render the template) whenever the list changes — no code
   change needed.

3. Push this repo to the proxy app's git remote to deploy
   (`PROJECT_DIR=proxy` makes the buildpack build only this subdirectory).

## Closing the bypass

The proxy only helps if people actually go through it. Metabase's own
`*.scalingo.io` URL (`copilot-metabase.osc-secnum-fr1.scalingo.io`) stays
reachable directly, unfiltered, unless it's closed. Ask Scalingo support to
disable public access to the Metabase app's default domain once the proxy is
confirmed working, and don't share that URL in the meantime.
