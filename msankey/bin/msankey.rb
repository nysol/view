#!/usr/bin/env ruby
# encoding: utf-8

require "rubygems"
require "nysol/mcmd"
require "json"
require "nysol/viewjs"

# ver="1.0" # 初期リリース 2014/3/08
# ver="1.1" # -nl追加 2014/12/02
# ver="1.2" # h=追加 2014/12/03
$cmd=$0.sub(/.*\//,"")

$version=1.1
$revision="###VERSION###"

def help()

STDERR.puts <<EOF
----------------------------
#{$cmd} version #{$version}
----------------------------
概要) DAG(有向閉路グラフ)からsankeyダイアグラムをhtmlとして生成する。
書式) #{$cmd} i= f= v= [-nl] [h=] [w=] [o=] [t=] [T=] [--help]

  ファイル名指定
  i=     : 枝データファイル
  f=     : 枝データ上の2つの節点項目名
  v=     : 枝の重み項目名
  o=     : 出力ファイル(HTMLファイル)
  t=     : タイトル文字列
  h=     : キャンバスの高さ(デフォルト:500)
  w=     : キャンバスの幅(デフォルト:960)
  -nl    : 節点ラベルを表示しない

  その他
  T= : ワークディレクトリ(default:/tmp)
  --help : ヘルプの表示

入力形式)
有向閉路グラフを節点ペア、および枝の重みで表現したCSVファイル。

出力形式)
sankeyダイアグラムを組み込んだ単体のhtmlファイルで、
インターネットへの接続がなくてもブラウザがあれば描画できる。

備考)
本コマンドのチャート描画にはD3(http://d3js.org/)を用いている。
必要なrubyライブラリ: nysol/mcmd, json

例)
$ cat data/edge.csv 
node1,node2,val
a,b,1
a,c,2
a,d,1
a,e,1
b,c,4
b,d,3
b,f,1
c,d,2
c,e,2
d,e,1
e,f,3
n1,n2
$ #{$cmd} i=edge.csv f=node1,node2 v=val o=output.html
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

args=MCMD::Margs.new(ARGV,"i=,f=,v=,h=,w=,o=,t=,-nl,T=,--help","f=,v=")

# mcmdのメッセージは警告とエラーのみ
ENV["KG_VerboseLevel"]="2" unless args.bool("-mcmdenv")

#ワークファイルパス
if args.str("T=")!=nil then
	ENV["KG_TmpPath"] = args.str("T=").sub(/\/$/,"")
end

ei = args. file("i=","r") # edgeファイル名
ef = args.field("f=", ei) # edge始点node項目名,終了頂点項目名
ef1=ef2=nil
if ef then
	ef1=ef["names"][0]
	ef2=ef["names"][1]
	if ef1==nil or ef2==nil then
		raise "f= takes just two field names"
	end
	else
		unless int then
			raise "f= is mandatory unless -int is specified"
		end	
end
ev=args.field("v=",ei)
ev_wk=ev["names"][0]
oFile = args.file("o=", "w")
title=args.str("t=","")
nl=args.bool("-nl")
height=args.int("h=",500)
width=args.int("w=",960)

wf=MCMD::Mtemp.new

#ノードデータ処理
#与えられたノードファイルから番号を振る
nodefile=wf.file #"xxnode.csv"
pairfile=wf.file #"xxpair.csv"
w1_file=wf.file #"wk1.csv"
w2_file=wf.file #"wk2.csv"
system "mcut f=#{ef1}:nodes i=#{ei} o=#{w1_file}"
system "mcut f=#{ef2}:nodes i=#{ei} o=#{w2_file}"
f=""
f<<"mcat i=#{w1_file},#{w2_file} f=nodes |"
f<<"msortf f=nodes |"
f<<"muniq k=nodes |"
f<<"mnumber a=num s=nodes |"
f<<"msortf f=nodes o=#{nodefile}"
system(f)
system "rm #{w1_file}"
system "rm #{w2_file}"

#エッジファイル処理(ノード名→（mapfileから）数字)
f=""
f<<"mcut f=#{ef1}:nodes,#{ef2},#{ev_wk} i=#{ei} |"
f<<"msortf f=nodes |"
f<<"mjoin k=nodes m=#{nodefile} f=num:num1|"
f<<"mcut f=nodes:#{ef1},#{ef2}:nodes,#{ev_wk},num1 | "
f<<"msortf f=nodes|"
f<<"mjoin k=nodes m=#{nodefile} f=num:num2|"
f<<"mcut f=num1,num2,#{ev_wk} |"
f<<"msortf f=num1%n,num2%n o=#{pairfile}"
system (f)

#json作成
wk=[]
nodes=[]
links=[]
#f=open("chart.json","w")
#f.puts '{"nodes":'
MCMD::Mcsvin::new("i=#{nodefile}"){|csv|
    csv.each{|val|
        #        wk.push({:name=>val["nodes"]})
        nodes.push({:name=>val["nodes"]})
    }
}
nodes=nodes.to_json(nodes)
wk=[]
MCMD::Mcsvin::new("i=#{pairfile}"){|csv|
    csv.each{|val|
        links.push({:source=>val["num1"].to_i ,:target=>val["num2"].to_i , :value =>val["#{ev_wk}"].to_i})
    }
}

links=links.to_json(links)

#----
#以下htmlファイル作成
nolabel=""
nolabel="font-size: 0px;" if nl

outTemplate = <<OUT
<!DOCTYPE html>
<html class="ocks-org do-not-copy">
<meta charset="utf-8">
<!--
<title>Sankey Diagram</title>
-->
<title>#{title}</title>
<style>


<style>

body {
    font: 10px sans-serif;
}

svg {
    padding: 10px 0 0 10px;
}

.arc {
    stroke: #fff;
}

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

#chart {
height: 500px;
}

.node rect {
    cursor: move;
    fill-opacity: .9;
    shape-rendering: crispEdges;
}

.node text {
    pointer-events: none;
    text-shadow: 0 1px 0 #fff;
    #{nolabel}
}

.link {
    fill: none;
    stroke: #000;
    stroke-opacity: .2;
}

.link:hover {
    stroke-opacity: .5;
}

</style>
<body>

<!--
<h1>Sankey Diagrams</h1>
-->
<h1>#{title}</h1>

<p id="chart">


<script>
#{ViewJs::d3jsMin()}

d3.sankey = function() {
    var sankey = {},
    nodeWidth = 24,
    nodePadding = 8,
    size = [1, 1],
    nodes = [],
    links = [];
    
    sankey.nodeWidth = function(_) {
        if (!arguments.length) return nodeWidth;
            nodeWidth = +_;
            return sankey;
            };
            
            sankey.nodePadding = function(_) {
                if (!arguments.length) return nodePadding;
                    nodePadding = +_;
                    return sankey;
                    };
                    
                    sankey.nodes = function(_) {
                        if (!arguments.length) return nodes;
                            nodes = _;
                            return sankey;
                            };
                            
                            sankey.links = function(_) {
                                if (!arguments.length) return links;
                                    links = _;
                                    return sankey;
                                    };
                                    
                                    sankey.size = function(_) {
                                        if (!arguments.length) return size;
                                            size = _;
                                            return sankey;
                                            };
                                            
                                            sankey.layout = function(iterations) {
                                                computeNodeLinks();
                                                computeNodeValues();
                                                computeNodeBreadths();
                                                computeNodeDepths(iterations);
                                                computeLinkDepths();
                                                return sankey;
                                            };
                                            
                                            sankey.relayout = function() {
                                                computeLinkDepths();
                                                return sankey;
                                            };
                                            
                                            sankey.link = function() {
                                                var curvature = .5;
                                                
                                                function link(d) {
                                                    var x0 = d.source.x + d.source.dx,
                                                    x1 = d.target.x,
                                                    xi = d3.interpolateNumber(x0, x1),
                                                    x2 = xi(curvature),
                                                    x3 = xi(1 - curvature),
                                                    y0 = d.source.y + d.sy + d.dy / 2,
                                                    y1 = d.target.y + d.ty + d.dy / 2;
                                                    return "M" + x0 + "," + y0
                                                    + "C" + x2 + "," + y0
                                                    + " " + x3 + "," + y1
                                                    + " " + x1 + "," + y1;
                                                }
                                                
                                                link.curvature = function(_) {
                                                    if (!arguments.length) return curvature;
                                                        curvature = +_;
                                                        return link;
                                                        };
                                                        
                                                        return link;
                                                        };
                                                        
                                                        // Populate the sourceLinks and targetLinks for each node.
                                                        // Also, if the source and target are not objects, assume they are indices.
                                                        function computeNodeLinks() {
                                                            nodes.forEach(function(node) {
                                                                          node.sourceLinks = [];
                                                                          node.targetLinks = [];
                                                                          });
                                                                          links.forEach(function(link) {
                                                                                        var source = link.source,
                                                                                        target = link.target;
                                                                                        if (typeof source === "number") source = link.source = nodes[link.source];
                                                                                        if (typeof target === "number") target = link.target = nodes[link.target];
                                                                                        source.sourceLinks.push(link);
                                                                                        target.targetLinks.push(link);
                                                                                        });
                                                        }
                                                        
                                                        // Compute the value (size) of each node by summing the associated links.
                                                        function computeNodeValues() {
                                                            nodes.forEach(function(node) {
                                                                          node.value = Math.max(
                                                                                                d3.sum(node.sourceLinks, value),
                                                                                                d3.sum(node.targetLinks, value)
                                                                                                );
                                                                          });
                                                        }
                                                        
                                                        // Iteratively assign the breadth (x-position) for each node.
                                                        // Nodes are assigned the maximum breadth of incoming neighbors plus one;
                                                        // nodes with no incoming links are assigned breadth zero, while
                                                        // nodes with no outgoing links are assigned the maximum breadth.
                                                        function computeNodeBreadths() {
                                                            var remainingNodes = nodes,
                                                            nextNodes,
                                                            x = 0;
                                                            
                                                            while (remainingNodes.length) {
                                                                nextNodes = [];
                                                                remainingNodes.forEach(function(node) {
                                                                                       node.x = x;
                                                                                       node.dx = nodeWidth;
                                                                                       node.sourceLinks.forEach(function(link) {
                                                                                                                nextNodes.push(link.target);
                                                                                                                });
                                                                                       });
                                                                                       remainingNodes = nextNodes;
                                                                                       ++x;
                                                            }
                                                            
                                                            //
                                                            moveSinksRight(x);
                                                            scaleNodeBreadths((width - nodeWidth) / (x - 1));
                                                            }
                                                            
                                                            function moveSourcesRight() {
                                                                nodes.forEach(function(node) {
                                                                              if (!node.targetLinks.length) {
                                                                              node.x = d3.min(node.sourceLinks, function(d) { return d.target.x; }) - 1;
                                                                              }
                                                                              });
                                                            }
                                                            
                                                            function moveSinksRight(x) {
                                                                nodes.forEach(function(node) {
                                                                              if (!node.sourceLinks.length) {
                                                                              node.x = x - 1;
                                                                              }
                                                                              });
                                                            }
                                                            
                                                            function scaleNodeBreadths(kx) {
                                                                nodes.forEach(function(node) {
                                                                              node.x *= kx;
                                                                              });
                                                            }
                                                            
                                                            function computeNodeDepths(iterations) {
                                                                var nodesByBreadth = d3.nest()
                                                                .key(function(d) { return d.x; })
                                                                .sortKeys(d3.ascending)
                                                                .entries(nodes)
                                                                .map(function(d) { return d.values; });
                                                                
                                                                //
                                                                initializeNodeDepth();
                                                                resolveCollisions();
                                                                for (var alpha = 1; iterations > 0; --iterations) {
                                                                    relaxRightToLeft(alpha *= .99);
                                                                    resolveCollisions();
                                                                    relaxLeftToRight(alpha);
                                                                    resolveCollisions();
                                                                }
                                                                
                                                                function initializeNodeDepth() {
                                                                    var ky = d3.min(nodesByBreadth, function(nodes) {
                                                                                    return (size[1] - (nodes.length - 1) * nodePadding) / d3.sum(nodes, value);
                                                                                    });
                                                                                    
                                                                                    nodesByBreadth.forEach(function(nodes) {
                                                                                                           nodes.forEach(function(node, i) {
                                                                                                                         node.y = i;
                                                                                                                         node.dy = node.value * ky;
                                                                                                                         });
                                                                                                           });
                                                                                                           
                                                                                                           links.forEach(function(link) {
                                                                                                                         link.dy = link.value * ky;
                                                                                                                         });
                                                                }
                                                                
                                                                function relaxLeftToRight(alpha) {
                                                                    nodesByBreadth.forEach(function(nodes, breadth) {
                                                                                           nodes.forEach(function(node) {
                                                                                                         if (node.targetLinks.length) {
                                                                                                         var y = d3.sum(node.targetLinks, weightedSource) / d3.sum(node.targetLinks, value);
                                                                                                         node.y += (y - center(node)) * alpha;
                                                                                                         }
                                                                                                         });
                                                                                           });
                                                                                           
                                                                                           function weightedSource(link) {
                                                                                               return center(link.source) * link.value;
                                                                                           }
                                                                }
                                                                
                                                                function relaxRightToLeft(alpha) {
                                                                    nodesByBreadth.slice().reverse().forEach(function(nodes) {
                                                                                                             nodes.forEach(function(node) {
                                                                                                                           if (node.sourceLinks.length) {
                                                                                                                           var y = d3.sum(node.sourceLinks, weightedTarget) / d3.sum(node.sourceLinks, value);
                                                                                                                           node.y += (y - center(node)) * alpha;
                                                                                                                           }
                                                                                                                           });
                                                                                                             });
                                                                                                             
                                                                                                             function weightedTarget(link) {
                                                                                                                 return center(link.target) * link.value;
                                                                                                             }
                                                                }
                                                                
                                                                function resolveCollisions() {
                                                                    nodesByBreadth.forEach(function(nodes) {
                                                                                           var node,
                                                                                           dy,
                                                                                           y0 = 0,
                                                                                           n = nodes.length,
                                                                                           i;
                                                                                           
                                                                                           // Push any overlapping nodes down.
                                                                                           nodes.sort(ascendingDepth);
                                                                                           for (i = 0; i < n; ++i) {
                                                                                           node = nodes[i];
                                                                                           dy = y0 - node.y;
                                                                                           if (dy > 0) node.y += dy;
                                                                                           y0 = node.y + node.dy + nodePadding;
                                                                                           }
                                                                                           
                                                                                           // If the bottommost node goes outside the bounds, push it back up.
                                                                                           dy = y0 - nodePadding - size[1];
                                                                                           if (dy > 0) {
                                                                                           y0 = node.y -= dy;
                                                                                           
                                                                                           // Push any overlapping nodes back up.
                                                                                           for (i = n - 2; i >= 0; --i) {
                                                                                           node = nodes[i];
                                                                                           dy = node.y + node.dy + nodePadding - y0;
                                                                                           if (dy > 0) node.y -= dy;
                                                                                           y0 = node.y;
                                                                                           }
                                                                                           }
                                                                                           });
                                                                }
                                                                
                                                                function ascendingDepth(a, b) {
                                                                    return a.y - b.y;
                                                                }
                                                                }
                                                                
                                                                function computeLinkDepths() {
                                                                    nodes.forEach(function(node) {
                                                                                  node.sourceLinks.sort(ascendingTargetDepth);
                                                                                  node.targetLinks.sort(ascendingSourceDepth);
                                                                                  });
                                                                                  nodes.forEach(function(node) {
                                                                                                var sy = 0, ty = 0;
                                                                                                node.sourceLinks.forEach(function(link) {
                                                                                                                         link.sy = sy;
                                                                                                                         sy += link.dy;
                                                                                                                         });
                                                                                                node.targetLinks.forEach(function(link) {
                                                                                                                         link.ty = ty;
                                                                                                                         ty += link.dy;
                                                                                                                         });
                                                                                                });
                                                                                                
                                                                                                function ascendingSourceDepth(a, b) {
                                                                                                    return a.source.y - b.source.y;
                                                                                                }
                                                                                                
                                                                                                function ascendingTargetDepth(a, b) {
                                                                                                    return a.target.y - b.target.y;
                                                                                                }
                                                                }
                                                                
                                                                function center(node) {
                                                                    return node.y + node.dy / 2;
                                                                }
                                                                
                                                                function value(link) {
                                                                    return link.value;
                                                                }
                                                                
                                                                return sankey;
                                                                };
</script>

<script>
var margin = {top: 1, right: 1, bottom: 6, left: 1},
    width = #{width} - margin.left - margin.right,
    height = #{height} - margin.top - margin.bottom;

var formatNumber = d3.format(",.0f"),
    format = function(d) { return formatNumber(d) + " TWh"; },
    color = d3.scale.category20();

var svg = d3.select("#chart").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    var sankey = d3.sankey()
    .nodeWidth(15)
    .nodePadding(10)
    .size([width, height]);

var path = sankey.link();

//d3.json("./chart.json", function(energy) {
//        var aaa=#{wk}
        var nodes=#{nodes}
        var links=#{links}
        sankey
 //           .nodes(energy.nodes)
 //          .links(energy.links)
        .nodes(nodes)
        .links(links)

          .layout(32);
        
        var link = svg.append("g").selectAll(".link")
 //           .data(energy.links)
        .data(links)
        .enter().append("path")
            .attr("class", "link")
            .attr("d", path)
            .style("stroke-width", function(d) { return Math.max(1, d.dy); })
            .sort(function(a, b) { return b.dy - a.dy; });
        
        link.append("title")
            .text(function(d) { return d.source.name + " → " + d.target.name + "" + format(d.value); });
        
        var node = svg.append("g").selectAll(".node")
//             .data(energy.nodes)
        .data(nodes)
        .enter().append("g")
            .attr("class", "node")
            .attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; })
            .call(d3.behavior.drag()
              .origin(function(d) { return d; })
              .on("dragstart", function() { this.parentNode.appendChild(this); })
              .on("drag", dragmove));
        
        node.append("rect")
            .attr("height", function(d) { return d.dy; })
            .attr("width", sankey.nodeWidth())
            .style("fill", function(d) { return d.color = color(d.name.replace(/ .*/, "")); })
            .style("stroke", function(d) { return d3.rgb(d.color).darker(2); })
            .append("title")
            .text(function(d) { return d.name + "" + format(d.value); });
        
        node.append("text")
            .attr("x", -6)
            .attr("y", function(d) { return d.dy / 2; })
            .attr("dy", ".35em")
            .attr("text-anchor", "end")
            .attr("transform", null)
            .text(function(d) { return d.name; })
            .filter(function(d) { return d.x < width / 2; })
            .attr("x", 6 + sankey.nodeWidth())
            .attr("text-anchor", "start");
        
        function dragmove(d) {
            d3.select(this).attr("transform", "translate(" + d.x + "," + (d.y = Math.max(0, Math.min(height - d.dy, d3.event.y))) + ")");
            sankey.relayout();
            link.attr("d", path);
        }
//    });
</script>
OUT
File.open(oFile,"w"){|fp|
	fp.puts outTemplate
}
