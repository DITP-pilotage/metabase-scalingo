web: bin/run
# PORT, not MB_JETTY_PORT: bin/start overwrites MB_JETTY_PORT with $PORT, which Scalingo sets to 0 outside of `web`.
metabase: SCALINGO=true PORT=3000 MB_JETTY_HOST=$SCALINGO_PRIVATE_HOSTNAME ./bin/start
