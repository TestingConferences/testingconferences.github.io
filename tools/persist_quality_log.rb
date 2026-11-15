#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'optparse'

options = {
  output: '_data/quality_log.yml',
  base_branch: 'main',
  max_attempts: 3,
  before_push_cmd: '',
  before_push_cmd_each_attempt: false
}

OptionParser.new do |opts|
  opts.banner = 'Usage: ruby tools/persist_quality_log.rb --version v123 --broken-links 0 --commit-sha abc123 --workflow-run-url https://...'

  opts.on('--version VERSION', 'Release version (for example: v123)') { |v| options[:version] = v }
  opts.on('--broken-links COUNT', Integer, 'Broken link count') { |v| options[:broken_links] = v }
  opts.on('--commit-sha SHA', 'Commit SHA for this snapshot') { |v| options[:commit_sha] = v }
  opts.on('--workflow-run-url URL', 'Workflow run URL') { |v| options[:workflow_run_url] = v }
  opts.on('--output PATH', 'Output YAML path') { |v| options[:output] = v }
  opts.on('--base-branch NAME', 'Branch to persist to') { |v| options[:base_branch] = v }
  opts.on('--max-attempts N', Integer, 'Max push attempts on non-fast-forward rejection') { |v| options[:max_attempts] = v }
  opts.on('--before-push-cmd COMMAND', 'Optional command to run before push attempts') { |v| options[:before_push_cmd] = v }
  opts.on('--before-push-cmd-each-attempt', 'Run before-push command on every attempt instead of once') { options[:before_push_cmd_each_attempt] = true }
end.parse!

abort('Missing required --version') unless options[:version]
abort('Missing required --broken-links') unless options.key?(:broken_links)
abort('Missing required --commit-sha') unless options[:commit_sha]
abort('Missing required --workflow-run-url') unless options[:workflow_run_url]
abort('--max-attempts must be >= 1') if options[:max_attempts].to_i < 1

def run!(*command)
  stdout, stderr, status = Open3.capture3(*command)
  return [stdout, stderr] if status.success?

  abort("Command failed: #{command.join(' ')}\nSTDOUT:\n#{stdout}\nSTDERR:\n#{stderr}")
end

def push_to_origin(branch)
  Open3.capture3('git', 'push', 'origin', "HEAD:#{branch}")
end

base_branch = options[:base_branch]
append_script = File.expand_path('append_quality_log.rb', __dir__)
before_push_cmd = options[:before_push_cmd].to_s.strip

run!('git', 'config', 'user.name', 'github-actions[bot]')
run!('git', 'config', 'user.email', 'github-actions[bot]@users.noreply.github.com')

(1..options[:max_attempts]).each do |attempt|
  run!('git', 'fetch', 'origin', base_branch)
  run!('git', 'checkout', '-B', base_branch, "origin/#{base_branch}")

  run!(
    'ruby', append_script,
    '--version', options[:version],
    '--broken-links', options[:broken_links].to_s,
    '--commit-sha', options[:commit_sha],
    '--workflow-run-url', options[:workflow_run_url],
    '--output', options[:output]
  )

  run!('git', 'add', options[:output])

  stdout, _stderr = run!('git', 'diff', '--staged', '--name-only')
  if stdout.strip.empty?
    puts 'No quality log changes to commit'
    exit 0
  end

  run!('git', 'commit', '-m', "chore: log link integrity for #{options[:version]}")

  if !before_push_cmd.empty? && (options[:before_push_cmd_each_attempt] || attempt == 1)
    hook_stdout, hook_stderr, hook_status = Open3.capture3('bash', '-c', before_push_cmd)
    unless hook_status.success?
      abort("Before-push command failed on attempt #{attempt}.\nSTDOUT:\n#{hook_stdout}\nSTDERR:\n#{hook_stderr}")
    end
  end

  push_stdout, push_stderr, push_status = push_to_origin(base_branch)
  if push_status.success?
    puts "Persisted quality log on attempt #{attempt}"
    exit 0
  end

  combined = "#{push_stdout}\n#{push_stderr}"
  non_fast_forward = combined.include?('non-fast-forward') || combined.include?('[rejected]')
  unless non_fast_forward
    abort("Push failed for a non-retryable reason:\n#{combined}")
  end

  puts "Push rejected as non-fast-forward on attempt #{attempt}; retrying..."
end

abort("Failed to persist quality log after #{options[:max_attempts]} attempts")
