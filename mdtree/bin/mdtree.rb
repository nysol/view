#!/usr/bin/env ruby
#-*- coding: utf-8 -*-

require 'rubygems'
require 'nysol/mcmd'
require 'nysol/viewjs'
require 'rexml/document'

$version=1.0
$revision="###VERSION###"

def help

STDERR.puts <<EOF
------------------------
mdtree.rb version #{$version}
------------------------
概要) PMMLで記述された決定木モデルのHTMLによる視覚化
書式) mdtree.rb i= o= [alpha=] [--help]

  i=     : PMMLファイル名
  o=     : 出力ファイル名(HTMLファイル)
  alpha= : 枝刈り度を指定する (0 以上の実数で、大きくすると枝が多く刈られる)。
         : 指定しなかった場合、mbonsai で交差検証を指定しなければ、
         : 0.01 が指定されたことになり、交差検証を指定していれば、誤分類率最小のモデルが描画される。
         : このパラメータは mbonsai で構築した決定木のみ有効。
  -bar   : ノードを棒グラフ表示にする
  --help : ヘルプの表示

備考)
本コマンドのチャート描画にはD3(http://d3js.org/)を用いている。

利用例)
$ mbonsai c=入院歴 n=来店距離 p=購入パターン d=性別 i=dat1.csv O=outdat
$ mdtree.rb i=outdat/model.pmml o=model.html
$ mdtree.rb alpha=0.1 i=outdat/model.pmml o=model2.html

Copyright(c) NYSOL 2012- All Rights Reserved.
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


class Pmml

	@@condmap = {
		"lessOrEqual"=>"<=","greaterThan"=>">","greaterOrEqual"=>">=",
		"equal"=>"==","notEqual"=>"!=","lessThan"=>"<"
	}
	
	def condCKsub(xstr)
		notFlg=false
		cond_str =""
		cond=[]
		if xstr.attributes['booleanOperator'] == "isIn" then
			xstr.elements["Array"].each{|astr|
				astr.to_s.split(" ").each{|astrs|
					cond << REXML::Text.unnormalize(astrs).gsub(/^\"/,"").gsub(/\"$/,"")
				}
			}
		elsif xstr.attributes['booleanOperator'] == "isNotIn" then
			cond_str = "else"
			notFlg=true
		end

		unless notFlg then
			cond_str = "{#{cond.join(',')}}"
		end
		return cond_str
	end

	def condCK(xstr)
		cond_str =""
		if xstr.elements["SimplePredicate"] then
			con = xstr.elements["SimplePredicate"]
			if @@condmap[con.attributes['operator']] ==nil then
				raise("UNKNOW FORMAT (#{con.attributes['operator']})")
			end
			cond_str = " #{@@condmap[con.attributes['operator']]} #{con.attributes['value']}"
		elsif xstr.elements["SimpleSetPredicate"] then
			cond_str = condCKsub(xstr.elements["SimpleSetPredicate"])
		elsif xstr.elements["CompoundPredicate"] then
			if xstr.elements["CompoundPredicate"].attributes["booleanOperator"] == "surrogate" then
				xstr.elements["CompoundPredicate"].each_element{|x| 
					if x.name["SimplePredicate"] then
						if @@condmap[x.attributes['operator']] ==nil then
							raise("UNKNOW FORMAT (#{x.attributes['operator']})")
						end
						cond_str = " #{@@condmap[x.attributes['operator']]} #{x.attributes['value']}"
						return cond_str 
					elsif  x.name["SimpleSetPredicate"] then
						cond_str = condCKsub(x)
						return cond_str 
					end
				}
			else
				raise("UNKNOW FORMAT (#{xstr.elements['CompoundPredicate'].attributes['booleanOperator']})")
			end
		elsif xstr.elements["Extension/SimplePredicate"] then
			con = xstr.elements["Extension/SimplePredicate"]
			val = []
			if con.attributes['operator'] == "notcontain" then
				cond_str = "else"
			elsif con.attributes['operator'] == "contain" then
				con.elements.each("index"){|idx|
					val << idx.attributes['value']
				}
				cond_str = "#{val.join}"
			end
		end
		
		return cond_str
	end

	def getFld(chd)
		fld = ""
		if chd.elements["CompoundPredicate"] then
			chd.elements["CompoundPredicate"].each_element{|x| 
				if x.attributes['field'] then
					fld = x.attributes['field'] 
					break
				end
			}
		elsif chd.elements["SimplePredicate"] then
			fld =chd.elements["SimplePredicate"].attributes['field']
		elsif chd.elements["SimpleSetPredicate"] then
			fld =chd.elements["SimpleSetPredicate"].attributes['field']
		elsif chd.elements["Extension/SimplePredicate"] then
			fld =chd.elements["Extension/SimplePredicate"].attributes['field']
		end
		return fld
	end


	def nodeDiv(xstr)

		score={}
		scal=0.0
		smax=0.0
		c_p = 0.0
		xstr.elements.each("ScoreDistribution"){|sc|
			score[sc.attributes['value']]=sc.attributes['recordCount'] 
			scal = scal + sc.attributes['recordCount'].to_f	
			smax = sc.attributes['recordCount'].to_f	 if sc.attributes['recordCount'].to_f > smax 
		}
		@scoreMin = scal if @scoreMin == nil or @scoreMin > scal
		@scoreMax = scal if @scoreMax == nil or @scoreMax < scal

		if xstr.elements["Extension"] then
			if xstr.elements["Extension"].attributes['name'] == "complexity penalty" then
				c_p = xstr.elements["Extension"].attributes['value'].to_f
			end
		end

		#リーフ処理
		if xstr.elements["Node"] == nil || c_p < @alpha then
			#id = xstr.attributes["id"]	
			id = @ncount
			@ncount += 1
			@nodes << {"label"=>"#{condCK(xstr)}","id"=>"#{id}","nodeclass"=>"type-leaf","score"=>score,"scal"=>smax}
			return id	
		end

		#ノード処理
		#id = xstr.attributes["id"]
		id = @ncount
		@ncount += 1

		fld=""
		xstr.elements.each("Node"){|child|
			toId = nodeDiv(child)
			fld = getFld(child)
			@edges << { "source"=>"#{id}","target"=>"#{toId}","id"=>"#{id}-#{toId}"}
		}
		lbl= "<table><tr><td align='center'>#{condCK(xstr)}<br/></td></tr><tr><td><br/></td></tr><tr><td align='center'>#{fld}<br/></td></tr></table>"
		lbl= "#{condCK(xstr)}@#{fld}"
		@nodes << {"label"=>"#{lbl}","id"=>"#{id}","nodeclass"=>"type-node","score"=>score ,"scal"=>smax}
		return id
	end

	def getSchem(xstr)
		xstr.elements.each("MiningField"){|sc|
			fld =sc.attributes['name']
			if sc.elements["Extension/alphabetIndex"] then
				idx = []
				sc.elements.each("Extension/alphabetIndex"){|aidx|
					idx[aidx.attributes['index'].to_i] =[] unless idx[aidx.attributes['index'].to_i]
					idx[aidx.attributes['index'].to_i] << aidx.attributes['alphabet']
				}
				@pidx[fld] = idx
			end
		}	
	end

	def setAlpha(xstr)
		al_se1 = al_min = al = -1
		xstr.elements.each("Extension"){|sc|
			if sc.attributes['name'] == "1SE alpha" then
				al_se1 = sc.attributes['value'].to_f
			elsif sc.attributes['name'] == "min alpha" then
				al_min = sc.attributes['value'].to_f
			elsif sc.attributes['name'] == "alpha" then
				al = sc.attributes['value'].to_f
			end
		}
		if @alpha == "min" then
			raise "can not use alpha=min or alpha=1se in this model" if al_min == -1 
			@alpha = al_min
		elsif  @alpha == "se1" then
			raise "can not use alpha=min or alpha=1se in this model" if al_se1 == -1 
			@alpha = al_se1
		elsif @alpha == nil then
			if al==-1 then
			 @alpha=al_min 
			else
			 @alpha=al 
			end
		else
			@alpha = @alpha.to_f
		end 
	end


	def initialize(fn,alpha)
		begin
			@alpha = alpha
			xml = REXML::Document.new(open(fn))
			@timestamp = xml.elements["/PMML/Header/Timestamp"].text
			@dd =[]
			xml.elements.each("/PMML/DataDictionary/DataField"){|dd|
				@dd << dd.attributes["name"]	
			}
			@nodes =[]
			@edges =[]
			@pidx ={}
			@scoreMin=nil
			@scoreMax=nil
			@ncount=0
			setAlpha(xml.elements["/PMML/TreeModel"])

			getSchem(xml.elements["/PMML/TreeModel/MiningSchema"])
			nodeDiv(xml.elements["/PMML/TreeModel/Node"])
		rescue=>msg	
			p msg.backtrace
			raise "XML parsing error #{msg}"
		end
	
	end
	def nodeList(barFLG=false)
		str=[]
		@nodes.each{|val|
			c_str=[]
			scal =0.0
				val["score"].each{|k,v|
					c_str << "{name:\"#{k}\",csvValue:\"#{v}\",smax:\"#{val['scal']}\"}"	
					scal += v.to_f
				}
			size = ( scal - @scoreMin ).to_f / ( @scoreMax - @scoreMin ).to_f + 1.0
			str << "\t#{val['id']}:{label:\"#{val['label']}\",id:\"#{val['id']}\",nodeclass:\"#{val['nodeclass']}\",score:[#{c_str.join(',')}],sizerate:\"#{size}\"}"
		}
		return str.join(",\n")
	end


	def edgeList
		str=[]
		@edges.each{|val|
			str << "\t{source:\"#{val['source']}\",target:\"#{val['target']}\",id:\"#{val['id']}\"}"
		}
		return str.join(",\n")
	end
	def legendList
		str=[]
		@nodes[0]["score"].each{|k,v|
			str << "\"#{k}\""
		}
		return str.join(",")
	end
	def indexList
		strA=[]
		@pidx.each{|k,v|
			str=[]
			next unless v
			v.each_index{|i|
				next unless v[i]
				str << "\"#{v[i].join(',')}\"" 
			}
			strA << "{name:\"#{k}\",val:[#{str.join(',')}]}"
		}
		return strA.join(",\n")

	end
	def data_max
		return @scoreMax
	end


end

# パラメータ処理
args=MCMD::Margs.new(ARGV,"i=,o=,alpha=,-bar","i=,o=")
file_i = args.file("i=","r") 
file_o = args.file("o=","w") 
alpha =  args.str("alpha=") 
barflg =  args.bool("-bar") 

pm =  Pmml.new(file_i,alpha)
nodedata=pm.nodeList(barflg)
edgedata=pm.edgeList
legenddata=pm.legendList
indexdata=pm.indexList
d_max = pm.data_max



bar_node= <<BAROUT
 /*barグラフ挿入*/
   nodeEnter
     .append("g")
     .attr("class","bar")
     .selectAll(".arc").data(function(d) 
     { 
     	return d.score 
     })
     .enter()
 	  .append("rect")
   	.attr("class", "arc")
     .attr("x", function(d,i) { return -barSizeMaX/2+i*(barSizeMaX/legands.length)+rPading; })
     .attr("y", function(d)   { return -(barSizeMaX/d.smax*d.csvValue-barSizeMaX/2); })
     .attr("width", (barSizeMaX/legands.length-rPading*2))
     .attr("height", function(d) { return barSizeMaX/d.smax*d.csvValue; })
     .style("fill", function(d,i) { return dictColor(i); })
     .on("mouseover", function(d) {
 			d3.select("#tooltip")
         .style("left", (d3.event.pageX+10) +"px")
         .style("top", (d3.event.pageY-10) +"px")
 				.select("#value")
 				.text( d.name + " : " + d.csvValue );
          d3.select("#tooltip").classed("hidden",false);
     })
     .on("mouseout", function() {
       d3.select("#tooltip").classed("hidden", true);
     });
 	function calSize(d){
 	}
BAROUT

pie_node = <<PIEOUT
 /*Pieグラフ挿入*/
  nodeEnter
    .append("g")
    .attr("class","pie")
    .selectAll(".arc").data(function(d) 
    { 
    	return pie(d.score) 
    })
    .enter()
	  .append("path")
  	.attr("class", "arc")
    .attr("d",  d3.svg.arc().outerRadius(radius))
    .style("fill", function(d,i) { return dictColor(i); })
    .on("mouseover", function(d) {
			d3.select("#tooltip")
        .style("left", (d3.event.pageX+10) +"px")
        .style("top", (d3.event.pageY-10) +"px")
				.select("#value")
				.text( d.data.name + " : " + d.data.csvValue );
         d3.select("#tooltip").classed("hidden",false);
    })
    .on("mouseout", function() {
      d3.select("#tooltip").classed("hidden", true);
    });
	function calSize(d){
	}
PIEOUT

graph_dips = pie_node
graph_dips = bar_node if barflg
	

outTemplate = <<OUT
<html lang="ja">
<head>
  <meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style type="text/css">
	  p.title { border-bottom: 1px solid gray;}
		g > .type-node > rect { stroke-dasharray: 10,5; stroke-width: 3px; stroke: #333; fill: white; }
		g > .type-leaf > rect { stroke-width: 3px; stroke: #333; fill: white;}
		.edge path {  fill: none;  stroke: #333; stroke-width: 1.5px;}
		svg >.legend > rect { stroke-width: 1px; stroke: #333; fill: none}
		svg > .pindex > .pindexL > rect { stroke-width: 1px; stroke: #333;  fill: none; }

#tooltip {
  position: absolute;
  width: 150px;
  height: auto;
  padding: 10px;
  background-color: white;
  -webkit-border-radius: 10px;
  -moz-border-radius: 10px;
  border-radius: 10px;
  -webkit-box-shadow: 4px 4px 10px rgba(0,0,0,0.4);
  -moz-box-shadow: 4px 4px 10px rgba(0,0,0,0.4);
  box-shadow: 4px 4px 10px rgba(0,0,0,0.4);
  pointer-events: none;
}

#tooltip.hidden {
  display: none;
}

#tooltip p {
  margin: 0;
  font-family: sans-serif;
  font-size: 10px;
  line-height: 14px;
}
  </style>

</head>
<body>
<div id="attach">
  <svg class="main-svg" id="svg-canvas" height="100000" width="100000"></svg>
</div>
<script>

#{ViewJs::dgreejsMin()}



/*--- dagre-d3-simple.js -----*/
/*
 *  Render javascript edges and nodes to the svg.  This method should be more
 *  convenient when data was serialized as json and node definitions would be duplicated
 *  if edges had direct references to nodes.  See state-graph-js.html for example.
 */
function renderJSObjsToD3(nodeData, edgeData, svgSelector) {
  var nodeRefs = [];
  var edgeRefs = [];
  var idCounter = 0;

  edgeData.forEach(function(e){
    edgeRefs.push({
      source: nodeData[e.source],
      target: nodeData[e.target],
      label: e.label,
      id: e.id !== undefined ? e.id : (idCounter++ + "|" + e.source + "->" + e.target)
    });
  });
	// ↓これ必要？
  for (var nodeKey in nodeData) {
    if (nodeData.hasOwnProperty(nodeKey)) {
      var u = nodeData[nodeKey];
      if (u.id === undefined) {
        u.id = nodeKey;
      }
      nodeRefs.push(u);
    }
  }
  
  renderDagreObjsToD3({nodes: nodeRefs, edges: edgeRefs}, svgSelector);
}

/*
 *  Render javscript objects to svg, as produced by  dagre.dot.
 */
function renderDagreObjsToD3(graphData, svgSelector) 
{
	/* 描画用設定値 */
	var radius = 10.0; 		// 円グラフ最小半径
	var rPading = 2.0; 		// 円隙間サイズ
	var rectSize = radius*4.0+rPading*2.0; // 円格納枠サイズ
	var barSizeMaX = radius*4.0; // barサイズMAX
	var charH= 18.0; 			 // 文字高さ
	var legendSize = 16.0; // 凡例マーカーサイズ
	var tMaxX=0;  			// テーブル表示サイズX
	var tMaxY=0;	 			// テーブル表示サイズX
	var tPadding=2.0; 	// テーブル隙間サイズX

	var pie = d3.layout.pie() 
    .sort(null)
    .value(function(d) { return d.csvValue; }); 

	/* ノードデータ,エッジデータ,描画場所*/
  var nodeData = graphData.nodes;
  var edgeData = graphData.edges;
  var svg = d3.select(svgSelector);


	// エッジ種類定義
  if (svg.select("#arrowhead").empty()) {
    svg.append('svg:defs').append('svg:marker')
      .attr('id', 'arrowhead')
      .attr('viewBox', '0 0 10 10')
      .attr('refX', 8)
      .attr('refY', 5)
      .attr('markerUnits', 'strokewidth')
      .attr('markerWidth', 8)
      .attr('markerHeight', 5)
      .attr('orient', 'auto')
      .attr('style', 'fill: #333')
      .append('svg:path')
      .attr('d', 'M 0 0 L 10 5 L 0 10 z');
  }

	/* 描画領域初期化 */
  svg.selectAll("g").remove();	
  var svgGroup = svg.append("g");

	/* ------------------------------- 
		ノード関係 
	------------------------------- */
	/* ノード領域追加 */
  var nodes = svgGroup
    .selectAll("g .node")
    .data(nodeData);

	/* ノード 属性追加 class & id */
  var nodeEnter = nodes
    .enter()
    .append("g")
    .attr("class", function (d) {
      if (d.nodeclass) {  return "node " + d.nodeclass;} 
      else             {  return "node"; }
    })
    .attr("id", function (d) {
      return "node-" + d.id;
    })
    
	/* 枠追加 */
  nodeEnter.append("rect").attr("class", "body");;

	/* ノードHEADラベル追加 */
	nodeEnter
    .append("text")
    .attr("class", "head")
	  .attr("text-anchor", "middle")
    .text(function (d) {
    	var sp = d.label.split("@") ;
      return sp[0];
    });

	/* ノードFOOTラベル追加 */
	nodeEnter
    .append("text")
    .attr("class", "foot")
    .attr("text-anchor", "middle")
    .text(function (d) {
    	var sp = d.label.split("@") 
    	if(sp.length < 2){ return "";}
    	else						 {return sp[1];}
    });

  /* グラフ挿入 */
#{graph_dips}

	/* ノードサイズ設定*/
	var nodeSize = []
	nodes.selectAll("g text").each(function (d) {
		if(nodeSize[d.id]==undefined){
			nodeSize[d.id]=[rectSize,rectSize]
		}
    var bbox = this.getBBox();
		nodeSize[d.id][1]+=charH 
		if(nodeSize[d.id][0]<bbox.width){nodeSize[d.id][0]=bbox.width} 
	})
	nodes
    .each(function (d,i) {
      d.width = nodeSize[i][0]; 
      d.height = nodeSize[i][1];
    });

	/* ------------------------------- 
		エッジ関係 
	------------------------------- */
  var edges = svgGroup
    .selectAll("g .edge")
    .data(edgeData);

  var edgeEnter = edges
    .enter()
    .append("g")
    .attr("class", "edge")
    .attr("id", function (d) { return "edge-" + d.id; })

  edgeEnter
    .append("path")
    .attr("marker-end", "url(#arrowhead)");

	/* ------------------------------- 
		凡例関係 
	------------------------------- */
	var legandX=0; // 凡例表示サイズX
	var legandY=0; // 凡例表示サイズY

  var legend = svg.append("svg")
      .attr("class", "legend")
    	.selectAll("g")
      .data(legands)
    	.enter().append("g")
      .attr("class","legandL")

  legend
  		.append("rect")
      .attr("width" , legendSize)
      .attr("height", legendSize)
      .style("fill", function(d, i) { return dictColor(i); });

  legend.append("text")
      .attr("x", 20)
      .attr("y", 9)
      .attr("dy", ".35em")
      .text(function(d) { return d; });

	svg.select("svg.legend")
		.append("text")
    .attr("x", 0)
    .attr("y", 9)
    .attr("dy", ".35em")
		.text("Legend")

	svg.select("svg.legend")
	.each(function() {
    dd=this.getBBox();
		tMaxX = dd.width;
		tMaxY = dd.height;
	})
	
	svg.select("svg.legend")
		.selectAll("g.legandL")
		.each(function() {
  	  dd=this.getBBox();
  	  if(legandX<dd.width){ legandX = dd.width;}
			legandY += dd.height;
			if(tMaxX<dd.width){ tMaxX = dd.width;}
		})

	svg.select("svg.legend")
		.append("rect")
    .attr("x", 0)
    .attr("y", 18)
    .attr("width" , legandX + tPadding*2)
    .attr("height", legandY + tPadding*(legands.length+1))

	tMaxY += (charH+tPadding)*legands.length

	legend
		.attr("transform", function(d,i) { 
			return  "translate(0," + (charH+(charH+tPadding)*i+tPadding) + ")"; 
		}
		);

	/* ------------------------------- 
		パターンindex関係
	------------------------------- */
	var indexX_K =[]; // index表示サイズX_key
	var indexX_V =[]; // index表示サイズX_val
	var indexX_R =[]; // index表示サイズReal
	var indexY_S=[]; 		// index表示開始位置Y

	var iposY = tMaxY + (charH+tPadding)

  var pindex = svg.append("svg")
      .attr("class", "pindex")
      .attr("y", iposY)
    	.selectAll("g")
      .data(ptnidxs)
    	.enter().append("g")
      .attr("class","pindexL")
		  .attr("id",(function(d,i) { return "a"+i;}));


  pindex
  	.append("text")
	  .attr("class","name")
    .text(function(d) { 
    	return d.name;
    });

  pindex
  	.append("text")
	  .attr("class","headerK")
    .text(function(d) { return "index";});

  pindex
	  .append("rect")
	  .attr("class","headerK")

  pindex
  	.append("text")
	  .attr("class","headerV")
    .text(function(d) { return "alphabet";});

  pindex
	  .append("rect")
	  .attr("class","headerV")


	pindex
		.selectAll("g.pidx")
		.data(function(d){return d.val})
		.enter()
	  .append("text")
	  .attr("class","no")
    .text(function(d,j) { return j+1 ;});

	pindex
		.selectAll("g.pidx")
		.data(function(d){return d.val})
		.enter()
	  .append("rect")
	  .attr("class","no")

	pindex
		.selectAll("g.pidx")
		.data(function(d){return d.val})
		.enter()
	  .append("text")
	  .attr("class","idx")
    .text(function(d,j) { return d ;});

	pindex
		.selectAll("g.pidx")
		.data(function(d){return d.val})
		.enter()
	  .append("rect")
	  .attr("class","idx")


	//幅チェック
	var indexYT = (charH*2+tPadding);
	for(var i=0 ;i<ptnidxs.length;i++){
		var indexX_KT = 0;
		var indexX_VT = 0;

		svg.select("svg.pindex")
			.selectAll("#a"+i)
			.selectAll("text.name")
			.each(function() {
  		  var dd=this.getBBox();
				if(tMaxX<dd.width){ tMaxX = dd.width;}
				indexX_R[i]=dd.width
			})

		svg.select("svg.pindex")
			.selectAll("#a"+i)
			.selectAll("text.headerK")
			.each(function() {
  	  	var dd=this.getBBox();
  	 		if(indexX_KT<dd.width){ indexX_KT = dd.width;}
			})


		svg.select("svg.pindex")
			.selectAll("#a"+i)
			.selectAll("text.headerV")
			.each(function() {
  	  	var dd=this.getBBox();
  	 		if(indexX_VT<dd.width){ indexX_VT = dd.width;}
			})


		svg.select("svg.pindex")
			.selectAll("#a"+i)
			.selectAll("text.no")
			.each(function() {
  	  	var dd=this.getBBox();
  	 		if(indexX_KT<dd.width){ indexX_KT = dd.width;}
			})
		svg.select("svg.pindex")
			.selectAll("#a"+i)
			.selectAll("text.idx")
			.each(function() {
  	  	var dd=this.getBBox();
  	 		if(indexX_VT<dd.width){ indexX_VT = dd.width;}
			})
			indexX_K.push(indexX_KT)
			indexX_V.push(indexX_VT)
			if(indexX_R[i]<indexX_VT+indexX_KT+tPadding*2){
				indexX_R[i]=indexX_VT+indexX_KT+tPadding*2
			}
			if(tMaxX<indexX_R[i]){
				tMaxX = indexX_R[i]
			}
			indexY_S.push(indexYT)
			indexYT += (ptnidxs[i].val.length+3)*(charH+tPadding);
			console.log(indexYT)
	}

	if (ptnidxs.length!=0){
		svg.select("svg.pindex")
		.append("text")
    .attr("y", 9)
    .attr("dy", ".35em")
		.text("Alphabet Index")
	}

	//グループ内配置
	for(var i=0 ;i<ptnidxs.length;i++){
		arrange = svg.select("svg.pindex").selectAll("#a"+i)
		arrange
			.selectAll("text.headerK")
			.attr("x",function(d,j){ return tPadding })
			.attr("y",function(d,j){ return (charH+tPadding) })

		arrange
			.selectAll("text.headerV")
			.attr("y",function(d,j){ return (charH+tPadding) })
			.attr("x",function(d,j){ return indexX_K[i]+tPadding*3 })

		arrange
			.selectAll("text.no")
			.attr("x",function(d,j){ return tPadding })
			.attr("y",function(d,j){ return (j+2)*(charH+tPadding) })
		arrange
			.selectAll("text.idx")
			.attr("y",function(d,j){ return (j+2)*(charH+tPadding) })
			.attr("x",function(d,j){ return indexX_K[i]+tPadding*3 })

		arrange
			.selectAll("rect.headerK")
			.attr("width",function(d,j){ return indexX_K[i]+tPadding*2 })
			.attr("height",function(d,j){ return charH+tPadding })
			.attr("y",function(d,j){ return tPadding })

		arrange
			.selectAll("rect.headerV")
			.attr("width",function(d,j){ return indexX_V[i]+tPadding*2 })
			.attr("height",function(d,j){ return charH+tPadding })
			.attr("x",function(d,j){ return indexX_K[i]+tPadding*2 })
			.attr("y",function(d,j){ return tPadding })

		arrange
			.selectAll("rect.no")
			.attr("width",function(d,j){ return indexX_K[i]+tPadding*2 })
			.attr("height",function(d,j){ return charH+tPadding })
			.attr("y",function(d,j){ return (j+1)*(charH+tPadding)+tPadding })

		arrange
			.selectAll("rect.idx")
			.attr("width",function(d,j){ return indexX_V[i]+tPadding*2 })
			.attr("height",function(d,j){ return charH+tPadding })
			.attr("x",function(d,j){ return indexX_K[i]+tPadding*2 })
			.attr("y",function(d,j){ return (j+1)*(charH+tPadding)+tPadding })
	}
	console.log(indexY_S)
	//全体配置
	svg.select("svg.pindex")
  	.selectAll("g.pindexL")
		.attr("transform", function(d,i) { 
			var rtnstr = "translate(0," + indexY_S[i] + ")"; 
			return rtnstr;
		}
		);


  // Add zoom behavior to the SVG canvas
  svgGroup.attr("transform", "translate("+tMaxX+", 5)")

  svg.call(d3.behavior.zoom().on("zoom", function redraw() {
		dx =  tMaxX + d3.event.translate[0]
		dy =  5 + d3.event.translate[1]
    svgGroup.attr("transform",
      "translate(" + dx +"," + dy+ ")" + " scale(" + d3.event.scale + ")");
  }));
  
  // Run the actual layout
  dagre.layout()
    .nodes(nodeData)
    .edges(edgeData)
    .run();

	/* ------------------------------- 
	 ノード表示位置移動
	 --------------------------------- */
  nodes
    .attr("transform", function (d) {
      return "translate(" + d.dagre.x + "," + d.dagre.y + ")";
    })
		.selectAll("g.node rect.body")
    .attr("rx", 5)
    .attr("ry", 5)
    .attr("x", function (d) { return -(rectSize/2);})
    .attr("y", function (d) { return -(rectSize/2);})
    .attr("width", function (d) { return rectSize;})
    .attr("height", function (d) { return rectSize; });

  nodes
    .selectAll("text.foot")
    .attr("transform", function (d) {
      return "translate(" + 0 + "," + (d.height/2) + ")";
    });

  nodes
    .selectAll("text.head")
    .attr("transform", function (d) {
      return "translate(" + 0   + "," + -( radius*2+rPading*2) + ")";
    });

  nodes.selectAll("g.pie")
    .attr("transform", function (d) { return "scale("+ d.sizerate +")" ;} );


	/* ------------------------------- 
	 エッジ表示位置移動
	 --------------------------------- */
  edges
    .selectAll("path")
    .attr("d", function (d) {
      var points = d.dagre.points.slice(0);
      points.unshift(dagre.util.intersectRect(d.source.dagre, points[0]));

      var preTarget = points[points.length - 2];
      var target = dagre.util.intersectRect(d.target.dagre, points[points.length - 1]);

      //  This shortens the line by a couple pixels so the arrowhead won't overshoot the edge of the target
      var deltaX = preTarget.x - target.x;
      var deltaY = preTarget.y - target.y;
      var m = 2 / Math.sqrt(Math.pow(deltaX, 2) + Math.pow(deltaY, 2));
      points.push({
          x: target.x + m * deltaX,
          y: target.y + m * deltaY
        }
      );
      return d3.svg.line()
        .x(function (e) {
          return e.x;
        })
        .y(function (e) {
          return e.y;
        })
        .interpolate("bundle")
        .tension(.8)
        (points);
    });

  edges
    .selectAll("g.label")
    .attr("transform", function (d) {
      var points = d.dagre.points;
      if (points.length > 1) {
        var x = (points[0].x + points[1].x) / 2;
        var y = (points[0].y + points[1].y) / 2;
        return "translate(" + (-d.bbox.width / 2 + x) + "," + (-d.bbox.height / 2 + y) + ")";
      } else {
        return "translate(" + (-d.bbox.width / 2 + points[0].x) + "," + (-d.bbox.height / 2 + points[0].y) + ")";
      }
    });
    

  var tooltip = d3.select("body").append("div")
      .attr("id", "tooltip")
      .attr("class", "hidden")
      .append("p")
      .attr("id", "value")
    	.text("0");
}

	// 色決定関数
function dictColor(i){
	var colorSet = [ [70,130,180],[144,238,144],[238,232,170],
 									[139,0,0],[0,139,0],[0,0,139]]
	var sur = i % colorSet.length;
	var div = (i-sur) / colorSet.length;
	var r =colorSet[sur][0]+div*20;
	var g =colorSet[sur][1]+div*20;
	var b =colorSet[sur][2]+div*20;
	if(r>255){ r=255;}
	if(g>255){ g=255;}
	if(b>255){ b=255;}
	return "rgb(" + r + ","+ g + "," + b + ")"
}


var nodes=
{
#{nodedata}
};

var edges=[
#{edgedata}
];

var legands=[
#{legenddata}
];

var ptnidxs=[
#{indexdata}
];


renderJSObjsToD3(nodes, edges, ".main-svg");
</script>
</body>
</html>
OUT



File.open(file_o,"w"){|fp|
	fp.puts outTemplate
}


# 終了メッセージ
MCMD::endLog(args.cmdline)

