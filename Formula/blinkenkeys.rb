class Blinkenkeys < Formula
  desc "Daemon and CLI that drive per-key RGB on VialRGB keyboards"
  homepage "https://github.com/seefood/blinkenkeys"
  license "GPL-3.0-only" # README says "GPL-3.0"; confirm -only vs -or-later

  ver = "0.2.1"
  base = "https://github.com/seefood/blinkenkeys/releases/download/v#{ver}"

  on_macos do
    on_arm do
      url "#{base}/blinkenkeys-v#{ver}-darwin-arm64.tar.gz"
      sha256 "e261df710c3b0b97c479f0e52d2780a95cbba50076ac2c3b0e3b8e2cbd45aa8d"
    end
    on_intel do
      url "#{base}/blinkenkeys-v#{ver}-darwin-amd64.tar.gz"
      sha256 "ecf20111dd042e8092358ff69797cdef0180d95e2c4c5f243accfcada9a7825c"
    end
  end

  on_linux do
    on_intel do
      url "#{base}/blinkenkeys-v#{ver}-linux-amd64.tar.gz"
      sha256 "46de151e8d9a202863dd3fefad174e0b3e7de5efa43a2b8bdfa3743af6681880"
    end
  end

  def install
    bin.install "bin/blinkenkeysd", "bin/blincli"
    pkgshare.install "examples/config"
    pkgshare.install "integrations"

    # The service runs as the user, so it can seed ~/.config (post_install is
    # sandboxed). Only when config.yaml is absent: an existing config, including
    # one from a previous install, is never touched.
    (libexec/"blinkenkeysd-service").write <<~SH
      #!/bin/sh
      dir="${XDG_CONFIG_HOME:-$HOME/.config}/blinkenkeys"
      if [ ! -e "$dir/config.yaml" ]; then
        mkdir -p "$dir" && cp -Rn "#{opt_pkgshare}/config/." "$dir/"
      fi
      exec "#{opt_bin}/blinkenkeysd" "$@"
    SH
    chmod 0555, libexec/"blinkenkeysd-service"
  end

  # Runs the daemon as a login service on macOS (and a systemd user unit on
  # Linuxbrew). It does not replace packaging/linux/install.sh's udev rule.
  service do
    run [opt_libexec/"blinkenkeysd-service"]
    keep_alive true
    log_path var/"log/blinkenkeysd.log"
    error_log_path var/"log/blinkenkeysd.log"
  end

  def caveats
    <<~EOS
      The service seeds ~/.config/blinkenkeys from #{opt_pkgshare}/config on
      first start, only if config.yaml is not already there. Edit the `devices:`
      uid in it for your keyboard.

      Start at login:  brew services start blinkenkeys

      Linux: raw HID access needs a udev rule, which Homebrew cannot install.
      Use packaging/linux/install.sh from the release tarball for that.
    EOS
  end

  test do
    assert_match "blincli", shell_output("#{bin}/blincli version")
    system bin/"blinkenkeysd", "--check-config", "-c", pkgshare/"config"
  end
end
