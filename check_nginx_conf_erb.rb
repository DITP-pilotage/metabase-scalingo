#!/usr/bin/env ruby
# Renders nginx.conf.erb with sample env vars and checks the output looks right.
# Run locally after touching the template: ruby check_nginx_conf_erb.rb
require "erb"

ENV["ALLOWED_IPS"] = "203.0.113.10, 198.51.100.0/24"
ENV["SCALINGO_APPLICATION_ID"] = "ap-00000000-0000-0000-0000-000000000000"
ENV["SCALINGO_PRIVATE_NETWORK_ID"] = "pn-00000000-0000-0000-0000-000000000000"
ENV["ACME_CHALLENGE_URL"] = "http://my-acme-app.osc-fr1.scalingo.io"

template = File.read(File.join(__dir__, "nginx.conf.erb"))
rendered = ERB.new(template).result

expected = [
  "allow 203.0.113.10;",
  "allow 198.51.100.0/24;",
  "deny all;",
  "error_page 403 /rie.html;",
  "location /.well-known/acme-challenge/ {\n    set $acme_upstream http://my-acme-app.osc-fr1.scalingo.io;\n    proxy_pass $acme_upstream;",
  "set $metabase_upstream http://metabase.ap-00000000-0000-0000-0000-000000000000.pn-00000000-0000-0000-0000-000000000000.private-network.internal:3000;\n    proxy_pass $metabase_upstream;",
]

missing = expected.reject { |line| rendered.include?(line) }
raise "nginx.conf.erb did not render as expected, missing: #{missing}" unless missing.empty?

puts "OK: nginx.conf.erb renders correctly"
puts rendered
