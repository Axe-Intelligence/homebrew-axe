class AxeMemoryKit < Formula
  desc "CLI to save and recall context across Claude Code sessions via AXE memory"
  homepage "https://github.com/memjar/axe-mumJL3"
  head "https://github.com/memjar/axe-mumJL3.git", branch: "main"
  license "MIT"

  depends_on "python@3.12"

  def install
    libexec.install Dir["axe-memory-kit/*"]

    (bin/"axe-memory").write <<~SH
      #!/bin/bash
      exec "#{Formula["python@3.12"].opt_bin}/python3" "#{libexec}/axe_memory.py" "$@"
    SH
    chmod 0755, bin/"axe-memory"
  end

  def post_install
    settings = Pathname.new(Dir.home) / ".claude/settings.json"
    return unless settings.exist?

    hook_cmd = "#{Formula["python@3.12"].opt_bin}/python3 #{libexec}/hooks/session_start_memory.py"

    require "json"
    data = JSON.parse(settings.read)
    data["hooks"] ||= {}
    data["hooks"]["SessionStart"] ||= []

    already = data["hooks"]["SessionStart"].any? do |block|
      block.fetch("hooks", []).any? { |h| h["command"].to_s.include?("session_start_memory") }
    end

    unless already
      data["hooks"]["SessionStart"] << {
        "hooks" => [{ "type" => "command", "command" => hook_cmd }],
      }
      settings.write(JSON.pretty_generate(data))
      ohai "AXE memory SessionStart hook added to ~/.claude/settings.json"
    end
  end

  def caveats
    <<~EOS
      Usage:
        axe-memory save "Decision or context to remember" --kind decision
        axe-memory recall          # recent memories
        axe-memory search <query>  # semantic search

      Set your AXE API key:
        export AXE_API_KEY="bnk_..."

      The SessionStart hook has been wired into ~/.claude/settings.json so
      Claude Code automatically loads your team memory at session start.
    EOS
  end

  test do
    assert_predicate bin/"axe-memory", :executable?
  end
end
