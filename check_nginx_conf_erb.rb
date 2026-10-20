#!/usr/bin/env ruby
# Renders nginx.conf.erb with sample env vars and checks the output looks right,
# without and with ProConnect (oauth2-proxy) configured.
# Run locally after touching the template: ruby check_nginx_conf_erb.rb
require "erb"

ENV["ALLOWED_IPS"] = "203.0.113.10, 198.51.100.0/24"
ENV["SCALINGO_APPLICATION_ID"] = "ap-00000000-0000-0000-0000-000000000000"
ENV["SCALINGO_PRIVATE_NETWORK_ID"] = "pn-00000000-0000-0000-0000-000000000000"
ENV["ACME_CHALLENGE_URL"] = "http://my-acme-app.osc-fr1.scalingo.io"

template = File.read(File.join(__dir__, "nginx.conf.erb"))
# The template's locals (allowlist, proconnect) land in this script's top-level
# binding, so this script's own names must differ from them.
render = -> { ERB.new(template).result }

common_lines = [
  "allow 203.0.113.10;",
  "allow 198.51.100.0/24;",
  "deny all;",
  "error_page 403 /rie.html;",
  "location /.well-known/acme-challenge/ {\n    set $acme_upstream http://my-acme-app.osc-fr1.scalingo.io;\n    proxy_pass $acme_upstream;",
  "set $metabase_upstream http://metabase.ap-00000000-0000-0000-0000-000000000000.pn-00000000-0000-0000-0000-000000000000.private-network.internal:3000;\n    proxy_pass $metabase_upstream;",
]
proconnect_lines = [
  "error_page 401 = /oauth2/sign_in;",
  "location /oauth2/ {",
  "location = /oauth2/auth {\n    internal;",
  "proxy_pass http://127.0.0.1:4180;",
  "auth_request /oauth2/auth;",
]

def check(name, rendered, expected, unexpected = [])
  missing = expected.reject { |line| rendered.include?(line) }
  present = unexpected.select { |line| rendered.include?(line) }
  raise "#{name}: missing #{missing}" unless missing.empty?
  raise "#{name}: should not contain #{present}" unless present.empty?
  # Each location that reaches Metabase or oauth2-proxy's pages carries the IP allowlist.
  denies = rendered.scan("deny all;").size
  locations = rendered.scan(/location (\/|\/oauth2\/) \{/).size
  raise "#{name}: #{locations} locations but #{denies} 'deny all;'" unless denies == locations
  puts "OK: #{name}"
end

ENV.delete("OAUTH2_PROXY_CLIENT_ID")
without = render.call
check("without ProConnect", without, common_lines, proconnect_lines)

ENV["OAUTH2_PROXY_CLIENT_ID"] = "sample-client-id"
with = render.call
check("with ProConnect", with, common_lines + proconnect_lines)

puts with if ARGV.include?("--print")
