class AxeMemoryKit < Formula
  desc "AXE memory CLI — save and recall context across Claude Code sessions"
  homepage "https://github.com/memjar/axe-mumJL3"
  url "https://github.com/memjar/axe-mumJL3/archive/refs/tags/memory-kit-v1.0.0.tar.gz"
  sha256 :no_check
  license "MIT"
  version "1.0.0"

  depends_on "python@3.12"

  def install
    # Install kit scripts into libexec
    libexec.install Dir["axe-memory-kit/*"]

    # Main CLI wrapper
    (bin/"axe-memory").write <<~SH
      #!/bin/bash
      exec "#{Formula["python@3.12"].opt_bin}/python3" "#{libexec}/axe_memory.py" "$@"
    SH
    chmod 0755, bin/"axe-memory"

    # SessionStart hook — wire into Claude Code automatically
    (libexec/"session_start_memory.py").tap do |f|
      break unless f.exist?
    end
  end

  def post_install
    # Register SessionStart hook in ~/.claude/settings.json
    settings = Pathname.new(ENV["HOME"]) / ".claude/settings.json"
    hook_cmd = "#{Formula["python@3.12"].opt_bin}/python3 #{libexec}/hooks/session_start_memory.py"

    if settings.exist?
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
    system bin/"axe-memory", "--help"
  end
end
