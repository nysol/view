#!/usr/bin/env ruby
#-*- coding: utf-8 -*-

require "rubygems"
require "nysol/mcmd"
require "set"

# ver="1.0" # 初期リリース 2016/11/09
$cmd=$0.sub(/.*\//,"")

$version=1.0
$revision="###VERSION###"

def help

STDERR.puts <<EOF
------------------------
#{$cmd} version #{$version}
------------------------
概要) 入れ子グラフ(nested graph)をtree構造グラフに変換する

書式1) #{$cmd} k= [ni=] [nf=] ei= ef= [no=] [eo=]

  k=  : 入れ子グラフのクラスタ項目名(ni=を指定した場合は同じ項目名でなければならない)
        複数項目指定不可

  ni= : 頂点集合ファイル名
  nf= : 頂点ID項目名

  ei= : 枝集合ファイル名
  ef= : 開始頂点ID項目名,終了頂点ID項目名
  ev= : 枝重み

  no=  : 出力節点ファイル名
  eo=  : 出力枝ファイル名

  -h,--help : ヘルプの表示

基本例)
EOF
exit
end
def ver()
	$revision ="0" if $revision =~ /VERSION/
	STDERR.puts "version #{$version} revision #{$revision}"
	exit
end

help() if ARGV.size <= 0 or ARGV[0]=="--help"
ver() if ARGV[0]=="--version"

# ===================================================================
# パラメータ処理
args=MCMD::Margs.new(ARGV,"k=,ni=,nf=,ei=,ef=,ev=,no=,eo=","ei=,ef=")

# mcmdのメッセージは警告とエラーのみ
ENV["KG_VerboseLevel"]="2" unless args.bool("-mcmdenv")

ni = args. file("ni=","r")                # nodeファイル名
nf = args.field("nf=", ni)                # nodeID項目名
unless args.keyValue["ni="]
	if args.keyValue["nf="]
		raise "nf= cannot be specified without ni="
	end
end

if args.keyValue["ni="]
	#unless args.keyValue["nf="] or args.keyValue["nv="]
	unless args.keyValue["nf="]
		raise "nf= must be specified when ni= is given"
	end
end

ei = args. file("ei=","r")                # edgeファイル名
key= args.field("k=", ei,nil,1,1)         # nested graph クラスタ項目
key=key["names"][0] if key
ef = args.field("ef=", ei)               # edge始点node項目名,終了頂点項目名
ev = args.field("ev=", ei)               # edge value項目名
ef1=ef["names"][0]
ef2=ef["names"][1]
if ef1==nil or ef2==nil then
	raise "ef= takes two field names"
end

if ni
	nf=nf["names"][0]
end
ev=ev["names"][0] if ev

noFile = args.file("no=","w")              # 出力ファイル名
eoFile = args.file("eo=","w")              # 出力ファイル名

#############
# entry point
temp=MCMD::Mtemp.new
xxa=temp.file
xxb=temp.file
xxnewNode=temp.file
system "mcut f=#{key}:#orgKey,#{ef1}:#orgEf1,#{ef2}:#orgEf2 i=#{ei} o=#{xxa}"

MCMD::Mcsvout.new("f=#orgKey,#orgEf1,#orgEf2,#ef1,#ef2 o=#{xxb}"){|oCSV|
	iCSV=MCMD::Mcsvin.new("i=#{xxa}")
	iCSV.each{|flds|
		orgKey  =flds["#orgKey"]
		orgEf1  =flds["#orgEf1"]
		orgEf2  =flds["#orgEf2"]
		# エッジを外して、親(key)との接続に変更する
		# 新しいkeyはnullとする
		oCSV.write([orgKey,orgEf1,orgEf2,orgKey,orgEf1])
		oCSV.write([orgKey,orgEf1,orgEf2,orgKey,orgEf2])
	}
}

# evが指定されているときは、平均重みを新しいedge(親-子)の重みとする
f=""
f << "mjoin k=#orgKey,#orgEf1,#orgEf2 K=#{key},#{ef1},#{ef2} m=#{ei} i=#{xxb} |" # 全項目join
if ev
	f << "mavg k=#ef1,#ef2 f=#{ev} |"
else
	f << "muniq k=#ef1,#ef2 |"
end
f << "mcut -r f=#orgKey,#orgEf1,#orgEf2 |"
f << "mfldname f=#ef1:#{ef1},#ef2:#{ef2} o=#{eoFile}"
system(f)

# 新たにclusterがnode名に登録されている可能性があるので、そのノードを取得し、後にnodeファイルに追加しておく
if ni
	fldNames=nil
	MCMD::Mcsvin.new("i=#{ni}"){|iCSV|
		fldNames=iCSV.names
		fldNames.delete(nf)
	}
	commas=','*(fldNames.size-1)
#p fldNames.join(',')

	f=""
	f << "mcut f=#{ef1}:#{nf} i=#{eoFile} |"
	f << "muniq k=#{nf} |"
	f << "mcommon k=#{nf} m=#{ni} -r |"
	f << "msetstr v=#{commas} a=#{fldNames.join(',')} o=#{xxnewNode}"
	system(f)
#system "cat #{xxnewNode}"
#exit
	# system "cat #{niFile}"
	# key,nam,keyNum%0,num,nv,nvv,nc,leaf,nvKey,ncKey
	# #1_1,a,1,5,0.4666666667,3.222222223,,1,0.6666666667,
	# #1_1,b,1,6,0.4,2.666666666,,1,0.6666666667,
	f=""
	f << "mcat i=#{ni},#{xxnewNode} |"
	f << "mcut f=#{key} -r |"
	f << "msetstr v= a=#{key} o=#{noFile}"
	system(f)
#system "cat #{noFile}"
#exit
end

# 終了メッセージ
MCMD::endLog(args.cmdline)

