class AxeMcp < Formula
  include Language::Python::Virtualenv

  desc "AXE MCP server — registers AXE fleet tools with Claude Code"
  homepage "https://github.com/memjar/axe-mumJL3"
  url "https://github.com/memjar/axe-mumJL3/archive/refs/tags/mcp-v1.0.0.tar.gz"
  sha256 :no_check
  license "MIT"
  version "1.0.0"

  depends_on "python@3.12"

  # Install from a local path while the tap formula matures;
  # swap url/sha256 once a tagged release exists on memjar/axe-mumJL3.
  def install
    # Install the MCP server script into libexec
    libexec.install ".axe/mcp/axe_server.py" => "axe_server.py"

    # Create a thin launcher so `axe-mcp` is on PATH
    (bin/"axe-mcp").write <<~SH
      #!/bin/bash
      exec "#{Formula["python@3.12"].opt_bin}/python3" "#{libexec}/axe_server.py" "$@"
    SH
    chmod 0755, bin/"axe-mcp"
  end

  def post_install
    settings = Pathname.new(ENV["HOME"]) / ".claude/settings.json"
    return unless settings.exist?

    require "json"
    data = JSON.parse(settings.read)
    data["mcpServers"] ||= {}
    data["mcpServers"]["axe"] = {
      "command" => (bin/"axe-mcp").to_s,
      "args"    => [],
      "env"     => {
        "AXE_AGENT_NAME" => ENV.fetch("AXE_AGENT_NAME", "local"),
        "HOME"           => ENV["HOME"],
        "PATH"           => "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin",
      },
    }
    settings.write(JSON.pretty_generate(data))
    ohai "AXE MCP server registered in ~/.claude/settings.json"
    ohai "Restart Claude Code to load the new MCP server."
  end

  def caveats
    <<~EOS
      AXE MCP is now registered in ~/.claude/settings.json.

      Set your AXE API key before starting Claude Code:
        export AXE_API_KEY="bnk_..."

      To reload without restarting Claude Code:
        claude mcp restart axe
    EOS
  end

  test do
    assert_predicate bin/"axe-mcp", :executable?
    system bin/"axe-mcp", "--help"
  end
end
