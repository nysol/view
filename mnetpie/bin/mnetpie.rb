#!/usr/bin/env ruby
#encoding:utf-8

require "rubygems"
require "nysol/mcmd"
require "nysol/viewjs"

$cmd = $0.sub(/.*\//,"")

$version = 1.0
$revision = "###VERSION###"

def help ()

STDERR.puts <<EOF
------------------------
#{$cmd} version #{$version}
------------------------
概要) Nodeデータ&EdgeファイルからグラフD3を使ったHTMLを作成する

書式) #{$cmd} ni= ei= ef= nf= [nodeSizeFld=] [nodeColorFld=] [edgeWidthFld=]  [edgeColorFld=] pieDataFld= pieTipsFld= picFld= o= -undirect

circle pieChart 画像 をNodeとして利用可能

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

paralist=[
	"ei=","ni=","ef=","nf=","o=",
	"nodeSizeFld=","pieDataFld=","pieTipsFld=",
	"nodeTipsFld=","picFld=","nodeColorFld=",
	"edgeWidthFld=","edgeColorFld=",
	"--help","-undirect","-offline"
]
nparalist=[
	"ei=","ni=","ef=","nf="
]

args=MCMD::Margs.new(ARGV, paralist.join(","),nparalist.join(',') )

# mcmdのメッセージは警告とエラーのみ
ENV["KG_VerboseLevel"]="2" unless args.bool("-mcmdenv")


# ni nf nodeSizeFld= pieDataFld= pieTipsFld=,nodeTipsFld= picFld=
# ei ef edgeWidthFld=,

# EDGE Para
ei = args. file("ei=","r") 
ef = args.field("ef=", ei)  # ef1=ef["names"][0] ef2=ef["names"][1]
if ef["names"].size() != 2 then 
	raise "ef= takes just two field names"
end
edgeWidthFld = args.field("edgeWidthFld=" , ei) #eszf
edgeColorFld = args.field("edgeColorFld=" , ei)



# Node Para
ni = args. file("ni=","r") 
nf = args.field("nf=", ni) # nf1=nf["names"][0]
if nf["names"].size() != 1 then 
	raise "nf= takes just one field name"
end

pieDataFld = args.field("pieDataFld=", ni)
pieTipsFld = args.field("pieTipsFld=", ni)
picFld     = args.field("picFld=", ni)

unless ( ( pieDataFld == nil && pieTipsFld == nil ) || ( pieDataFld != nil && pieTipsFld != nil ) ) then
	raise "pieDataFld= pieTipsFld= are necessary at the same time"
end

if picFld != nil && pieDataFld !=nil then
	raise "picFld= cannot be specified with pieDataFld= pieTipsFld="
end

nodeSizeFld  = args.field("nodeSizeFld=", ni)
nodeTipFld   = args.field("nodeTipsFld=", ni)

#circleの時のみ使える
nodeColorFld = args.field("nodeColorFld=", ni)

if nodeColorFld != nil  then

	if picFld != nil || pieDataFld !=nil || pieTipsFld !=nil then
		raise "nodeColorFld= cannot be specified with pieDataFld= pieTipsFld= picFld="
	end
end

undirect=args.bool("-undirect")
localFlg=args.bool("-offline")

oFile = args.file("o=", "w")

caseNo = 0 
if pieDataFld != nil && pieTipsFld != nil then
	caseNo = 1
elsif picFld != nil then
	caseNo = 2
end

# caseNo 0:circle 1:piechart  2:画像

wf=MCMD::Mtemp.new
nftmp = wf.file()
nftmp1 = wf.file()
eftmp = wf.file()
efctmp = wf.file()
efxtmp = wf.file()

nodefld =[]
nodedmy1 = []
nodedmy2 = []

nodefld << "#{nf["names"][0]}:node"

if nodeSizeFld != nil then
	nodefld << "#{nodeSizeFld['names'][0]}:nodesize"
else
	nodedmy1 << "nodesize"
	nodedmy2 << "50"
end

if nodeTipFld != nil then
	nodefld << "#{nodeTipFld['names'][0]}:nodeT"
else
	nodedmy1 << "nodeT"
	nodedmy2 << ""
end

if nodeColorFld != nil then
	nodefld << "#{nodeColorFld['names'][0]}:nodeClr"
else
	nodedmy1 << "nodeClr"
	nodedmy2 << "skyblue"
end


if caseNo == 1 then
	nodefld << "#{pieDataFld['names'][0]}:pieD"
	nodefld << "#{pieTipsFld['names'][0]}:pieT"

elsif caseNo == 2 then
	nodefld << "#{picFld['names'][0]}:pic"
end


f = ""
f << "mcut i=#{ni} f=#{nodefld.join(',')} |"
if nodedmy1.size() != 0 then
	f << "msetstr a=#{nodedmy1.join(',')} v=#{nodedmy2.join(',')} |"	
end


if caseNo == 1 then

	f << "mshare k=node f=pieD:pieDS |"
	f << "mnumber k=node a=nodeid -B o=#{nftmp1}"
	system(f)

	# make Pie TIPS GROUP
	f = ""
	f << "muniq k=pieT i=#{nftmp1} |"
	f << "mnumber -q a=pieTno |"
	f << "mjoin k=pieT f=pieTno i=#{nftmp1}  |"
	f << "msortf f=nodeid%n,pieTno%n o=#{nftmp} "
	system(f)

else

	f << "mnumber a=nodeid%n -q o=#{nftmp}"
	system(f)

end

# MAKE EDGE DATA 
edgefld  = []
edgedmy1 = []
edgedmy2 = []

edgefld <<  "#{ef['names'][0]}:edgeS"
edgefld <<  "#{ef['names'][1]}:edgeE"

if edgeWidthFld != nil then
	edgefld << "#{edgeWidthFld['names'][0]}:edgesize"
else
	edgedmy1 << "edgesize"
	edgedmy2 << "1"
end	

if edgeColorFld != nil then
	edgefld << "#{edgeColorFld['names'][0]}:edgecolor"
else
	edgedmy1 << "edgecolor"
	edgedmy2 << "black"
end

f = ""
f << "mcut i=#{ei} f=#{edgefld.join(',')} |"
if edgedmy1.size() != 0 then
	f << "msetstr a=#{edgedmy1.join(',')} v=#{edgedmy2.join(',')} |"
end

f << "mnumber a=preNo -q |"
f << "mbest k=edgeS,edgeE s=preNo%nr |"
f << "mnumber s=preNo%n a=edgeID |"
f << "mjoin k=edgeS K=node f=nodeid:edgeSid m=#{nftmp} |"
f << "mjoin k=edgeE K=node f=nodeid:edgeEid m=#{nftmp} o=#{eftmp}"
system(f)


#双方向チェック一応
f =""
f << "mfsort i=#{eftmp} f=edgeS,edgeE |"
f << "mcount k=edgeS,edgeE a=edgecnt |"
f << "mselnum c=[2,] f=edgecnt |"
f << "msetstr a=biflg v=1 o=#{efctmp}"
system(f)


f=""
f << "mjoin k=edgeID f=biflg m=#{efctmp} -n i=#{eftmp} | "
f << "msortf f=edgeID%n o=#{efxtmp}"
system(f)




gdata="{\"nodes\":["

nodedatastk = []

if caseNo == 1 then
	MCMD::Mcsvin::new("i=#{nftmp} k=nodeid -q"){|csv|
		nodedatas =""
  	csv.each{|val,top,btm|
   		name = val["node"]
    	r = val["nodesize"]
    	title = val["nodeT"]
			if top then
				nodedatas =""
				nodedatas << "{"
				nodedatas <<	 "\"name\": \"#{name}\","
				nodedatas <<	 "\"title\": \"#{title}\","
				nodedatas <<	 "\"r\": #{r},"
				nodedatas <<	 "\"node\": ["
			end
			
			pieTno = val["pieTno"]
			pieT = val["pieT"]
			pieDS = val["pieDS"]
			nodedatas << "{"
			nodedatas << "\"group\": #{pieTno},"
			nodedatas << "\"color\": #{pieDS},"
			nodedatas << "\"value\": #{pieDS},"
			nodedatas << "\"title\": \"#{pieT}\""
			nodedatas << "}"

			if btm then
				nodedatas << "]"
				nodedatas << "}"
				nodedatastk << nodedatas
				nodedatas =""
			else
				nodedatas << ","
			end
  	}	
	}
else

	MCMD::Mcsvin::new("i=#{nftmp}"){|csv|

		nodedatastk = []
    csv.each{|val|
    	name = val["node"]
    	r = val["nodesize"]
    	title = val["nodeT"]
    	pic = val["pic"]
    	nclr = val["nodeClr"]
    	nodedatas =""
	    nodedatas << "{"
	    nodedatas <<	 "\"name\": \"#{name}\","
			nodedatas <<	 "\"title\": \"#{title}\","
			nodedatas <<	 "\"pic\": \"#{pic}\","
			nodedatas <<	 "\"color\": \"#{nclr}\","
	    nodedatas <<	 "\"r\": #{r}"
	    nodedatas << "}"
	    nodedatastk <<  nodedatas
    }
	}

end


edgedatastk = []

MCMD::Mcsvin::new("i=#{efxtmp}"){|csv|
	csv.each{|val|
    es = val["edgeSid"]
    et = val["edgeEid"]
    esize = val["edgesize"]
    ecolor = val["edgecolor"]
		if es==et then
			#dmy node
			dno = nodedatastk.size
    	nodedatas =""
	    nodedatas << "{"
	    nodedatas <<	 "\"name\": \"\","
			nodedatas <<	 "\"title\": \"\","
			nodedatas <<	 "\"pic\": \"\","
			nodedatas <<	 "\"color\": \"\","
	    nodedatas <<	 "\"r\": 0"
	    nodedatas << "}"			
			nodedatastk << nodedatas
			nodedatastk << nodedatas
	    edgedatas = ""
		  edgedatas << "{"
	 		edgedatas << "\"source\": #{es},"
	  	edgedatas << "\"target\": #{dno},"
	  	edgedatas << "\"length\": 10,"
	  	edgedatas << "\"ewidth\": #{esize},"
	  	edgedatas << "\"color\": \"#{ecolor}\""
  		edgedatas << "}"
	  	edgedatastk <<  edgedatas

	    edgedatas = ""
		  edgedatas << "{"
	 		edgedatas << "\"source\": #{dno},"
	  	edgedatas << "\"target\": #{dno+1},"
	  	edgedatas << "\"length\": 10,"
	  	edgedatas << "\"ewidth\": #{esize},"
	  	edgedatas << "\"color\": \"#{ecolor}\""
  		edgedatas << "}"
	  	edgedatastk <<  edgedatas

	    edgedatas = ""
		  edgedatas << "{"
	 		edgedatas << "\"source\": #{dno+1},"
	  	edgedatas << "\"target\": #{et},"
	  	edgedatas << "\"length\": 10,"
	  	edgedatas << "\"ewidth\": #{esize},"
	  	edgedatas << "\"color\": \"#{ecolor}\""
  		edgedatas << "}"
	  	edgedatastk <<  edgedatas
		else
	    edgedatas = ""
		  edgedatas << "{"
	 		edgedatas << "\"source\": #{es},"
	  	edgedatas << "\"target\": #{et},"
	  	edgedatas << "\"length\": 500,"
	  	edgedatas << "\"ewidth\": #{esize},"
	  	edgedatas << "\"color\": \"#{ecolor}\""
  		edgedatas << "}"
	  	edgedatastk <<  edgedatas
		end
	}
}

gdata << nodedatastk.join(',')
gdata << "],\"links\": ["
gdata << edgedatastk.join(',')
gdata << "]}"

direct = ".attr('marker-end','url(#arrowhead)')"
if undirect then
 direct = ""
end

nodeTemplate =<<NodeNormal 
    node
			.append("circle")
			.attr("r",function(d){return d.r/4;})
			.attr("fill", function(d){return d.color;})
			.append("title")
			.text(function(d){return d.title;})

NodeNormal

nodemakeTemplate =<<NodeMakeNormal 
	for(var i=0 ; i< graph.nodes.length;i++){
		graph.nodes[i].id = i
	}
NodeMakeNormal

if pieDataFld != nil then
nodeTemplate =<<NodePIe 
    node.selectAll("path")
        .data( function(d, i){
          return pie(d.node);
				})
        .enter()
        .append("svg:path")
        .attr("d", arc)
        .attr("fill", function(d, i) {
					return color(d.data.group);
				})
				.append("title")
				.text(function(d){return d.data.title;})

        node.append("circle")
				.attr("r",function(d){return d.r/4;})
				.attr({
					'fill': 'white'
				})
				.append("title")
				.text(function(d){return d.title;});
NodePIe

nodemakeTemplate =<<NodeMakePie
	for(var i=0 ; i< graph.nodes.length;i++){
		var r = graph.nodes[i].r
		for(var j=0 ; j< graph.nodes[i].node.length;j++){
			graph.nodes[i].node[j]['r'] = r
		}
		graph.nodes[i].id = i
	}
NodeMakePie

elsif picFld !=nil

nodeTemplate =<<NodePic
    node
			.append("image")
			.attr("height",function(d){return d.r;})
			.attr("width",function(d){return d.r;})
			.attr("x",function(d){return -1 * d.r/2; })
			.attr("y",function(d){return -1 * d.r/2; })
			.attr("xlink:href",function(d){return d.pic; })
			.append("title")
			.text(function(d){return d.title;})
NodePic


end


d3js_str="<script type='text/javascript' src='http://d3js.org/d3.v3.min.js'></script>"

if localFlg then
	d3js_str = "<script> " + ViewJs::d3jsMin() + "</script>"
end




outTemplate =<<OUT
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	#{d3js_str}
    <style>

    </style>
</head>
<body>

<script type="text/javascript">

	var graph = #{gdata} ;
	
	
  var width = 4000,
      height = 3000;

	var color = d3.scale.category10();
    
	#{nodemakeTemplate}

	for(var i=0 ; i< graph.links.length;i++){
		graph.links[i].id = i
	}

    var pie = d3.layout.pie()
        .sort(null)
        .value(function(d) { return d.value; });

    var arc = d3.svg.arc()
       	.outerRadius( function(d){ return d.data.r ; })
        .innerRadius( function(d){ return d.data.r/2 ; } );
		
	var svg = d3.select("body").append("svg")
		.attr("width", width)
		.attr("height", height);

     d3.select("svg").append('defs').append('marker')
        .attr({'id':'arrowhead',
            'viewBox':'-0 -5 10 10',
            'refX':30,
            'refY':0,
            'orient':'auto-start-reverse',
            'markerWidth':5,
            'markerHeight':5,
            'xoverflow':'visible'})
        .append('path')
        .attr('d', 'M 0,-5 L 10 ,0 L 0,5')
        .attr('fill', '#999')
        .style('stroke','none');
            
	var g = svg.append("g");
	var node = g.selectAll(".node");
	var link = g.selectAll(".link");
	nodes = graph.nodes
  links = graph.links

	var force = 
		d3.layout.force()
			.linkDistance(100)
			.linkStrength(3.5)
      .charge(-3500)
			.gravity(0.1)
			.friction(0.95)
      .size([width, height])
			.on("tick", function() {
				link
					.attr("x1", function(d) { return d.source.x; })
					.attr("y1", function(d) { return d.source.y; })
					.attr("x2", function(d) { return d.target.x; })
					.attr("y2", function(d) { return d.target.y; });

				node
					.attr("x", function(d) { return d.x; })
					.attr("y", function(d) { return d.y; })
					.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"});	
	    });


		node = node.data(nodes, function( d ) { return d.id; } );
		link = link.data(links, function( d ) { return d.id; } );


    link
      .enter()
      .append("line")
      .attr("class", "link")
			.style("stroke", function( d ) { return d.color; } )
			.style("stroke-width", function( d ) { return d.ewidth; })
			#{direct}


    node
    	.enter()
			.append("g")
      .attr("class", "node")
			.style({})
			.call(force.drag)
			.on("contextmenu", function(nd) {
					d3.event.preventDefault();
					force.stop()
				 	nodes.splice( nd.index, 1 );
					links = links.filter(function(nl) {
						return nl.source.index != nd.index && nl.target.index != nd.index;					
					});
					node = node.data(nodes, function( d ) { return d.id; } );
					node.exit().remove();
					link = link.data( links, function( d ) { return d.id; } );
					link.exit().remove();
			    force.nodes(nodes)
      	   .links(links)
        	 .start();

				});  
	
		#{nodeTemplate}


    node
      .append("text")
      .attr("text-anchor", "middle")
			.style("stroke", "black")
      .text(function(d) {
        return d.name;
    	});


    force.nodes(nodes)
         .links(links)
         .start();


</script>
</body>
</html>
OUT

File.open(oFile,"w"){|fp|
	fp.puts outTemplate
}


