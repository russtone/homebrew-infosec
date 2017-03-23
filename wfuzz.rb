require "formula"

class Wfuzz < Formula
  homepage "https://github.com/xmendez/wfuzz"
  url "https://github.com/xmendez/wfuzz", :using => :git, :revision => "796e1c2"
  version "2.1.5"
  revision 1

  depends_on "curl"

  resource "pycurl" do
    url "https://pypi.python.org/packages/12/3f/557356b60d8e59a1cce62ffc07ecc03e4f8a202c86adae34d895826281fb/pycurl-7.43.0.tar.gz"
    sha256 "aa975c19b79b6aa6c0518c0cc2ae33528900478f0b500531dbcdbf05beec584c"
  end

  def install
    ENV.prepend_create_path "PYTHONPATH", libexec/"vendor/lib/python2.7/site-packages"
    ENV.prepend_create_path "PYTHONPATH", libexec/"vendor/lib64/python2.7/site-packages"

    %w[pycurl].each do |r|
      resource(r).stage do
        system "python", *Language::Python.setup_install_args(libexec/"vendor")
      end
    end

    (bin/"wfuzz.py").write <<-EOS.undent
      #!/usr/bin/env bash
      cd #{libexec} && PYTHONPATH=#{ENV["PYTHONPATH"]} python wfuzz.py "$@"
    EOS
    libexec.install Dir['*']
  end
end
