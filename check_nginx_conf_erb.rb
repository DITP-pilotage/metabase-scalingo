#!/usr/bin/env ruby
# Renders nginx.conf.erb with sample env vars and checks the output looks right.
# Run locally after touching the template: ruby check_nginx_conf_erb.rb
require "erb"

ENV["ALLOWED_IPS"] = "203.0.113.10, 198.51.100.0/24"
ENV["SCALINGO_APPLICATION_ID"] = "ap-a71da13f-7c70-4c00-a644-eee8558d8053"
ENV["SCALINGO_PRIVATE_NETWORK_ID"] = "pn-ad0fd6a1-d05e-40ea-bf63-c4f8a75a9d8c"
ENV["ACME_CHALLENGE_URL"] = "http://copilot-refresh.osc-secnum-fr1.scalingo.io"

template = File.read(File.join(__dir__, "nginx.conf.erb"))
rendered = ERB.new(template).result

expected = [
  "allow 203.0.113.10;",
  "allow 198.51.100.0/24;",
  "deny all;",
  "location /.well-known/acme-challenge/ {\n    proxy_pass http://copilot-refresh.osc-secnum-fr1.scalingo.io;",
  "proxy_pass http://metabase.ap-a71da13f-7c70-4c00-a644-eee8558d8053.pn-ad0fd6a1-d05e-40ea-bf63-c4f8a75a9d8c.private-network.internal:3000;",
]

missing = expected.reject { |line| rendered.include?(line) }
raise "nginx.conf.erb did not render as expected, missing: #{missing}" unless missing.empty?

puts "OK: nginx.conf.erb renders correctly"
puts rendered
