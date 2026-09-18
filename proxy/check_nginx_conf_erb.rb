#!/usr/bin/env ruby
# Renders nginx.conf.erb with sample env vars and checks the output looks right.
# Run locally after touching the template: ruby proxy/check_nginx_conf_erb.rb
require "erb"

ENV["ALLOWED_IPS"] = "203.0.113.10, 198.51.100.0/24"
ENV["BACKEND_HOST"] = "copilot-metabase.osc-secnum-fr1.scalingo.io"

template = File.read(File.join(__dir__, "nginx.conf.erb"))
rendered = ERB.new(template).result

expected = [
  "allow 203.0.113.10;",
  "allow 198.51.100.0/24;",
  "deny all;",
  "proxy_pass https://copilot-metabase.osc-secnum-fr1.scalingo.io;",
]

missing = expected.reject { |line| rendered.include?(line) }
raise "nginx.conf.erb did not render as expected, missing: #{missing}" unless missing.empty?

puts "OK: nginx.conf.erb renders correctly"
puts rendered
