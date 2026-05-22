class AxeMcp < Formula
  desc "MCP server that registers AXE fleet tools with Claude Code"
  homepage "https://github.com/memjar/axe-mumJL3"
  license "MIT"
  head "https://github.com/memjar/axe-mumJL3.git", branch: "main"

  depends_on "python@3.12"

  def install
    libexec.install ".axe/mcp/axe_server.py" => "axe_server.py"

    (bin/"axe-mcp").write <<~SH
      #!/bin/bash
      exec "#{Formula["python@3.12"].opt_bin}/python3" "#{libexec}/axe_server.py" "$@"
    SH
    chmod 0755, bin/"axe-mcp"
  end

  def post_install
    settings = Pathname.new(Dir.home) / ".claude/settings.json"
    return unless settings.exist?

    require "json"
    data = JSON.parse(settings.read)
    data["mcpServers"] ||= {}
    data["mcpServers"]["axe"] = {
      "command" => (bin/"axe-mcp").to_s,
      "args"    => [],
      "env"     => {
        "AXE_AGENT_NAME" => ENV.fetch("AXE_AGENT_NAME", "local"),
        "HOME"           => Dir.home,
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
  end
end
