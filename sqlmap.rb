class Sqlmap < Formula
  desc "Penetration testing for SQL injection and database servers"
  homepage "http://sqlmap.org"
  url "https://github.com/sqlmapproject/sqlmap/archive/1.0.11.tar.gz"
  sha256 "9d530182ef9ccc1aee33aaf3d630254a245c76fd1932395452347844237d6a60"
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
index e78c1fa..100d089 100644
--- a/lib/core/common.py
+++ b/lib/core/common.py
@@ -1199,7 +1199,7 @@ def setPaths(rootPath):
     paths.SQLMAP_XML_BANNER_PATH = os.path.join(paths.SQLMAP_XML_PATH, "banner")
     paths.SQLMAP_XML_PAYLOADS_PATH = os.path.join(paths.SQLMAP_XML_PATH, "payloads")

-    _ = os.path.join(os.path.expandvars(os.path.expanduser("~")), ".sqlmap")
+    _ = os.path.join(os.path.expandvars("$XDG_DATA_HOME"), "sqlmap") if "XDG_DATA_HOME" in os.environ else os.path.join(os.path.expandvars(os.path.expanduser("~")), ".sqlmap")
     paths.SQLMAP_OUTPUT_PATH = getUnicode(paths.get("SQLMAP_OUTPUT_PATH", os.path.join(_, "output")), encoding=sys.getfilesystemencoding() or UNICODE_ENCODING)
     paths.SQLMAP_DUMP_PATH = os.path.join(paths.SQLMAP_OUTPUT_PATH, "%s", "dump")
     paths.SQLMAP_FILES_PATH = os.path.join(paths.SQLMAP_OUTPUT_PATH, "%s", "files")
