class JohnJumbo < Formula
  desc "Enhanced version of john, a UNIX password cracker"
  homepage "http://www.openwall.com/john/"

  stable do
    url "http://openwall.com/john/j/john-1.8.0-jumbo-1.tar.xz"
    sha256 "bac93d025995a051f055adbd7ce2f1975676cac6c74a6c7a3ee4cfdd9c160923"
    version "1.8.0"
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
index 29e6509..874dbdf 100644
--- a/src/params.h
+++ b/src/params.h
@@ -80,17 +80,18 @@
  * notes above.
  */
 #ifndef JOHN_SYSTEMWIDE
-#define JOHN_SYSTEMWIDE			0
+#define JOHN_SYSTEMWIDE			1
 #endif
 
 #if JOHN_SYSTEMWIDE
 #ifndef JOHN_SYSTEMWIDE_EXEC /* please refer to the notes above */
-#define JOHN_SYSTEMWIDE_EXEC		"/usr/libexec/john"
+#define JOHN_SYSTEMWIDE_EXEC		"HOMEBREW_PREFIX/share/john"
 #endif
 #ifndef JOHN_SYSTEMWIDE_HOME
-#define JOHN_SYSTEMWIDE_HOME		"/usr/share/john"
+#define JOHN_SYSTEMWIDE_HOME		"HOMEBREW_PREFIX/share/john"
 #endif
 #define JOHN_PRIVATE_HOME		"~/.john"
+#define JOHN_XDG_HOME		"~/john"
 #endif
 
 #ifndef OMP_FALLBACK
diff --git a/src/path.c b/src/path.c
index 14f6310..2e07fcc 100644
--- a/src/path.c
+++ b/src/path.c
@@ -12,6 +12,7 @@
 #include "autoconfig.h"
 #endif
 #include <string.h>
+#include <stdlib.h>
 
 #include "misc.h"
 #include "params.h"
@@ -34,6 +35,7 @@ static int john_home_lengthex;
 
 static char *user_home_path = NULL;
 static int user_home_length;
+static int is_xdg = 1;
 #endif
 
 #include "memdbg.h"
@@ -41,7 +43,7 @@ static int user_home_length;
 void path_init(char **argv)
 {
 #if JOHN_SYSTEMWIDE
-	struct passwd *pw;
+	char *home_dir;
 #ifdef JOHN_PRIVATE_HOME
 	char *private;
 #endif
@@ -55,19 +57,30 @@ void path_init(char **argv)
 	john_home_length = strlen(john_home_path);
 
 	if (user_home_path) return;
-	pw = getpwuid(getuid());
-	endpwent();
-	if (!pw) return;
 
-	user_home_length = strlen(pw->pw_dir) + 1;
+	/* $HOME may override user's home directory */
+	if (!(home_dir = getenv("XDG_DATA_HOME"))) {
+		is_xdg = 0;
+		if (!(home_dir = getenv("HOME"))) {
+			struct passwd *pw;
+
+			pw = getpwuid(getuid());
+			endpwent();
+			if (!pw)
+				return;
+			home_dir = pw->pw_dir;
+		}
+	}
+
+	user_home_length = strlen(home_dir) + 1;
 	if (user_home_length >= PATH_BUFFER_SIZE) return;
 
 	user_home_path = mem_alloc(PATH_BUFFER_SIZE);
-	memcpy(user_home_path, pw->pw_dir, user_home_length - 1);
+	memcpy(user_home_path, home_dir, user_home_length - 1);
 	user_home_path[user_home_length - 1] = '/';
 
 #ifdef JOHN_PRIVATE_HOME
-	private = path_expand(JOHN_PRIVATE_HOME);
+	private = path_expand(is_xdg ? JOHN_XDG_HOME : JOHN_PRIVATE_HOME);
 	if (mkdir(private, S_IRUSR | S_IWUSR | S_IXUSR)) {
 		if (errno != EEXIST) pexit("mkdir: %s", private);
 	} else
