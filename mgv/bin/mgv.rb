#!/usr/bin/env ruby
#-*- coding: utf-8 -*-

require "rubygems"
require "nysol/mcmd"
require "set"

# ver="1.0" # 初期リリース 2016/11/07
# ver="1.1" # k=除外対応 2016/11/08
# ver="1.2" # nested graph対応,色対応 2016/11/09
$cmd=$0.sub(/.*\//,"")

$version=1.2
$revision="###VERSION###"

def help

STDERR.puts <<EOF
------------------------
#{$cmd} version #{$version}
------------------------
概要) CSVによるグラフ構造データをDOTフォーマットで出力する

書式1) #{$cmd} [type=flat|nest] [k=] [ni=] [nf=] [nv=] [nc=] [nr=] [col=] [nl=] [nw=]
                  [-clusterLabel] [-noiso] ei= ef= [ev=] [er=] [el=] [-d] [o=]

  type= : グラフのタイプ
          flat: key項目をクラスタとした木構造グラフ
          nest: 木構造であることを前提にした入れ子構造グラフ(データが木構造でない場合の描画は不定)
  k=  : 入れ子グラフのクラスタ項目名(ni=を指定した場合は同じ項目名でなければならない)
        複数項目指定不可
        k=を省略すればtype=に関わらずクラスタを伴わない普通のグラフ描画となる。

  ni= : 節点集合ファイル名
  nf= : 節点ID項目名
  nv= : 節点の大きさ項目名(この値に応じて節点の楕円の大きさが変化する,1項目のみ指定可)。
  nc= : 節点カラー項目名(この値に応じて枠線カラーが変化する,1項目のみ指定可)。
        カラーは、RGBを16進数2桁づつ6桁で表現する。ex) FF00FF:紫
        さらに最後に2桁追加すればそれは透過率となる。
  nr= : ノードの拡大率(デフォルト=3.0,最大10.0まで指定可能)
        節点の楕円のサイズを1.0〜nr=の値に基準化する。
        すなわちnv=が最小の節点の大きさが1.0、最大の節点の大きさがnr=で指定した値となる。
  nl= : ノードラベルの項目(複数指定したら"_"で区切って結合される)
  nw= : 節点の枠線の幅を指定する(デフォルトは1)
  -clusterLabel : k=を指定して入れ子グラフを作成する場合、クラスタのラベルも表示する
  -noiso : 孤立節点(隣接節点のない節点)は出力しない

  ei= : 枝集合ファイル名
  ef= : 開始節点ID項目名,終了節点ID項目名
  ev= : 枝の幅項目名(この値に応じて枝の幅(太さ)が変化する)
  ec= : 枝の色を表す項目
  ed= : 枝の矢印を表す項目(-dの指定、未指定に関わらず優先される)
        値としては、F,B,W,N,nullの5つの値のいずれかでなければならない。
        ef=e1,e2とした場合、それぞれで描画される矢印は以下の通り。
        F: e1->e2, B: e1<-e2, W: e1<->e2, N:e1-e2(矢印なし),null:デフォルト
        デフォルトは、-dが指定されていればF、-dの指定がなければNとなる。
  er= : エッジの拡大率(デフォルト=10.0,最大20.0まで指定可能)
        枝の太さを1.0〜er=の値に基準化する。
        すなわちev=が最小の枝の太さが1.0、最大の枝の太さer=で指定した値となる。
  el= : エッジラベルの項目(複数指定したら"_"で区切って結合される)

  -d  : 有向グラフと見なす。"edge [dir=none]"を記述する。
  o=  : 出力ファイル名

  -h,--help : ヘルプの表示

基本例)
$ cat node.csv
cluster%0,node%1,support
#1_1,a,0.4666666667
#1_1,b,0.4
#1_2,d,0.2666666667
#1_2,e,0.3333333333
#2_1,#1_1,0.6666666667
#2_1,c,0.3333333333
#3_1,#1_2,0.4
#3_1,#2_1,0.8
#3_1,f,0.2

$ cat edge.csv
cluster,node1,node2,support
#1_1,a,b,0.1
#1_2,d,e,0.1
#2_1,#1_1,c,0.2
#3_1,#1_2,#2_1,0.3
#3_1,#2_1,f,0.4

$ #{$cmd} k=cluster ni=node.csv nf=node nv=support ei=edge.csv ef=node1,node2 ev=support -el -nl nr=6.0 er=20 o=result.dot
# fdpはgraphVizのコマンド, nested graphはdotコマンドでは描画できない
$ fdp -Tpdf result.dot >result.pdf
$ open result.png
$ cat result.dot
digraph G {
  edge [dir=none color="#00000050"]
  n_15 [label="j_0.09090909091" height=0.5 width=0.75 style="setlinewidth(1)" ]
  n_14 [label="i_0.09090909091" height=0.5 width=0.75 style="setlinewidth(1)" ]
  subgraph cluster_4 {
    n_12 [label="g_0.1818181818" height=0.857142857 width=1.2857142855 style="setlinewidth(1)" ]↩
    n_13 [label="h_0.1818181818" height=0.857142857 width=1.2857142855 style="setlinewidth(1)" ]↩
    n_12 -> n_13 [label="0.1818181818" style="setlinewidth(1)" ]↩
  }
  subgraph cluster_5 {
    cluster_3 []
    cluster_2 []
    cluster_2 -> cluster_3 [label="0.2727272727" style="setlinewidth(20)" ]
    subgraph cluster_2 {
      n_6 [label="a_0.3636363636" height=1.5714285715 width=2.35714285725 style="setlinewidth(1)" ]
      n_7 [label="b_0.3636363636" height=1.5714285715 width=2.35714285725 style="setlinewidth(1)" ]
      n_9 [label="d_0.3636363636" height=1.5714285715 width=2.35714285725 style="setlinewidth(1)" ]
      n_10 [label="e_0.4545454545" height=1.9285714285 width=2.89285714275 style="setlinewidth(1)" ]
      n_6 -> n_7 [label="0.1818181818" style="setlinewidth(1)" ]
      n_6 -> n_9 [label="0.1818181818" style="setlinewidth(1)" ]
      n_7 -> n_9 [label="0.1818181818" style="setlinewidth(1)" ]
      n_6 -> n_10 [label="0.2727272727" style="setlinewidth(20)" ]
      n_7 -> n_10 [label="0.1818181818" style="setlinewidth(1)" ]
      n_9 -> n_10 [label="0.2727272727" style="setlinewidth(20)" ]
     }
    subgraph cluster_3 {
      n_8 [label="c_0.2727272727" height=1.2142857145 width=1.8214285717499998 style="setlinewidth(1)" ]
      n_11 [label="f_0.1818181818" height=0.857142857 width=1.2857142855 style="setlinewidth(1)" ]
      n_8 -> n_11 [label="0.1818181818" style="setlinewidth(1)" ]
    }
  }
}
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
args=MCMD::Margs.new(ARGV,"type=,k=,ni=,nf=,nv=,nc=,ei=,ef=,ev=,o=,nl=,el=,nr=,er=,ed=,-d,nw=,-clusterLabel,-noiso,-debug","ei=,ef=")

# mcmdのメッセージは警告とエラーのみ
ENV["KG_VerboseLevel"]="2" unless args.bool("-mcmdenv")

type = args.  str("type=","flat")         # グラフタイプ
if type!="nest" and type!="flat"
		raise "key= takes `nest' or `flat'"
end

ni = args. file("ni=","r")                # nodeファイル名
nf = args.field("nf=", ni)                # nodeID項目名
nv = args.field("nv=", ni)                # node value項目名
nc = args.field("nc=", ni)                # node color項目名
nr = args.float("nr=" , 3.0 ,1.0  ,10.0 ) # node 拡大率
nl = args.field("nl=", ni)                # nodeラベル項目名
nw =args.int("nw=",1,1)                   # nodeの枠線の太さ
unless args.keyValue["ni="]
	if args.keyValue["nf="] or args.keyValue["nv="] or args.keyValue["nc="] or args.keyValue["nr="] or args.keyValue["-nl"] or args.keyValue["-cl"] or args.keyValue["nw="]
		raise "nf=,nv=,nc=,nr=,-nl,-cl cannot be specified without ni="
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
ef = args.field("ef=", ei)                # edge始点node項目名,終了節点項目名
ev = args.field("ev=", ei)                # edge value項目名
ec = args.field("ec=", ei)                # edge color項目名
ed = args.field("ed=", ei)                # edge direction項目名
er = args.float("er=" , 10.0 ,1.0 ,20.0 ) # edge 拡大率
el = args.field("el=", ei)                # edgeラベル項目
ef1=ef["names"][0]
ef2=ef["names"][1]
if ef1==nil or ef2==nil then
	raise "ef= takes two field names"
end

if ni
	nf=nf["names"][0]
	nv=nv["names"][0] if nv
	nc=nc["names"][0] if nc
end

ev=ev["names"][0] if ev

directed = args. bool("-d")                    #有向グラフ
directedStr="edge []"
directedStr="edge [dir=none]" unless directed
oFile = args.file("o=","w")                # 出力ファイル名

clusterLabel=args.bool("-clusterLabel")
noiso=args.bool("-noiso")

# edgeデータからnested graphのtree構造を作る
# clusterのみの構造を作る
def mkTree(iFile,oFile)
	temp=MCMD::Mtemp.new
	xxroot =temp.file
	xxbase=[]
	xxbase << temp.file

	# #{iFile}
	# key,nam%0,keyNum,num,nv,nc
	# #2_1,#1_1,4,1,6,1
	# #2_1,#1_2,4,2,0.9999999996,1
	xxiFile1=temp.file
	xxiFile2=temp.file
	xxkey   =temp.file
	xxnum   =temp.file
	xxleaf  =temp.file
	xxcheck =temp.file

	# keyNumとnum項目のuniqリストを作り、お互いの包含関係でrootノードとleafノードを識別する。
	system "mcut f=keyNum,num i=#{iFile} | msortf f=keyNum o=#{xxiFile1}"
	system "mcut f=keyNum i=#{xxiFile1} | muniq k=keyNum o=#{xxkey}"
	system "mcut f=num    i=#{xxiFile1} | muniq k=num    o=#{xxnum}"

	# leaf nodesの選択
	system "mcommon k=num K=keyNum m=#{xxkey} -r i=#{xxnum} | mcut f=num o=#{xxleaf}"

	# root nodesの選択
	system "mcommon k=keyNum K=num m=#{xxnum} -r i=#{xxkey} | mcut f=keyNum:node0 o=#{xxbase[0]}"

	# leaf nodeの構造を知る必要はないので入力ファイルのnodeからleafを除外
	system "mcommon k=num m=#{xxleaf} -r i=#{xxiFile1} o=#{xxiFile2}"

	# root nodesファイルから親子関係noodeを次々にjoinしていく
	# xxbase0 : root nodes
	# node0%0
	# 3
	# 4
	# xxbase1
	# node0%0,node1
	# 3,
	# 4,1
	# 4,2
	# xxbase2
	# node0,node1%0,node2
	# 3,,
	# 4,1,
	# 4,2,
	# join項目(node2)の非null項目が0件で終了

# system "cat #{xxbase[0]}"
# node0%0
# #1_3
# #2_1
	i=0
	depth=nil
	while true
# puts "xxbase[#{i}]"
# system "cat #{xxbase[i]}"
		xxbase << temp.file
		system "mnjoin  k=node#{i} K=keyNum m=#{xxiFile2} f=num:node#{i+1} -n i=#{xxbase[i]} o=#{xxbase[i+1]}"
		system "mdelnull f=node#{i+1} i=#{xxbase[i+1]} o=#{xxcheck}"
		size=MCMD::mrecount("i=#{xxcheck}")
		if size==0
			system "msortf f=* i=#{xxbase[i]} o=#{oFile}"
			depth=i+1
			break
		end
		i+=1
	end
# system "cat #{oFile}"
# node0%0,node1
# 3,
# 4,1
# 4,2
#puts "depth=#{depth}"
# depth=2
	return depth
end

# edgeデータからflat graph構造を作る
# clusterのみの構造を作る
def mkFlat(iFile,oFile)
	f=""
	f << "mcut f=keyNum:node0 i=#{iFile} |"
	f << "muniq k=node0 o=#{oFile}"
	system(f)
	return 1
end


def keyBreakDepth(newFlds,oldFlds)
	return 0 unless oldFlds # 先頭行
	(0...newFlds.size).each{|i|
		return i if newFlds[i]!=oldFlds[i]
	}
end

##########################
# creating tree structure
#
# digraph G {edge [dir=none]
#   subgraph n_3 {
# ##3
#   }
#   subgraph n_4 {
# ##4
#     subgraph n_1 {
# ##1
#     }
#     subgraph n_2 {
# ##2
#     }
#   }
# }
def dotTree(iFile,depth,header,footer,oFile)
	File.open(oFile,"w"){|fpw|
		fpw.puts header
		fpw.puts "##0" # 孤立node(keyがnullのnode)
		iCSV=MCMD::Mcsvin.new("i=#{iFile} -array")
		oldFlds=nil
		stack=[] # "subgraph {"に対応する終了括弧"}"のスタック
		lastDepth=0 # 前行で出力されたsubgraphの深さ
		iCSV.each{|newFlds|
			next if newFlds[0]=="0" # 孤立nodeはスキップ
			kbd=keyBreakDepth(newFlds,oldFlds) # 前行に比べてどの位置でkeybreakがあったか
			(0...lastDepth-kbd).each{|i| # 前行より深さが戻った分終了括弧"}"を出力
				fpw.puts stack.pop
			}
			# keybreakした位置から最深の位置までsubgraphを出力
			(kbd...depth).each{|i|
				break unless newFlds[i] # nullはその深さにsubgraphなしということ
				indent='  '*(i+1) # インデント
				fpw.puts "#{indent}subgraph cluster_#{newFlds[i]} {"
				fpw.puts "###{newFlds[i]}"
				stack.push("#{indent}}") # 対応する終了括弧をスタックしておく
				lastDepth=i+1 # 出力した最深位置の更新
			}
			oldFlds=newFlds
		}
		(0...lastDepth).each{|i| # 深さが戻った分終了括弧"}"を出力
			fpw.puts stack.pop
		}
		fpw.puts footer
	}
end

# 全てをsubgraphを付けずにnodeとして出力する
def dotPlain(iFile,depth,header,footer,oFile)
	File.open(oFile,"w"){|fpw|
		fpw.puts header
		fpw.puts "##0" # 孤立node(keyがnullのnode)
		iCSV=MCMD::Mcsvin.new("i=#{iFile} -array")
		iCSV.each{|flds|
			flds.each{|fld|
				break if fld==nil or fld==""
				fpw.puts "###{fld}"
			}
		}
		fpw.puts footer
	}
end

def replace(treeFile,nodePath,edgePath,clusterLabel,noiso,oFile)
	File.open(oFile,"w"){|dot|
		File.open(treeFile,"r"){|tree|
			while line=tree.gets
				if line[0]=="#"
					num=line.strip.sub("##","")
					# 孤立nodeのclusterラベル(null)は出力しない
					if clusterLabel and File.exist?("#{nodePath}/L_#{num}") and num!="0"
						File.open("#{nodePath}/L_#{num}","r"){|label|
							dot.puts label.read
						}
					end
					if File.exist?("#{nodePath}/c_#{num}") # このifにマッチしないケースはないけど念のため
						unless noiso and num=="0" # -noisoが指定されたら孤立ノードは出力しない
							File.open("#{nodePath}/c_#{num}","r"){|node|
								dot.puts node.read
							}
						end
					end
					if File.exist?("#{edgePath}/c_#{num}") # 孤立nodeはedgeなしなのでマッチする
						File.open("#{edgePath}/c_#{num}","r"){|edge|
							dot.puts edge.read
						}
					end
				else
					dot.puts line
				end
			end
		}
	}
end

####################
# mapファイルの作成
# 1) key,node名の値に一対一対応するnodeIDを作成(niがなければeiから作成)
def mkMap(key,nf,ni,ef1,ef2,ei,oFile)
	temp=MCMD::Mtemp.new
	xxa=temp.file
	xxb=temp.file
	xxc=temp.file
	xxL1=temp.file
	xxL2=temp.file
	xxleaf=temp.file

	f=""
	if ni then
		f=""
		f << "mcommon k=#{nf} K=#{key} m=#{ni} -r i=#{ni} |"
		f << "mcut f=#{nf}:nam |"
		f << "msetstr v=1 a=leaf o=#{xxleaf}"
		system(f)
		system "mcut f=#{nf}:nam  i=#{ni} o=#{xxa}"
		system "mcut f=#{key}:nam i=#{ni} o=#{xxb}"
		f=""
		f << "mcat i=#{xxa},#{xxb} |"
		f << "muniq k=nam |"
		f << "mjoin k=nam m=#{xxleaf} f=leaf -n |"
		# nullは最初に来るはずなので、mcalでなくmnumberでもnullを0に採番できるはずだが念のために
		f << "mcal c='if(isnull($s{nam}),0,line()+1)' a=num |"
		f << "mnullto f=nam v=##NULL##  o=#{oFile}"
		system(f)
	else
		f=""
		f << "mcommon k=#{ef1} K=#{key} m=#{ei} -r i=#{ei} |"
		f << "mcut f=#{ef1}:nam o=#{xxL1}"
		system(f)
		f=""
		f << "mcommon k=#{ef2} K=#{key} m=#{ei} -r i=#{ei} |"
		f << "mcut f=#{ef2}:nam o=#{xxL2}"
		system(f)
		f=""
		f << "mcat i=#{xxL1},#{xxL2} |"
		f << "muniq k=nam |"
		f << "msetstr v=1 a=leaf o=#{xxleaf}"
		system(f)
		system "mcut f=#{ef1}:nam  i=#{ei} o=#{xxa}"
		system "mcut f=#{ef2}:nam  i=#{ei} o=#{xxb}"
		system "mcut f=#{key}:nam  i=#{ei} o=#{xxc}"
		f=""
		f << "mcat i=#{xxa},#{xxb},#{xxc} |"
		f << "muniq k=nam |"
		f << "mjoin k=nam m=#{xxleaf} f=leaf -n |"
		f << "mcal c='if(isnull($s{nam}),0,line()+1)' a=num |"
		f << "mnullto f=nam v=##NULL##  o=#{oFile}"
		system(f)
	end
end

####################
# nodeファイルの作成
# 1) key,node名すべての値に一対一対応するnodeIDを作成=>xxmap
# niがなければeiから作成
# 1) key,node名に対応するnodeIDをjoinする
# 2) nv項目を基準化
# 3) nvがなければ全データ1をセット
# 4) 基準化された値をnr倍する
# 3) ncがなければ全データnullをセット
#
# オリジナルのkey,node名に一意のnodeID(num)をつけて、nodeマスターを作成する
def mkNode(key,nf,nl,nv,nr,nc,ni,ef1,ef2,ei,mapFile,oFile)
	temp=MCMD::Mtemp.new
	xxa=temp.file
	xxb=temp.file

	# nodeファイルから作成
	if ni
		# mcal cat用のlabel項目の作成
		label=[]
		if nl
			nl["names"].each{|name|
				label << "$s{#{name}}"
			}
		else
			label << "$s{#{nf}}"
		end

		nvcStr=""
		nvcStr << ",#{nv}:nv" if nv
		nvcStr << ",#{nc}:nc" if nc

		# map
		# nam,leaf,num
		# ##NULL##,,0
		# #1_1,,2
		# #1_2,,3
		# #1_3,,4
		# #2_1,,5
		# a,1,6
		# b,1,7
		# c,1,8
		f=""
		f << "mcal c='cat(\"_\",#{label.join(',')})' a=##label i=#{ni} |"
		f << "mcut f=#{key}:key,#{nf}:nam,##label:nl#{nvcStr} |"
		f << "mnullto f=key v=##NULL## |"
		f << "msetstr v=  a=nv |" unless nv
		f << "msetstr v=  a=nc |" unless nc
		f << "mjoin k=key K=nam m=#{mapFile} f=num:keyNum |"
		f << "mjoin k=nam K=nam m=#{mapFile} f=num,leaf |"
		f << "mnormalize f=nv:nv2 c=range |"
		f << "mcal c='${nv2}*(#{nr}-1)+1' a=nvv |"
		f << "mcut f=key,nam,keyNum,num,nl,nv,nvv,nc,leaf o=#{xxa}"
		system(f)
		# key(cluster)のnvとncを結合しておく
		f=""
		f << "mjoin k=keyNum K=num m=#{xxa} f=nl:nlk,nv:nvKey,nc:ncKey -n i=#{xxa} |"
		# rootのclusterはnlkがnullになるので、keyをlabelとしておく
		f << "mcal c='if(isnull($s{nlk}),$s{key},$s{nlk})' a=nlKey |"
		f << "mcut f=nlk -r o=#{oFile}"
		system(f)

	# edgeファイルから作成
	else
		system "mcut f=#{key}:key,#{ef1}:nam,#{ef1}:nl i=#{ei} o=#{xxa}"
		system "mcut f=#{key}:key,#{ef2}:nam,#{ef2}:nl i=#{ei} o=#{xxb}"
		f=""
		f << "mcat i=#{xxa},#{xxb} |"
		f << "mnullto f=key v=##NULL## |"
		f << "muniq k=key,nam |"
		f << "mjoin k=key K=nam m=#{mapFile} f=num:keyNum |"
		f << "mjoin k=nam K=nam m=#{mapFile} f=num,leaf |"
		f << "msetstr v=,,,,, a=nv,nvv,nc,nlKey,nvKey,ncKey |"
		f << "mcut f=key,nam,keyNum,num,nl,nv,nvv,nc,leaf,nvKey,ncKey o=#{oFile}"
		system(f)
	end
# system "head #{oFile}"
# key,nam,keyNum%0,num,nv,nvv,nc,leaf,nvKey,ncKey
# ##NULL##,j,0,15,0.09090909091,1,FF0000,1,,
# ##NULL##,i,0,14,0.09090909091,1,FF0000,1,,
# #1_1,a,2,6,0.3636363636,1.857142857,FF0000,1,0.7272727273,
# #1_1,b,2,7,0.3636363636,1.857142857,00FF00,1,0.7272727273,
# #1_1,d,2,9,0.3636363636,1.857142857,00FF00,1,0.7272727273,
# #1_1,e,2,10,0.4545454545,2.142857143,0000FF,1,0.7272727273,
# #1_2,c,3,8,0.2727272727,1.571428571,FF0000,1,0.2727272727,
# #1_2,f,3,11,0.1818181818,1.285714286,FF0000,1,0.2727272727,
# #1_3,g,4,12,0.1818181818,1.285714286,00FF00,1,,
end

#####################
# edgeフィアルの作成
# 1) key,node名に対応するnodeIDをjoinする
# 2) ev項目を基準化
# 3) evがなければ全データ1をセット
# 4) 基準化された値をer倍する
def mkEdge(key,ef1,ef2,el,ec,ed,ev,er,ei,mapFile,oFile)
	# mcal cat用のlabel項目の作成
	label=[]
	if el
		el["names"].each{|name|
			label << "$s{#{name}}"
		}
	end

	evcdStr=""
	evcdStr << ",#{ev}:ev" if ev
	evcdStr << ",#{ec}:ec" if ec
	evcdStr << ",#{ed}:ed" if ed
	f=""
	if el
		f << "mcal c='cat(\"_\",#{label.join(',')})' a=##label i=#{ei} |"
	else
		f << "msetstr v= a=##label i=#{ei} |"
	end
	f << "mcut f=#{key}:key,#{ef1}:nam1,#{ef2}:nam2,##label:el#{evcdStr} |"
	f << "msetstr v=1 a=ev |" unless ev
	f << "mnullto f=key v=##NULL## |"
	f << "mjoin k=key  K=nam m=#{mapFile} f=num:keyNum |"
	f << "mjoin k=nam1 K=nam m=#{mapFile} f=num:num1,leaf:leaf1 |"
	f << "mjoin k=nam2 K=nam m=#{mapFile} f=num:num2,leaf:leaf2 |"
	f << "mnormalize f=ev:ev2 c=range |"
	f << "mcal c='${ev2}*(#{er}-1)+1' a=evv |"
	f << "mcut f=key,nam1,nam2,keyNum,num1,num2,el,ev,evv,leaf1,leaf2 o=#{oFile}"
	system(f)
end

#########################################
# dot用のnodeデータをcluster別に作成する
def dotNode(iFile,nw,type,clusterLabel,oPath)
	# system "cat #{iFile}"
	# key,nam,keyNum%0,num,nl,nv,nvv,nc,leaf,nvKey,ncKey
	# ##NULL##,j,0,15,j_A,0.09090909091,1,FF0000,1,,
	# ##NULL##,i,0,14,i_A,0.09090909091,1,FF0000,1,,
	# #1_1,a,2,6,a_A,0.3636363636,1.857142857,FF0000,1,0.7272727273,
	# #1_1,b,2,7,b_B,0.3636363636,1.857142857,00FF00,1,0.7272727273,
	# #1_1,d,2,9,d_B,0.3636363636,1.857142857,00FF00,1,0.7272727273,
	# #1_1,e,2,10,e_C,0.4545454545,2.142857143,0000FF,1,0.7272727273,
	# #1_2,c,3,8,c_A,0.2727272727,1.571428571,FF0000,1,0.2727272727,
	# #1_2,f,3,11,f_A,0.1818181818,1.285714286,FF0000,1,0.2727272727,
	# #1_3,g,4,12,g_B,0.1818181818,1.285714286,00FF00,1,,
	# #1_3,h,4,13,h_C,0.1818181818,1.285714286,0000FF,1,,
	# #2_1,#1_2,5,3,#1_2_,0.2727272727,1.571428571,,,,
	# #2_1,#1_1,5,2,#1_1_,0.7272727273,3,,,,
	iCSV=MCMD::Mcsvin.new("k=keyNum i=#{iFile}")
	block=""
	iCSV.each{|flds,top,bot|
		nam=flds["nam"]
		nl =flds["nl"]
		nv =flds["nv"]
		nvv=flds["nvv"]
		nc =flds["nc"]
		leaf=flds["leaf"]

		prefix="n"
		prefix="cluster" unless leaf
		nStr ="#{prefix}_#{flds["num"]}"
		attrStr=""

		unless prefix=="cluster"
			# node label
			# labelが#で始まる場合は、clusterLabelが指定されていない限りlabelを表示しない
			if nl[0]!="#" or clusterLabel
				attrStr << "label=\"#{nl}\" "
			else
				attrStr << "label=\"\" "
			end

			# node shape
			if nvv
				nRatioNorm=nvv.to_f
				attrStr << "height=#{0.5*nRatioNorm} width=#{0.75*nRatioNorm} "
			end

			# node color
			if nc
				attrStr << "color=\"##{nc}\" "
			end

			# node linewidth
			if nw
				attrStr << "style=\"setlinewidth(#{nw})\" "
			end
		end
		block << "#{nStr} [#{attrStr}]\n"

		if bot
			keyNum=flds["keyNum"]
			key=flds["key"]
			nlKey=flds["nlKey"]
			nvKey=flds["nvKey"]
			ncKey=flds["ncKey"]
			File.open("#{oPath}/c_#{keyNum}","w"){|fpw|
				fpw.write(block)
			}
			# クラスタのラベルや色も出力しておく
			attrStr=""
			attrStr << "label=\"#{nlKey}\"\n"

			# node color
			if ncKey
				attrStr << "color=\"##{ncKey}\"\n"
			end
			# node linewidth
			if nw and ncKey
				if ncKey
					attrStr << "style=\"setlinewidth(#{nw})\"\n"
				end
			end
			File.open("#{oPath}/L_#{keyNum}","w"){|fpw|
				fpw.write(attrStr)
			}
			block=""
		end
	}
end

#########################################
# dot用のedgeデータをcluster別に作成する
def dotEdge(iFile,oPath)
	# key,nam1,nam2%0,keyNum,num1,num2,ev,evv
	# #2_1,#1_1,#1_2,4,1,2,0.2727272727,20
	# #1_1,a,b,1,5,6,0.1818181818,0
	iCSV=MCMD::Mcsvin.new("k=keyNum i=#{iFile}")
	block=""
	iCSV.each{|flds,top,bot|
		num1=flds["num1"]
		num2=flds["num2"]
		el=flds["el"]
		ev=flds["ev"]
		ec=flds["ec"]
		ed=flds["ed"]
		evv=flds["evv"]
		leaf1=flds["leaf1"]
		leaf2=flds["leaf2"]

		prefix1="n"
		prefix2="n"
		prefix1="cluster" unless leaf1
		prefix2="cluster" unless leaf2
		e1Str ="#{prefix1}_#{num1}"
		e2Str ="#{prefix2}_#{num2}"

		attrStr=""
		attrStr << "label=\"#{el}\" "                if el
		attrStr << "style=\"setlinewidth(#{evv})\" " if evv
		attrStr << "color=\"##{ec}\" "               if ec
		if ed
			if ed=="F"
				attrStr << "dir=forward "
			elsif ed=="B"
				attrStr << "dir=back "
			elsif ed=="W"
				attrStr << "dir=both "
			elsif ed=="N"
				attrStr << "dir=none "
			end
		end

		block << "#{e1Str} -> #{e2Str} [#{attrStr}]\n"

		if bot
			keyNum=flds["keyNum"]
			File.open("#{oPath}/c_#{keyNum}","w"){|fpw|
				fpw.write(block)
			}
			block=""
		end
	}
end

#############
# entry point

temp=MCMD::Mtemp.new
xxni  =temp.file
xxei  =temp.file
xxmap =temp.file
xxnode=temp.file
xxedge=temp.file
xxnode2=temp.file
xxedge2=temp.file
xxtree=temp.file
xxdotNode=temp.file
xxdotEdge=temp.file
MCMD::mkDir(xxdotNode)
MCMD::mkDir(xxdotEdge)

# 処理前のデータ修正
unless key
	if ni
		system "msetstr v= a=#key i=#{ni} o=#{xxni}"
		ni=xxni
	end
	system "msetstr v= a=#key i=#{ei} o=#{xxei}"
	ei=xxei
	key="#key"
end

# ノードファイルの作成
mkMap(key,nf,ni,ef1,ef2,ei,xxmap)
mkNode(key,nf,nl,nv,nr,nc,ni,ef1,ef2,ei,xxmap,xxnode)
mkEdge(key,ef1,ef2,el,ec,ed,ev,er,ei,xxmap,xxedge)
#system "head #{xxmap}"
# nam%0,num
# ,0
# #1_1,1
# #1_2,2
#
#system "cat #{xxnode}"
#exit
# key,nam,keyNum%0,num,nv,nvv,nc,leaf,nvKey,ncKey
# #1_1,a,1,5,0.4666666667,3.222222223,,1,0.6666666667,
# #1_1,b,1,6,0.4,2.666666666,,1,0.6666666667,
#system "cat #{xxedge}"
# key,nam1,nam2%0,keyNum,num1,num2,ev,evv,leaf1,leaf2
# #3_1,#1_2,#2_1,4,2,3,0.3,13.66666667,,
# #1_1,a,b,1,5,6,0.1,1,1,1
#exit
# dot用のnodeとedgeデータをcluster別ファイルとして生成
dotNode(xxnode,nw,type,clusterLabel,xxdotNode)
dotEdge(xxedge                     ,xxdotEdge)
#system "rm -rf ./xxdotNode"
#system "cp -R #{xxdotNode} ./xxdotNode"
#system "rm -rf ./xxdotEdge"
#system "cp -R #{xxdotEdge} ./xxdotEdge"

depth=nil
if type=="flat"
	depth=mkFlat(xxnode,xxtree)
elsif type=="nest"
	# tree構造の処理
	# クラスタのみtree構造に格納する
	depth=mkTree(xxnode,xxtree)
	# puts "xxtree"
	# system "cat #{xxtree}"
	# node0%0,node1%1
	# 3,
	# 4,1
	# 4,2
end

# tree構造をdotとして書き出す。その時、node,edgeを置換するためのキーワードを埋め込む
xxdotTree=temp.file
header=""
header << "digraph G {\n"
header << "  #{directedStr}\n"
footer=""
footer << "}\n"
#system "cat #{xxtree}"
dotTree(xxtree,depth,header,footer,xxdotTree)
#puts "--------"
#system "cat #{xxdotTree}"
#exit
# xxdotTreeのnode,edge keywordをxxdotNode,xxdotEdgeで置換してdotの完成
replace(xxdotTree,xxdotNode,xxdotEdge,clusterLabel,noiso,oFile)

# 終了メッセージ
MCMD::endLog(args.cmdline)

