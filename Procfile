web: bin/run
# PORT, not MB_JETTY_PORT: bin/start overwrites MB_JETTY_PORT with $PORT, which Scalingo sets to 0 outside of `web`.
# 0.0.0.0, not $SCALINGO_PRIVATE_HOSTNAME: during a deploy that name can still resolve to the old container's IP, and Jetty fails to bind.
metabase: SCALINGO=true PORT=3000 MB_JETTY_HOST=0.0.0.0 ./bin/start
