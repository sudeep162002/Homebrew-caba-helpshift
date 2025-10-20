class Caba < Formula
  desc "Cab Booking Analyzer - Professional PDF to Excel CLI tool"
  homepage "https://github.com/sudeep162002/CABA"
  url "https://github.com/sudeep162002/CABA/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "e729e795ca5a84117d8101baeac1fe8b065961ef9cc7728a29ee63f2226d8a47"
  license "MIT"
  head "https://github.com/sudeep162002/CABA.git", branch: "main"

  depends_on "python@3.13"
  depends_on "rust" => :build  # Add Rust as a build dependency for pydantic-core

  # Skip cleaning for all files in libexec to prevent Homebrew from modifying them
  skip_clean "libexec/**/*"

  def install
    # Install project files into the formula's private libexec directory
    libexec.install Dir["*"]

    # Create a virtual environment using the specific Homebrew Python
    venv = libexec/"venv"
    system Formula["python@3.13"].opt_bin/"python3.13", "-m", "venv", venv

    # Set environment variables to ensure proper linking
    ENV["LDFLAGS"] = "-Wl,-headerpad_max_install_names"
    ENV["CFLAGS"] = "-Wl,-headerpad_max_install_names"
    
    # Install all packages from source to avoid binary compatibility issues
    system venv/"bin/pip", "install", "--no-cache-dir", "--no-binary", ":all:", "-r", libexec/"requirements.txt"

    # Create a wrapper script in the user's PATH (bin/)
    (bin/"caba").write <<~EOS
      #!/bin/sh
      # Set environment variables to ensure proper library loading
      export DYLD_LIBRARY_PATH=""
      export LD_LIBRARY_PATH=""
      # Ensure we're using the correct Python environment
      export PYTHONPATH="#{libexec}"
      # Add the venv lib directory to DYLD_FALLBACK_LIBRARY_PATH
      export DYLD_FALLBACK_LIBRARY_PATH="#{venv}/lib:$DYLD_FALLBACK_LIBRARY_PATH"
      exec "#{venv}/bin/python" "#{libexec}/caba.py" "$@"
    EOS
  end

  test do
    # A simple test to ensure the executable runs without critical errors
    assert_match(/cab booking analyzer/i, shell_output("#{bin}/caba --help 2>&1", 1))
  end

  # Add caveats to inform users about potential issues
  def caveats
    <<~EOS
      This formula installs a Python virtual environment in:
        #{opt_libexec}/venv
      
      The tool uses its own Python environment and doesn't interfere with system Python.
      
      If you encounter issues with dependencies, try reinstalling:
        brew reinstall caba
    EOS
  end
end
