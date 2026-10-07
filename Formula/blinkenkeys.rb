class Blinkenkeys < Formula
  desc "Daemon and CLI that drive per-key RGB on VialRGB keyboards"
  homepage "https://github.com/seefood/blinkenkeys"
  license "GPL-3.0-only" # README says "GPL-3.0"; confirm -only vs -or-later

  ver = "0.2.0"
  base = "https://github.com/seefood/blinkenkeys/releases/download/v#{ver}"

  on_macos do
    on_arm do
      url "#{base}/blinkenkeys-v#{ver}-darwin-arm64.tar.gz"
      sha256 "4584b050aa5b5494c96794d517ff91fdaace28c507226aa7298cb9e14e8fd2b3"
    end
    on_intel do
      url "#{base}/blinkenkeys-v#{ver}-darwin-amd64.tar.gz"
      sha256 "5fda3ef922932cee0360f3fb84ef176cd19255aa0319799d3ce468a2c5bf695e"
    end
  end

  on_linux do
    on_intel do
      url "#{base}/blinkenkeys-v#{ver}-linux-amd64.tar.gz"
      sha256 "bda2f833cfa25880070a3038c9ee69e37cf3dade581e91aa2c69d9dad9b8a137"
    end
  end

  def install
    bin.install "bin/blinkenkeysd", "bin/blincli"
    pkgshare.install "examples/config"
    pkgshare.install "integrations"
  end

  # Runs the daemon as a login service on macOS (and a systemd user unit on
  # Linuxbrew). It does not replace packaging/linux/install.sh's udev rule.
  service do
    run [opt_bin/"blinkenkeysd"]
    keep_alive true
    log_path var/"log/blinkenkeysd.log"
    error_log_path var/"log/blinkenkeysd.log"
  end

  def caveats
    <<~EOS
      Seed a config before starting the service, then edit the `devices:` uid:
        mkdir -p ~/.config/blinkenkeys
        cp -Rn #{pkgshare}/config/. ~/.config/blinkenkeys/

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
