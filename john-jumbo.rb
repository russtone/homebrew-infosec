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
index 29e6509..44b6387 100644
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
-#define JOHN_PRIVATE_HOME		"~/.john"
+#define JOHN_PRIVATE_HOME		"$JOHN_PRIV"
+#define JOHN_FOLDER		"john"
 #endif
 
 #ifndef OMP_FALLBACK
diff --git a/src/path.c b/src/path.c
index 203345c..399e094 100644
--- a/src/path.c
+++ b/src/path.c
@@ -13,6 +13,7 @@
 #endif
 #include <string.h>
 #include <stdlib.h>
+#include <stdbool.h>
 
 #include "misc.h"
 #include "params.h"
@@ -33,8 +34,8 @@ static int john_home_lengthex;
 #include <sys/types.h>
 #include <sys/stat.h>
 
-static char *user_home_path = NULL;
-static int user_home_length;
+static char *john_private_home_path = NULL;
+static int john_private_home_length;
 #endif
 
 #include "memdbg.h"
@@ -45,6 +46,7 @@ void path_init(char **argv)
 	char *home_dir;
 #ifdef JOHN_PRIVATE_HOME
 	char *private;
+	bool is_xdg = true;
 #endif
 #else
 	char *pos;
@@ -55,28 +57,32 @@ void path_init(char **argv)
 	strnzcpy(john_home_path, JOHN_SYSTEMWIDE_HOME "/", PATH_BUFFER_SIZE);
 	john_home_length = strlen(john_home_path);
 
-	if (user_home_path) return;
+	if (john_private_home_path) return;
 
 	/* $HOME may override user's home directory */
-	if (!(home_dir = getenv("HOME"))) {
-		struct passwd *pw;
-
-		pw = getpwuid(getuid());
-		endpwent();
-		if (!pw)
-			return;
-		home_dir = pw->pw_dir;
+	if (!(home_dir = getenv("XDG_DATA_HOME"))) {
+		is_xdg = false;
+		if (!(home_dir = getenv("HOME"))) {
+			struct passwd *pw;
+
+			pw = getpwuid(getuid());
+			endpwent();
+			if (!pw)
+				return;
+			home_dir = pw->pw_dir;
+		}
 	}
 
-	user_home_length = strlen(home_dir) + 1;
-	if (user_home_length >= PATH_BUFFER_SIZE) return;
+	john_private_home_length = strlen(home_dir) + (is_xdg ? 0 : 1) + strlen(JOHN_FOLDER) + 2;
+
+	if (john_private_home_length >= PATH_BUFFER_SIZE) return;
 
-	user_home_path = mem_alloc(PATH_BUFFER_SIZE);
-	memcpy(user_home_path, home_dir, user_home_length - 1);
-	user_home_path[user_home_length - 1] = '/';
+	john_private_home_path = mem_alloc(PATH_BUFFER_SIZE);
+	snprintf(john_private_home_path, john_private_home_length + 1, "%s/%s%s/",
+	         home_dir, is_xdg ? "" : ".", JOHN_FOLDER);
 
 #ifdef JOHN_PRIVATE_HOME
-	private = path_expand(JOHN_PRIVATE_HOME);
+	private = path_expand(JOHN_PRIVATE_HOME "/");
 	if (mkdir(private, S_IRUSR | S_IWUSR | S_IXUSR)) {
 		if (errno != EEXIST) pexit("mkdir: %s", private);
 	} else
@@ -166,14 +172,14 @@ char *path_expand(char *name)
 	}
 
 #if JOHN_SYSTEMWIDE
-	if (!strncmp(name, "~/", 2)) {
-		if (user_home_path &&
-		    user_home_length + strlen(name) - 2 < PATH_BUFFER_SIZE) {
-			strnzcpy(&user_home_path[user_home_length], &name[2],
-				PATH_BUFFER_SIZE - user_home_length);
-			return user_home_path;
+	if (!strncmp(name, "$JOHN_PRIV/", 11)) {
+		if (john_private_home_path &&
+		    john_private_home_length + strlen(name) - 11 < PATH_BUFFER_SIZE) {
+			strnzcpy(&john_private_home_path[john_private_home_length], &name[11],
+				PATH_BUFFER_SIZE - john_private_home_length);
+			return john_private_home_path;
 		}
-		return name + 2;
+		return name + 11;
 	}
 #endif
 
@@ -208,7 +214,7 @@ void path_done(void)
 {
 	MEM_FREE(john_home_path);
 #if JOHN_SYSTEMWIDE
-	MEM_FREE(user_home_path);
+	MEM_FREE(john_private_home_path);
 #endif
 	if (john_home_pathex)
 		MEM_FREE(john_home_pathex);
