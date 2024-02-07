class BugenTest < Formula
  desc "Test by Bugen"
  homepage "https://github.com/BugenZhao/homebrew-test-repo"
  url "https://github.com/BugenZhao/homebrew-test-repo/archive/refs/tags/v0.2.tar.gz"
  sha256 "ddf18cc3cf8b0baaf4f19fb083045bbae514a630a9f9f910a12d36a53ecf8387"
  license "Apache-2.0"
  revision 2
  head "https://github.com/BugenZhao/homebrew-test-repo.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "protobuf" => :build
  depends_on "rustup-init" => :build
  depends_on "openssl@3"
  depends_on "xz"

  def install
    # this will install the necessary cargo/rustup toolchain bits in HOMEBREW_CACHE
    system "#{Formula["rustup-init"].bin}/rustup-init",
           "-qy", "--no-modify-path"
    ENV.prepend_path "PATH", HOMEBREW_CACHE/"cargo_cache/bin"

    ENV.delete "RUSTFLAGS" # https://github.com/Homebrew/brew/pull/15544#issuecomment-1628639703
    # Homebrew changes cxx flags, and CMake doesn't pick them up, so rdkafka-sys build fails.
    # We cannot pass CMake flags (`std_cmake_args`) because it's in their build.rs.
    #
    # Some refs that might be useful:
    # https://github.com/Homebrew/homebrew-core/pull/51949#issuecomment-601943075
    # https://github.com/Homebrew/brew/pull/7134

    if MacOS.version >= :mojave && MacOS::CLT.installed?
      ENV["SDKROOT"] = ENV["HOMEBREW_SDKROOT"] = MacOS::CLT.sdk_path(MacOS.version)
    end

    # Remove `"-Clink-arg=xxx/ld64.lld"` to avoid relying on llvm's lld.
    inreplace ".cargo/config.toml" do |s|
      s.gsub!(/"-Clink-arg=.*ld64.lld",?/, "")
    end

    system "cargo", "install",
           "--profile", "dev",
           *std_cargo_args(path: ".") # "--locked", "--root ..."
  end

  test do
    system "#{bin}/homebrew-test-repo"
  end
end
