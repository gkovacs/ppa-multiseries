#!/usr/bin/ruby

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
	Dir.foreach(dirn) { |fn|
		if fn == "." or fn == ".."
			next
		end
		fn = File.expand_path(dirn+"/"+fn)
		if File.directory?(fn)
			rmdir(fn)
		else
			File.delete(fn)
		end
	}
	Dir.delete(dirn)
end

if __FILE__ == $0

	if ARGV.length == 0
		puts "need argument"
		exit
	end

	deletedirs = true
	distrolist = ["hardy", "intrepid", "jaunty", "karmic", "lucid"]

	if ARGV.length > 1
		if ARGV[1] == "-k"
			deletedirs = false
			ARGV = ARGV[0..0]+ARGV[2..ARGV.length]
		end
	end
	
	if ARGV.length > 1
		distrolist = ARGV[1..ARGV.length]
	end

	dscn = ARGV[0]
	if dscn.include? "http://" or dscn.include? "ftp://"
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

		debmail = ENV['DEBMAIL']
		debname = ENV['DEBFULLNAME']
		cdate = `date --rfc-2822`

		for distn in distrolist do
nchentry = <<-eos
#{debpkg} (#{debver}~#{distn}1) #{distn}; urgency=low

  * Upload to Launchpad

 -- #{debname} <#{debmail}>  #{cdate}
eos
			writef("debian/changelog", nchentry+dchtxt)
			sh "debuild -i -I -S -sa"
		end
	}
	
	if deletedirs
		rmdir(srcdir)
	end

end
