# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

spec = Gem::Specification.new do |s|
  s.name="nysol-view"
  s.version="3.0.0"
  s.author="NYSOL"
  s.email="info@nysol.jp"
  s.homepage="http://www.nysol.jp/"
  s.summary="nysol VIEW tools"
	s.files=[
		"lib/nysol/viewjs.rb",
		"bin/mbar.rb",
		"bin/mdtree.rb",
		"bin/mgv.rb",
		"bin/m2gv.rb",
		"bin/mautocolor.rb",
		"bin/mnest2tree.rb",
		"bin/msankey.rb",
		"bin/mpie.rb"
	]
	s.bindir = 'bin'
	s.executables = [
		"mgv.rb",
		"m2gv.rb",
		"mautocolor.rb",
		"mnest2tree.rb",
		"msankey.rb",
		"mbar.rb",
		"mpie.rb",
		"mdtree.rb"
	]
	s.require_path = "lib"
	s.add_dependency "nysol" ,"~> 3.0.0"
	s.description = <<-EOF
	  nysol VIEW tools
	EOF
end
