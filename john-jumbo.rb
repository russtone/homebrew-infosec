class JohnJumbo < Formula
  desc "Enhanced version of john, a UNIX password cracker"
  homepage "http://www.openwall.com/john/"

  stable do
    url "http://openwall.com/john/j/john-1.8.0-jumbo-1.tar.xz"
    sha256 "bac93d025995a051f055adbd7ce2f1975676cac6c74a6c7a3ee4cfdd9c160923"
    version "1.8.0"

    # Previously john-jumbo ignored the value of $HOME; fixed
    # upstream.  See
    # https://github.com/magnumripper/JohnTheRipper/issues/1901
    patch do
      url "https://github.com/magnumripper/JohnTheRipper/commit/d29ad8aabaa9726eb08f440001c37611fa072e0c.diff"
      sha256 "de5c09397f3666d0592e0f418f26a78a6624c5a947347ec2440e141c8915ae82"
    end
  end

  conflicts_with "john", :because => "both install the same binaries"

  option "without-completion", "bash/zsh completion will not be installed"

  depends_on "pkg-config" => :build
  depends_on "openssl"
  depends_on "gmp"

  # Patch taken from MacPorts, tells john where to find runtime files.
  # https://github.com/magnumripper/JohnTheRipper/issues/982
  patch :DATA

  fails_with :llvm do
    build 2334
    cause "Don't remember, but adding this to whitelist 2336."
  end

  # https://github.com/magnumripper/JohnTheRipper/blob/bleeding-jumbo/doc/INSTALL#L133-L143
  fails_with :gcc do
    cause "Upstream have a hacky workaround for supporting gcc that we can't use."
  end

  def install
    cd "src" do
      args = []
      if build.bottle?
        args << "--disable-native-tests" << "--disable-native-macro"
      end
      system "./configure", *args
      system "make", "clean"
      system "make", "-s", "CC=#{ENV.cc}"
    end

    # Remove the symlink and install the real file
    rm "README"
    prefix.install "doc/README"
    doc.install Dir["doc/*"]

    # Only symlink the main binary into bin
    (share/"john").install Dir["run/*"]
    bin.install_symlink share/"john/john"

    if build.with? "completion"
      bash_completion.install share/"john/john.bash_completion" => "john.bash"
      zsh_completion.install share/"john/john.zsh_completion" => "_john"
    end

    # Source code defaults to "john.ini", so rename
    mv share/"john/john.conf", share/"john/john.ini"
  end

  test do
    touch "john2.pot"
    (testpath/"test").write "dave:#{`printf secret | /usr/bin/openssl md5`}"
    assert_match(/secret/, shell_output("#{bin}/john --pot=#{testpath}/john2.pot --format=raw-md5 test"))
    assert_match(/secret/, (testpath/"john2.pot").read)
  end
end


__END__
diff --git a/src/params.h b/src/params.h
index 29e6509..7127430 100644
--- a/src/params.h
+++ b/src/params.h
@@ -80,17 +80,17 @@
  * notes above.
  */
 #ifndef JOHN_SYSTEMWIDE
-#define JOHN_SYSTEMWIDE                        0
+#define JOHN_SYSTEMWIDE                        1
 #endif

 #if JOHN_SYSTEMWIDE
 #ifndef JOHN_SYSTEMWIDE_EXEC /* please refer to the notes above */
-#define JOHN_SYSTEMWIDE_EXEC           "/usr/libexec/john"
+#define JOHN_SYSTEMWIDE_EXEC           "HOMEBREW_PREFIX/libexec/john"
 #endif
 #ifndef JOHN_SYSTEMWIDE_HOME
-#define JOHN_SYSTEMWIDE_HOME           "/usr/share/john"
+#define JOHN_SYSTEMWIDE_HOME           "HOMEBREW_PREFIX/share/john"
 #endif
-#define JOHN_PRIVATE_HOME              "~/.john"
+#define JOHN_PRIVATE_HOME              "XDG_DATA_HOME/john"
 #endif

 #ifndef OMP_FALLBACK