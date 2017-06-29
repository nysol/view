require "bundler/gem_tasks"
iDic = "./bin"

fList = [
	iDic,
	"bin/mbar.rb",
	"bin/mdtree.rb",
	"bin/mgv.rb",
	"bin/m2gv.rb",
	"bin/mautocolor.rb",
	"bin/mnest2tree.rb",
	"bin/msankey.rb",
	"bin/mpie.rb"
]

directory iDic
file "bin/mbar.rb" => "mbar/bin/mbar.rb" do |t|
	cp t.source, t.name
end

file "bin/mdtree.rb" => "mdtree/bin/mdtree.rb" do |t|
	cp t.source, t.name
end
file "bin/mgv.rb" => "mgv/bin/mgv.rb" do |t|
	cp t.source, t.name
end

file "bin/m2gv.rb" => "mgv/bin/m2gv.rb" do |t|
	cp t.source, t.name
end
file "bin/mautocolor.rb" => "mgv/bin/mautocolor.rb" do |t|
	cp t.source, t.name
end
file "bin/mnest2tree.rb" => "mgv/bin/mnest2tree.rb" do |t|
	cp t.source, t.name
end

file "bin/mnest2tree.rb" => "mgv/bin/mnest2tree.rb" do |t|
	cp t.source, t.name
end
file "bin/msankey.rb" => "msankey/bin/msankey.rb" do |t|
	cp t.source, t.name
end

file "bin/mpie.rb" => "mpie/bin/mpie.rb" do |t|
	cp t.source, t.name
end


task "build" => fList do
end

