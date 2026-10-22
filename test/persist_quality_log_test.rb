#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require 'fileutils'
require 'open3'
require 'shellwords'
require 'tmpdir'
require 'yaml'

ROOT = File.expand_path('..', __dir__)
PERSIST = File.join(ROOT, 'tools', 'persist_quality_log.rb')

class PersistQualityLogTest < Minitest::Test
  def run_command!(dir, *args)
    _stdout, stderr, status = Open3.capture3(*args, chdir: dir)
    assert status.success?, "command failed: #{args.join(' ')}\n#{stderr}"
  end

  def write_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def test_retries_non_fast_forward_and_preserves_intervening_main_changes
    Dir.mktmpdir do |dir|
      remote = File.join(dir, 'remote.git')
      seed = File.join(dir, 'seed')
      worker = File.join(dir, 'worker')
      competitor = File.join(dir, 'competitor')
      final_clone = File.join(dir, 'final')

      run_command!(dir, 'git', 'init', '--bare', remote)

      run_command!(dir, 'git', 'clone', remote, seed)
      run_command!(seed, 'git', 'config', 'user.name', 'Test User')
      run_command!(seed, 'git', 'config', 'user.email', 'test@example.com')
      write_file(File.join(seed, '_data', 'quality_log.yml'), "--- []\n")
      write_file(File.join(seed, 'README.md'), "base\n")
      run_command!(seed, 'git', 'add', '_data/quality_log.yml', 'README.md')
      run_command!(seed, 'git', 'commit', '-m', 'seed main')
      run_command!(seed, 'git', 'push', 'origin', 'HEAD:main')

      run_command!(dir, 'git', 'clone', '--branch', 'main', remote, worker)
      run_command!(dir, 'git', 'clone', '--branch', 'main', remote, competitor)
      run_command!(competitor, 'git', 'config', 'user.name', 'Competing User')
      run_command!(competitor, 'git', 'config', 'user.email', 'compete@example.com')

      hook = [
        "cd #{Shellwords.escape(competitor)}",
        'git fetch origin main',
        'git checkout -B main origin/main',
        "echo 'intervening change' >> README.md",
        'git add README.md',
        "git commit -m 'intervening main change'",
        'git push origin HEAD:main'
      ].join(' && ')

      stdout, stderr, status = Open3.capture3(
        'ruby', PERSIST,
        '--version', 'v-race',
        '--broken-links', '5',
        '--commit-sha', 'scanned-sha-123',
        '--workflow-run-url', 'https://example.com/workflow/1',
        '--base-branch', 'main',
        '--max-attempts', '3',
        '--before-push-cmd', hook,
        '--output', '_data/quality_log.yml',
        chdir: worker
      )
      assert status.success?, "persist script failed:\nSTDOUT:\n#{stdout}\nSTDERR:\n#{stderr}"
      assert_includes stdout, 'non-fast-forward'

      run_command!(dir, 'git', 'clone', '--branch', 'main', remote, final_clone)
      readme = File.read(File.join(final_clone, 'README.md'))
      assert_includes readme, 'intervening change'

      log = YAML.safe_load_file(File.join(final_clone, '_data', 'quality_log.yml'))
      matching = log.select { |entry| entry['version'] == 'v-race' }
      assert_equal 1, matching.length
      assert_equal 'scanned-sha-123', matching.first['commit_sha']
      assert_equal 5, matching.first['broken_links']
      assert_equal 'https://example.com/workflow/1', matching.first['workflow_run_url']
    end
  end
end
