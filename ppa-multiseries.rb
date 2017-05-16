#!/usr/bin/ruby

# Copyright (c) 2010 Geza Kovacs
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'fileutils'

module Enumerable
	def grep(v)
		return select { |a|
			a.include? v
		}
	end
end

def sh(c)
	outl = []
	IO.popen(c) { |f|
		while not f.eof?
			tval = f.gets
			puts tval
			outl.push(tval)
		end
	}
	return outl.join("")
end

def cat(c)
	outl = []
	f = File.open(c, "r")
	f.each { |line|
		outl.push(line)
	}
	f.close
	return outl.join("")
end

def writef(fn, c)
	File.open(fn, "w") { |f|
		f.puts(c)
	}
end

def rmdir(dirn)
	FileUtils.rm_rf(dirn)
end

if __FILE__ == $0

	if ARGV.length == 0
		puts "need argument"
		exit
	end

	deletedirs = true
	distrolist = ["precise", "trusty", "xenial", "yakkety", "zesty"]
	vernum = 1

	if ARGV.length > 1
		if ARGV[1] == "-k"
			deletedirs = false
			ARGV = ARGV[0..0]+ARGV[2..ARGV.length]
		end
	end
	
	if ARGV.length > 1
		if ARGV[1].to_i > 1
			vernum = ARGV[1].to_i
			ARGV = ARGV[0..0]+ARGV[2..ARGV.length]
		end
	end

	if ARGV.length > 1
		distrolist = ARGV[1..ARGV.length]
	end

	dscn = ARGV[0]
	if dscn.include? "http://" or dscn.include? "https://" or dscn.include? "ftp://"
		sh "dget #{dscn}"
		dscn = dscn[dscn.rindex("/")+1..dscn.length]
	end

	srcinf = sh "dpkg-source -x #{dscn}"
	srcdir = srcinf.split("\n").grep("extracting")[0].split(" ").last

	Dir.chdir(srcdir) {
		dchtxt = cat "debian/changelog"
		dchfl = dchtxt.split("\n")[0]
		debver = dchfl.split(")")[0].split("(").last
		debpkg = dchfl.split(" ")[0]

		debmail = ENV['DEBEMAIL']
		debname = ENV['DEBFULLNAME']
		cdate = `date --rfc-2822`

		for distn in distrolist do
nchentry = <<-eos
#{debpkg} (#{debver}~#{distn}#{vernum}) #{distn}; urgency=low

  * Upload to Launchpad

 -- #{debname} <#{debmail}>  #{cdate}
eos
			writef("debian/changelog", nchentry+dchtxt)
			origsrcfmt = nil
			if distn == "karmic" or distn == "jaunty" or distn == "intrepid" or distn == "hardy"
			    if File.exists? "debian/source/format"
			        origsrcfmt = cat "debian/source/format"
			        writef("debian/source/format", "1.0")
			    end
			end
			sh "debuild -i -I -S -sa"
			if origsrcfmt != nil
			    writef("debian/source/format", origsrcfmt)
			end
		end
	}
	
	if deletedirs
		rmdir(srcdir)
	end

end
