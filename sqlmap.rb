class Sqlmap < Formula
  desc "Penetration testing for SQL injection and database servers"
  homepage "http://sqlmap.org"
  url "https://github.com/sqlmapproject/sqlmap/archive/1.0.9.tar.gz"
  sha256 "dde180280d825da18dcb3c304e74e870e3ce396f5a1a001922cb386d860454f6"
  head "https://github.com/sqlmapproject/sqlmap.git"

  bottle :unneeded
	patch :DATA

  def install
    libexec.install Dir["*"]

    bin.install_symlink libexec/"sqlmap.py"
    bin.install_symlink bin/"sqlmap.py" => "sqlmap"

    bin.install_symlink libexec/"sqlmapapi.py"
    bin.install_symlink bin/"sqlmapapi.py" => "sqlmapapi"
  end

  test do
    data = %w[Bob 14 Sue 12 Tim 13]
    create = "create table students (name text, age integer);\n"
    data.each_slice(2) do |n, a|
      create << "insert into students (name, age) values ('#{n}', '#{a}');\n"
    end
    pipe_output("sqlite3 school.sqlite", create, 0)
    select = "select name, age from students order by age asc;"
    args = %W[--batch -d sqlite://school.sqlite --sql-query "#{select}"]
    output = shell_output("#{bin}/sqlmap #{args.join(" ")}")
    data.each_slice(2) { |n, a| assert_match "#{n}, #{a}", output }
  end
end

__END__
diff --git a/lib/core/common.py b/lib/core/common.py
index 743270b..5fbbdd6 100644
--- a/lib/core/common.py
+++ b/lib/core/common.py
@@ -1200,7 +1200,8 @@ def setPaths(rootPath):
     paths.SQLMAP_XML_PAYLOADS_PATH = os.path.join(paths.SQLMAP_XML_PATH, "payloads")

     _ = os.path.join(os.path.expandvars(os.path.expanduser("~")), ".sqlmap")
-    paths.SQLMAP_HOME_PATH = _
+    __ = os.path.join(os.path.expandvars("$XDG_DATA_HOME")) if "XDG_DATA_HOME" in os.environ else ''
+    paths.SQLMAP_HOME_PATH = __ if __ else _
     paths.SQLMAP_OUTPUT_PATH = getUnicode(paths.get("SQLMAP_OUTPUT_PATH", os.path.join(_, "output")), encoding=sys.getfilesystemencoding() or UNICODE_ENCODING)
     paths.SQLMAP_DUMP_PATH = os.path.join(paths.SQLMAP_OUTPUT_PATH, "%s", "dump")
     paths.SQLMAP_FILES_PATH = os.path.join(paths.SQLMAP_OUTPUT_PATH, "%s", "files")

