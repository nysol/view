#!/usr/bin/env bash

# インストールされたコマンドでのチェック
if [ "$1" = "g" ] ; then
  lexe=""
# ローカルでのチェック
else
  lexe='ruby -I../../lib ../bin/'
fi

ip=data
op=xxresult
mkdir -p $op

function normalize {
	nv=$1; nr=$2; fld=$3; iFile=$4; oFile=$5
	mnormalize f=$nv:__nv2 c=range i=$iFile |
	mcal c="\${__nv2}*($nr-1)+1" a=$fld |
	mcut f=__nv2 -r o=$oFile
}

function edgeColor {
	${lexe}mautocolor.rb i=$ip/node.csv f=val a=color color=category o=xxnode
	${lexe}mautocolor.rb i=$ip/edge.csv f=v   a=color color=category o=xxedge

	normalize val 3  nvv xxnode xxnormN
	normalize v   10 evv xxedge xxnormE
	${lexe}m2gv.rb ni=xxnormN nf=node nv=nvv ei=xxnormE ef=e1,e2 nc=color ec=color ev=evv o=$op/test81.dot

	${lexe}mautocolor.rb i=$ip/edge1.csv f=resemblance a=color color=00FF00,FF00FF o=xxedge
	normalize resemblance   10 evv xxedge xxnormE
	${lexe}m2gv.rb type=nest k=cluster ni=$ip/node1.csv nf=node ei=xxnormE ef=node1,node2 ec=color ev=evv o=$op/test82.dot
}

function direction {
	${lexe}m2gv.rb ni=$ip/node1.csv nf=node ei=$ip/edge1.csv ef=node1,node2 -d o=$op/test70.dot
	${lexe}m2gv.rb ni=$ip/node1.csv nf=node ei=$ip/edge1.csv ef=node1,node2 ed=dir o=$op/test71.dot
	${lexe}m2gv.rb ni=$ip/node1.csv nf=node ei=$ip/edge1.csv ef=node1,node2 -d ed=dir o=$op/test72.dot
	${lexe}m2gv.rb type=nest k=cluster ni=$ip/node1.csv nf=node ei=$ip/edge1.csv ef=node1,node2  o=$op/test73.dot
	${lexe}m2gv.rb type=nest k=cluster ni=$ip/node1.csv nf=node ei=$ip/edge1.csv ef=node1,node2 ed=dir o=$op/test74.dot
	${lexe}m2gv.rb type=nest k=cluster ni=$ip/node1.csv nf=node ei=$ip/edge1.csv ef=node1,node2 -d ed=dir o=$op/test75.dot
}

######################################
# mautocolor
function color {
	${lexe}mautocolor.rb i=$ip/color.csv f=class1 a=color color=category               o=$op/color1.csv
	${lexe}mautocolor.rb i=$ip/color.csv f=class1 a=color color=category order=descend o=$op/color2.csv
	${lexe}mautocolor.rb i=$ip/color.csv f=class1 a=color color=category order=ascend  o=$op/color3.csv
	${lexe}mautocolor.rb i=$ip/color.csv f=class2 a=color color=category               o=$op/color4.csv
	${lexe}mautocolor.rb i=$ip/color.csv f=value1 a=color color=FF0000,0000FF          o=$op/color5.csv
	${lexe}mautocolor.rb i=$ip/color.csv f=value2 a=color color=FF0000,0000FF          o=$op/color6.csv
	${lexe}mautocolor.rb i=$ip/color.csv f=class1 a=color color=category transmit=50   o=$op/color7.csv
}


################
# k=なし
# 基本例
function base {
	normalize val 6  nvv $ip/node.csv xxnormN
	normalize v   20 evv $ip/edge.csv xxnormE
	${lexe}m2gv.rb ni=xxnormN nf=node nv=nvv ei=xxnormE ef=e1,e2 ev=evv el=v nl=node,val o=$op/test1.dot

	# edgeのみ与えて実行
	normalize v   20 evv $ip/edge.csv xxnormE
	${lexe}m2gv.rb ei=xxnormE ef=e1,e2 ev=evv el=v o=$op/test2.dot

	# 最もシンプルな指定方法
	${lexe}m2gv.rb ei=$ip/edge.csv ef=e1,e2 o=$op/test3.dot
}

######################################
# flat cluster graph
function flatGraph {
	normalize support 6  nvv $ip/node3.csv xxnormN
	normalize support 20 evv $ip/edge3.csv xxnormE
	${lexe}m2gv.rb type=flat k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv el=support nl=node,support o=$op/test31.dot

	normalize support 6  nvv $ip/node4.csv xxnormN
	normalize support 20 evv $ip/edge4.csv xxnormE
	${lexe}m2gv.rb type=flat k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv el=support nl=node,support o=$op/test32.dot

	# edgeのみ与えて実行
	normalize support 20 evv $ip/edge1.csv xxnormE
	${lexe}m2gv.rb type=flat k=cluster ei=xxnormE ef=node1,node2 ev=evv el=support o=$op/test33.dot
	normalize support 20 evv $ip/edge4.csv xxnormE
	${lexe}m2gv.rb type=flat k=cluster ei=xxnormE ef=node1,node2 ev=evv el=support o=$op/test34.dot

	${lexe}m2gv.rb type=flat k=cluster ei=$ip/edge1.csv ef=node1,node2 o=$op/test35.dot
	${lexe}m2gv.rb type=flat k=cluster ei=$ip/edge4.csv ef=node1,node2 o=$op/test36.dot

	# group label追加
	normalize support 6  nvv $ip/node4.csv xxnormN
	normalize support 20 evv $ip/edge4.csv xxnormE
	${lexe}m2gv.rb type=flat k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv el=support nl=node,support -clusterLabel o=$op/test37.dot

	# color
	${lexe}mautocolor.rb i=$ip/node1.csv f=class1 color=category a=class1c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $ip/edge1.csv xxnormE
	${lexe}m2gv.rb type=flat k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv -clusterLabel nc=class1c o=$op/test38.dot

	# nc=class2 clusterも色をつける
	echo "# nc=class2 clusterも色をつける"
	${lexe}mautocolor.rb i=$ip/node1.csv f=class2 color=category a=class2c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $ip/edge1.csv xxnormE
	${lexe}m2gv.rb type=flat k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv -clusterLabel nc=class2c o=$op/test39.dot

	# nodeの線を太くする nw=3
	echo "# nodeの線を太くする nw=3"
	${lexe}mautocolor.rb i=$ip/node1.csv f=class1 color=category a=class1c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $ip/edge1.csv xxnormE
	${lexe}m2gv.rb type=flat k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv -clusterLabel nc=class1c nw=3 o=$op/test40.dot

# 数値項目によるグラデーションカラー
echo "# 数値項目によるグラデーションカラー"
	${lexe}mautocolor.rb i=$ip/node1.csv f=class3 color=FF0000,0000FF a=class3c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $ip/edge1.csv xxnormE
	${lexe}m2gv.rb type=flat k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv -clusterLabel nc=class3c nw=5 o=$op/test41.dot

	${lexe}mautocolor.rb i=$ip/node1.csv f=class4 color=FF0000,0000FF a=class4c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $ip/edge1.csv xxnormE
	${lexe}m2gv.rb type=flat k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv -clusterLabel nc=class4c nw=5 o=$op/test42.dot

	# nv,nc両方ラベルに入れる
	echo "# nv,nc両方ラベルに入れる"
	${lexe}mautocolor.rb i=$ip/node1.csv f=class1 color=category a=class1c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $ip/edge1.csv xxnormE
	${lexe}m2gv.rb type=flat k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv nl=node,support,class1 -clusterLabel nc=class1c nw=3 o=$op/test43.dot

	# 大きなデータ
	normalize support 2  nvv $ip/1477126924.2442381.node xxnormN
	normalize support 20 evv $ip/1477126924.2442381.edge xxnormE
	${lexe}m2gv.rb type=flat k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv el=support nl=node,support o=$op/test44.dot
}

######################################
# tree cluster graph
function treeGraph {
	${lexe}mnest2tree.rb k=cluster ni=$ip/node3.csv nf=node ei=$ip/edge3.csv ef=node1,node2 ev=support no=$op/tNode3b.csv eo=$op/tEdge3b.csv
	${lexe}mnest2tree.rb k=cluster ni=$ip/node4.csv nf=node ei=$ip/edge4.csv ef=node1,node2 ev=support no=$op/tNode4b.csv eo=$op/tEdge4b.csv
	${lexe}mnest2tree.rb k=cluster ni=$ip/1477126924.2442381.node nf=node ei=$ip/1477126924.2442381.edge ef=node1,node2 ev=support no=$op/t1477126924.2442381.node eo=$op/t1477126924.2442381.edge

	normalize support 6  nvv $op/tNode3b.csv xxnormN
	normalize support 20 evv $op/tEdge3b.csv xxnormE
	${lexe}m2gv.rb type=flat -d ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv el=support nl=node,support o=$op/test51.dot

	normalize support 6  nvv $op/tNode3b.csv xxnormN
	normalize support 20 evv $op/tEdge3b.csv xxnormE
	${lexe}m2gv.rb type=flat -d -d ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv el=support nl=node,support -noiso o=$op/test51-1.dot

	normalize support 6  nvv $op/tNode4b.csv xxnormN
	normalize support 20 evv $op/tEdge4b.csv xxnormE
	${lexe}m2gv.rb type=flat -d ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv el=support nl=node,support o=$op/test52.dot

	# edgeのみ与えて実行
	normalize support 20 evv $op/tEdge3b.csv xxnormE
	${lexe}m2gv.rb type=flat -d ei=xxnormE ef=node1,node2 ev=evv el=support o=$op/test53.dot
	normalize support 20 evv $op/tEdge4b.csv xxnormE
	${lexe}m2gv.rb type=flat -d ei=xxnormE ef=node1,node2 ev=evv el=support o=$op/test54.dot

	${lexe}m2gv.rb type=flat -d ei=$op/tEdge3b.csv ef=node1,node2 o=$op/test55.dot
	${lexe}m2gv.rb type=flat -d ei=$op/tEdge4b.csv ef=node1,node2 o=$op/test56.dot
	${lexe}m2gv.rb type=flat -d ei=$op/tEdge4b.csv ef=node1,node2 -clusterLabel o=$op/test56-1.dot

	# group label追加
	normalize support 6  nvv $op/tNode4b.csv xxnormN
	normalize support 20 evv $op/tEdge4b.csv xxnormE
	${lexe}m2gv.rb type=flat -d ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv el=support nl=node,support -clusterLabel o=$op/test57.dot

	# color
	${lexe}mautocolor.rb i=$op/tNode3b.csv f=class1 color=category a=class1c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $op/tEdge3b.csv xxnormE
	${lexe}m2gv.rb type=flat -d ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv -clusterLabel nc=class1c o=$op/test58.dot

	# nc=class2 clusterも色をつける
	echo "# nc=class2 clusterも色をつける"
	${lexe}mautocolor.rb i=$op/tNode3b.csv f=class2 color=category a=class2c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $op/tEdge3b.csv xxnormE
	${lexe}m2gv.rb type=flat -d ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv -clusterLabel nc=class2c o=$op/test59.dot

	# nodeの線を太くする nw=3
	echo "# nodeの線を太くする nw=3"
	${lexe}mautocolor.rb i=$op/tNode3b.csv f=class1 color=category a=class1c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $op/tEdge3b.csv xxnormE
	${lexe}m2gv.rb type=flat -d ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv -clusterLabel nc=class1c nw=3 o=$op/test60.dot

# 数値項目によるグラデーションカラー
echo "# 数値項目によるグラデーションカラー"
	${lexe}mautocolor.rb i=$op/tNode3b.csv f=class3 color=FF0000,0000FF a=class3c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $op/tEdge3b.csv xxnormE
	${lexe}m2gv.rb type=flat -d ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv -clusterLabel nc=class3c nw=5 o=$op/test61.dot

	${lexe}mautocolor.rb i=$op/tNode3b.csv f=class4 color=FF0000,0000FF a=class4c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $op/tEdge3b.csv xxnormE
	${lexe}m2gv.rb type=flat -d ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv -clusterLabel nc=class4c nw=5 o=$op/test62.dot

	# nv,nc両方ラベルに入れる
	echo "# nv,nc両方ラベルに入れる"
	${lexe}mautocolor.rb i=$op/tNode3b.csv f=class1 color=category a=class1c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $op/tEdge3b.csv xxnormE
	${lexe}m2gv.rb type=flat -d ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv nl=node,support,class1 -clusterLabel nc=class1c nw=3 o=$op/test63.dot

	# 大きなデータ
	normalize support 2  nvv $op/t1477126924.2442381.node xxnormN
	normalize support 20 evv $op/t1477126924.2442381.edge xxnormE
	${lexe}m2gv.rb type=flat -d ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv el=support nl=node,support o=$op/test64.dot
}

################
# nested graph
function nestedGraph {

	normalize support 6  nvv $ip/node1.csv xxnormN
	normalize support 20 evv $ip/edge1.csv xxnormE
	${lexe}m2gv.rb type=nest k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv el=support nl=node,support o=$op/test11.dot

	normalize support 6  nvv $ip/node2.csv xxnormN
	normalize support 20 evv $ip/edge2.csv xxnormE
	${lexe}m2gv.rb type=nest k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv el=support nl=node,support o=$op/test12.dot

	# edgeのみ与えて実行
	normalize support 20 evv $ip/edge1.csv xxnormE
	${lexe}m2gv.rb type=nest k=cluster ei=xxnormE ef=node1,node2 ev=evv el=support o=$op/test13.dot
	normalize support 20 evv $ip/edge2.csv xxnormE
	${lexe}m2gv.rb type=nest k=cluster ei=xxnormE ef=node1,node2 ev=evv el=support o=$op/test14.dot

	${lexe}m2gv.rb type=nest k=cluster ei=$ip/edge1.csv ef=node1,node2 o=$op/test15.dot
	${lexe}m2gv.rb type=nest k=cluster ei=$ip/edge2.csv ef=node1,node2 o=$op/test16.dot

	# group label追加
	normalize support 6  nvv $ip/node2.csv xxnormN
	normalize support 20 evv $ip/edge2.csv xxnormE
	${lexe}m2gv.rb type=nest k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv el=support nl=node,support -clusterLabel o=$op/test17.dot

	# color
	${lexe}mautocolor.rb i=$ip/node1.csv f=class1 color=category a=class1c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $ip/edge1.csv xxnormE
	${lexe}m2gv.rb type=nest k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv -clusterLabel nc=class1c o=$op/test18.dot

	# nc=class2 clusterも色をつける
	echo "# nc=class2 clusterも色をつける"
	${lexe}mautocolor.rb i=$ip/node1.csv f=class2 color=category a=class2c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $ip/edge1.csv xxnormE
	${lexe}m2gv.rb type=nest k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv -clusterLabel nc=class2c o=$op/test19.dot

	# nodeの線を太くする nw=3
	echo "# nodeの線を太くする nw=3"
	${lexe}mautocolor.rb i=$ip/node1.csv f=class1 color=category a=class1c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $ip/edge1.csv xxnormE
	${lexe}m2gv.rb type=nest k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv -clusterLabel nc=class1c nw=3 o=$op/test20.dot

# 数値項目によるグラデーションカラー
echo "# 数値項目によるグラデーションカラー"
	${lexe}mautocolor.rb i=$ip/node1.csv f=class3 color=FF0000,0000FF a=class3c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $ip/edge1.csv xxnormE
	${lexe}m2gv.rb type=nest k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv -clusterLabel nc=class3c nw=5 o=$op/test21.dot

	${lexe}mautocolor.rb i=$ip/node1.csv f=class4 color=FF0000,0000FF a=class4c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $ip/edge1.csv xxnormE
	${lexe}m2gv.rb type=nest k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv -clusterLabel nc=class4c nw=5 o=$op/test22.dot

	# nv,nc両方ラベルに入れる
	echo "# nv,nc両方ラベルに入れる"
	${lexe}mautocolor.rb i=$ip/node1.csv f=class1 color=category a=class1c o=xxcolor
	normalize support 3  nvv xxcolor       xxnormN
	normalize support 20 evv $ip/edge1.csv xxnormE
	${lexe}m2gv.rb type=nest k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv nl=node,support,class1 -clusterLabel nc=class1c nw=3 o=$op/test23.dot

	# 大きなデータ
	normalize support 2  nvv $ip/1477126924.2442381.node xxnormN
	normalize support 20 evv $ip/1477126924.2442381.edge xxnormE
	${lexe}m2gv.rb type=nest k=cluster ni=xxnormN nf=node nv=nvv ei=xxnormE ef=node1,node2 ev=evv el=support nl=node,support o=$op/test24.dot
}

base
color
edgeColor
nestedGraph
treeGraph
flatGraph
direction
exit
diff -r -q answer xxresult
diff -r answer xxresult > diffcheck.log

