require "formula"

class FuzzTxt < Formula
  homepage "https://github.com/Bo0oM/fuzz.txt"
  url "https://github.com/Bo0oM/fuzz.txt", :using => :git, :revision => "6034d239"
  head "https://github.com/Bo0oM/fuzz.txt", :using => :git, :branch => "master"
  version "1.0"

  def install
    pkgshare.install Dir["*"]
  end

  def caveats; <<-EOS.undent
    The fuzz.txt can be found in #{HOMEBREW_PREFIX}/share/fuzz.txt
    EOS
  end
end
