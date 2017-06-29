#!/usr/bin/env ruby
#-*- coding: utf-8 -*-

require "rubygems"
require "nysol/mcmd"
require "nysol/viewjs"

# ver="1.0" # 初期リリース 2014/5/11
$cmd = $0.sub(/.*\//,"")

$version = 1.0
$revision = "###VERSION###"

def help ()

#ヒアドキュメント
STDERR.puts <<EOF
------------------------
#{$cmd} version #{$version}
------------------------
概要) CSVデータから棒グラフ(HTML)を作成する
      1次元グリッド、２次元グリッドのグラフ表示が可能
      マウススクロールで拡大、縮小、マウスドラッグで画像の移動が可能

書式1) #{$cmd} [i=] [o=] [title=] [height=] [width=] [k=] [cc=] f= v= [--help]
                i=        : 入力データファイル名(CSV形式)
                o=        : 出力ファイル名(HTMLファイル)
                title=    : グラフのタイトル文字列を指定する
                height=   : 棒グラフ用描画枠の縦幅を指定する(default:250/1つの棒グラフは400)
                width=    : 棒グラフ用描画枠の横幅を指定する(default:250/1つの棒グラフは600)
                k=        : x軸,y軸に展開する属性項目名
                            k=なしの場合は棒グラフを1つ作成する
                            項目を1つ指定した場合は1次元の棒グラフ行列を、
                            項目を2つ指定した場合は2次元の棒グラフ行列を作成する
                            (y軸項目,x軸項目の順に指定)
                cc=       : 1行に表示する棒グラフの最大数を指定する(default:5)
                            1次元グラフのみで指定可能(k=1つ指定の場合)
                f=        : 構成要素項目名を指定する(必須)
                            データにnullが含まれる場合は無視する
                v=    : 構成量項目(棒グラフの高さを決定する項目)を指定する(必須)
                            データにnullが含まれる場合は0として扱う
                            先頭の0は無視する
                            数字以外の場合はエラーとなる
                --help    : ヘルプの表示

注意1)コマンドには、f=パラメータやk=パラメータで指定した項目を自動的に並べ替える機能はない
グラフに表示したい順に、あらかじめ並べ替えておく必要がある。
1次元、２次元グラフの場合はデータの先頭の棒グラフの表示順に並べられる

例1) 棒グラフを1つ描画する
dat1.csvファイルのAgeを構成要素項目に、Populationを構成量項目として棒グラフを1つ描画する

dat1.csv
Age,Population
10,310504
20,552339
30,259034.5555
40,0450818
50,1231572
60,1215966
70,641667

$ #{$cmd} i=dat1.csv v=Population f=Age o=result1.html

例2) 1次元の棒グラフ行列を描画する
dat2.csvファイルのAgeを構成要素項目に、Populationを構成量項目として棒グラフを描画する
k=パラメータにPref項目を指定しているので、
Pref項目の値をx軸(横方向)に展開した1次元の棒グラフ行列が描画される
title=パラメータでグラフのタイトルも指定している

dat2.csv
Pref,Age,Population
奈良,10,310504
奈良,20,552339
奈良,30,259034
奈良,40,450818
奈良,50,1231572
奈良,60,1215966
奈良,70,641667
北海道,10,310504
北海道,20,252339
北海道,30,859034
北海道,40,150818
北海道,50,9231572
北海道,60,4215966
北海道,70,341667

$ #{$cmd} i=dat2.csv k=Pref v=Population f=Age o=result2.html

例3) x軸上に表示する棒グラフの最大数を1とする

$ #{$cmd} i=dat2.csv k=Pref v=Population f=Age o=result3.html cc=1

例4) 2次元の棒グラフ行列を描画する
dat3.csvファイルのテーマパーク名を構成要素項目に、
Numberを構成量項目として棒グラフを描画する
k=パラメータにGenderとAge項目を指定して、Gender項目の値をx軸(横方向)に、
Age項目の値をy軸(縦方向)に展開した2次元の棒グラフ行列を描画する

dat3.csv
Gender,Age,テーマパーク名,Number
男性,30,デズニ,100
男性,30,UFJ,59
男性,30,梅屋敷,180
男性,40,デズニ,200
男性,40,UFJ,3
男性,40,梅屋敷,10
男性,50,デズニ,110
男性,50,UFJ,40
女性,30,梅屋敷,100
女性,30,デズニ,80
女性,30,UFJ,200
女性,40,デズニ,90
女性,40,UFJ,80
女性,40,梅屋敷,120
女性,50,デズニ,99
女性,50,UFJ,80
女性,50,梅屋敷,110

$ #{$cmd} i=dat3.csv k=Gender,Age v=Number f=テーマパーク名 o=result3.html title=性別と年代ごとのテーマパーク訪問回
EOF

exit
end

def ver()
  $revision = "0" if $revision =~ /VERSION/
  STDERR.puts "version #{$version} revision #{$revision}"
  exit
end

def checkNull(key)
  if key == nil then # 値の項目がnullの場合0にする
    return "0"
  end
  return key
end

def checkNumeric(key)
  unless key =~ /^-?([0-9]\d*|0)(\.\d+)?$/  # 棒グラフの値の整数チェック
    raise "#{key} is not a numeric"
  end
end

def getStrLength(key, maxLeg)
  if key != nil 
    tmpSize = key.split(//).size
    if tmpSize > maxLeg
      return tmpSize
    end
  end
  return maxLeg
end

#  (dataStr, countKey, maxValue, maxLeg, maxValueSize, minValue) = makeZeroDemData(iFile, legendKey, barValue)
# iFile(inputファイル)
# legendKey(キーの項目)     (例：年代)
# barValue(値の項目)     (例：人口)
def makeZeroDemData(iFile, legendKey, barValue)
  dataStr = "var data = [\n{"
  countKey = 0
  maxValue = 0
  minValue = 0
  maxLeg = 0
  maxValueSize = 0
  if iFile then
    MCMD::Mcsvin.new("i=#{iFile}"){|csv|
      csv.each{|flds|            # 行処理
        csv.names.each {|header| # 一行の項目分ループ
          if header == "#{legendKey}" then # 棒グラフのキー項目
            maxLeg = getStrLength(flds[header], maxLeg)
          end
          if header == barValue  # header読み込み(headerがvalueの時)
            flds[header] = checkNull(flds[header])
            checkNumeric(flds[header])
            if flds[header].length > maxValueSize
              maxValueSize = flds[header].length
            end
            if flds[header] =~ /\d+\.\d+/ then
              if flds[header].to_f > maxValue.to_f then #構成量項目の最大値を取得
                maxValue = flds[barValue]
              end
              if flds[header].to_f < minValue.to_f then #構成量項目の最小値を取得
                minValue = flds[barValue].to_f
              end
            else 
              if flds[header].to_i > maxValue.to_i then #構成量項目の最大値を取得
                maxValue = flds[barValue]
              end
              if flds[header].to_i < minValue.to_i then #構成量項目の最小値を取得
                minValue = flds[barValue].to_i
              end
            end
            dataStr << "\"_#{flds[legendKey]}\":\"#{flds[barValue]}\","
          end
        }
         countKey +=1 # 行数カウント(0次元の場合はヘッダを除いたデータの行数)
      }
      dataStr = dataStr.chop
      dataStr << "}\n];\n"
    }
  end
  return dataStr, countKey, maxValue, maxLeg, maxValueSize, minValue
end

#  (dataStr, xcount, keycount, maxValue, maxLeg, maxValueSize, minValue) = makeOneDemData(iFile, primKey, legendKey, barValue)
# iFile(inputファイル)
# primKey(主キー)        (例：Pref)
# legendKey(キーの項目)     (例：年代)
# barValue(値の項目)     (例：人口)
def makeOneDemData(iFile, primKey, legendKey, barValue)
  dataStr = "var data = ["
  xcount = {} # hash
  keycount = {} 
  maxValue = 0
  minValue = 0
  maxLeg   = 0
  maxValueSize = 0
  if iFile then
    MCMD::Mcsvin.new("i=#{iFile} k=#{primKey} -q"){|csv|
      csv.each{|flds,top,bot|  # 行処理
        if top == true then      # 先頭行の場合 
          dataStr << "\n{"
        end
        csv.names.each {|header| # 一行の項目分ループ
          unless xcount.has_key?("#{flds[primKey]}") 
            xcount[flds[primKey]] = 1  # x軸の項目ハッシュ(カウント用)
          end
          if header == "#{primKey}" && xcount[flds[primKey]] == 1  # 1回目に出たときだけ作る
            dataStr << "\"#{header}\":\"#{flds[header]}\","
            xcount[flds[primKey]] +=1
          end
          if header == "#{legendKey}" then # 棒グラフのキー項目
            maxLeg = getStrLength(flds[header], maxLeg)
            keycount[flds[legendKey]] = 1  # 棒グラフのキー項目ハッシュ(カウント用)
          end
          if header == "#{barValue}" then
            flds[header] = checkNull(flds[header])
            checkNumeric(flds[header])
            if flds[header].length > maxValueSize
              maxValueSize = flds[header].length
            end
            if flds[header] =~ /\d+\.\d+/ then
              if flds[header].to_f > maxValue.to_f then #構成量項目の最大値を取得
                maxValue = flds[barValue]
              end
              if flds[header].to_f < minValue.to_f then #構成量項目の最小値を取得
                minValue = flds[barValue].to_f
              end
            else 
              if flds[header].to_i > maxValue.to_i then #構成量項目の最大値を取得
                maxValue = flds[barValue]
              end
              if flds[header].to_i < minValue.to_i then #構成量項目の最小値を取得
                minValue = flds[barValue].to_i
              end
            end
            dataStr << "\"_#{flds[legendKey]}\":\"#{flds[barValue]}\"," # key項目:value項目値 
          end
        }
        if bot == true then # primKeyの同じ項目の終わり
          dataStr = dataStr.chop
          dataStr << "},"
        end
      }
      dataStr = dataStr.chop
      dataStr << "\n];\n"
    }
  end
  return  dataStr, xcount, keycount, maxValue, maxLeg, maxValueSize, minValue
end

#  (dataStr, xcount, ycount, keycount, maxValue, maxLeg, maxValueSize, minValue) = makeTwoDemData(iFile, yBar, xBar, legendKey, barValue)
# iFile(inputファイル)
# yBar(keyの値:行の項目)
# xBar(keyの値:列の項目)
# legendKey(キーの項目)
# barValue(値の項目)
def makeTwoDemData(iFile, yBar, xBar, legendKey, barValue)
  dataStr = "var data = ["
  xcount = {}
  ycount = {} 
  maxValue = 0
  minValue = 0
  maxLeg   = 0
  maxValueSize = 0
  xycount = Hash.new{|h,k| h[k]=Hash.new(&h.default_proc)} # hashネスト宣言
  keycount = {} 
  if iFile then
    MCMD::Mcsvin.new("i=#{iFile} k=#{yBar},#{xBar} -q"){|csv|
      csv.each{|flds,top,bot|
        if top == true then  # 先頭 
          dataStr << "\n{"
        end
        csv.names.each {|header| # 一行の項目分ループ
            xcount[flds[xBar]] = 1 # x軸の項目ハッシュ(カウント用)
            ycount[flds[yBar]] = 1 # y軸の項目ハッシュ(カウント用)
          unless xycount[flds[xBar]].has_key?("#{flds[yBar]}")
            xycount[flds[xBar]][flds[yBar]] = 1 # y軸の項目ハッシュ(カウント用)
          end
          if header == "#{xBar}" && xycount[flds[xBar]][flds[yBar]] == 1 then
            dataStr << "\"#{xBar}\":\"#{flds[xBar]}\",\"#{yBar}\":\"#{flds[yBar]}\"," 
             xycount[flds[xBar]][flds[yBar]] +=1
          end
          if header == "#{legendKey}" then # 棒グラフのキー項目
            maxLeg = getStrLength(flds[header], maxLeg)
            keycount[flds[legendKey]] = 1  # 棒グラフのキー項目ハッシュ
          end
          if header == "#{barValue}" then # 棒グラフの値項目
            flds[header] = checkNull(flds[header])
            checkNumeric(flds[header])
            if flds[header].length > maxValueSize
              maxValueSize = flds[header].length
            end
            if flds[header] =~ /\d+\.\d+/ then
              if flds[header].to_f > maxValue.to_f then #構成量項目の最大値を取得
                maxValue = flds[barValue]
              end
              if flds[header].to_f < minValue.to_f then #構成量項目の最小値を取得
                minValue = flds[barValue].to_f
              end
            else 
              if flds[header].to_i > maxValue.to_i then #構成量項目の最大値を取得
                maxValue = flds[barValue]
              end
              if flds[header].to_i < minValue.to_i then #構成量項目の最小値を取得
                minValue = flds[barValue].to_i
              end
            end
            dataStr << "\"_#{flds[legendKey]}\":\"#{flds[barValue]}\"," # key項目:value項目値
          end
        }
        if bot == true then
          dataStr = dataStr.chop
          dataStr << "},"
        end
      }
      dataStr = dataStr.chop
      dataStr << "\n];\n"
    }
  end
  return  dataStr, xcount, ycount, keycount, maxValue, maxLeg, maxValueSize, minValue
end

help() if ARGV.size <= 0 or ARGV[0] == "--help"
ver() if ARGV[0] == "--version"

# ===================================================================
# パラメータ処理 f=,v=は必須
args = MCMD::Margs.new(ARGV,"i=,o=,title=,cc=,height=,width=,k=,f=,v=,--help","f=,v=")
input_args = ARGV.join(" ")
command = $cmd

# mcmdのメッセージは警告とエラーのみ
ENV["KG_VerboseLevel"] = "2" unless args.bool("-mcmdenv")

iFile     = args.file("i=","r")   # inputファイル名を取得(readable)
oFile     = args.file("o=","w")   # outputファイル名を取得(writable)

title         = args.str("title=")    # タイトル取得
svgHeight     = args.int("height=")       # 棒グラフ用SVGの縦幅
svgWidth      = args.int("width=")       # 棒グラフ用SVGの横幅

keyFld   = args.field("k=", iFile)      # key項目値取得
key1 = key2 = nil
if keyFld then
  key1 = keyFld["names"][0]  # 行キー
  key2 = keyFld["names"][1]  # 列キー
end
xMax  = args.int("cc=")     # x軸に並べる棒グラフの数取得
legendKey    = args.str("f=")    # 棒グラフの構成要素項目
barValue     = args.str("v=")     # 棒グラフの値のキー

args.field("v=", iFile) if args.keyValue["v="] # 項目値をヘッダからチェック
args.field("f=", iFile)   if args.keyValue["f="]   # 凡例項目をヘッダからチェック

if xMax then
  if keyFld == nil or key2 then
    raise "cc= takes only k=A"
  end
  if xMax < 1 then
    raise "cc= takes more than 1"
  end
end

# ===================================================================
# デフォルト値
# デフォルトは0次元グラフの設定値
#0次元
if key1 == nil and key2 == nil then
  svgHeight = 400 unless svgHeight   
  svgWidth  = 600 unless svgWidth        
else
  svgHeight = 250 unless svgHeight   
  svgWidth  = 250 unless svgWidth        
end

# キャンパスのマージン
outerMarginL = 30
outerMarginR = 30
outerMarginT = 30
outerMarginB = 30

maxValue = 0
xMax = 5 unless xMax

# ============
# INPUTファイルの読み込み
xcount = {}
ycount = {}
keycount = {}
xNum = 1
yNum = 1
keyNum = 0
dataStr = ""
maxValue=0
minValue=0
maxValueSize=0
maxLeg=0
# 2次元グラフ処理
if key1 != nil and key2 != nil then
  (dataStr, xcount, ycount, keycount, maxValue, maxLeg, maxValueSize, minValue) = makeTwoDemData(iFile, key1, key2, legendKey, barValue)
  xNum   = xcount.length   # x軸の棒グラフ数
  yNum   = ycount.length   # y軸の棒グラフ数
  keyNum = keycount.length # 凡例用キー数
# 1次元グラフ処理
elsif key1 != nil and key2 == nil then
  (dataStr, xcount, countKey, maxValue, maxLeg, maxValueSize, minValue)  = makeOneDemData(iFile, key1, legendKey, barValue)
  xNum = xcount.length     #主キーの数
  keyNum = countKey.length #keyの数
  if xNum > xMax
    yNum = xNum / xMax
    xNum = xMax
  end
# 0次元グラフ処理
elsif key1 == nil and key2 == nil then
  (dataStr, countKey, maxValue, maxLeg, maxValueSize, minValue)  = makeZeroDemData(iFile, legendKey, barValue)
  keyNum = countKey
end
xCampusSize = xNum * svgWidth + outerMarginL + outerMarginR
yCampusSize = yNum * svgHeight + outerMarginT + outerMarginB
maxValueCount = maxValue.length 
maxLength = maxValueCount + maxValueCount / 3
if maxLength < maxValueSize
  maxLength = maxValueSize
end
# 棒グラフ用SVGのマージン
# 左は最大桁数+カンマの数*10(単位)+10(マージン)
barMarginL = maxLength * 10 + 10
barMarginR = 10
barMarginT = 20
#barMarginB = 20
# 下は最大桁数*10(単位)+30(マージン)
barMarginB = maxLeg * 10 + 30
# ============
# 文字列作成
colorStyle = ""
campusStr = ""
outLineStr = ""
barStr = ""
graphTitle = ""
#legendStr = ""
svgStr = ""
xZeroBar = ""
#2次元グラフの場合
if key1 != nil and key2 != nil then
colorStyle = <<EOT
var tmpKeys = d3.keys(data[0]).filter(function(key) { if(key !== "#{key1}" && key !== "#{key2}") { return key; }});
EOT
#0,１次元グラフの場合
else
colorStyle = <<EOT
var tmpKeys = d3.keys(data[0]).filter(function(key) { if(key !== "#{key1}") { return key; }});
EOT
end

# ============
# TITLE用文字列作成
titleMargin =20
tmpX = (xCampusSize - outerMarginR) / 2 
titleStr = ""
if title then
titleStr = <<EOT
var title = d3.select("svg").append("text")
      .attr("x", (#{tmpX}))
      .attr("y", "#{titleMargin}")
      .attr("text-anchor", "middle")
      .style("font-size", "13pt")
      .text("#{title}");
EOT
end

# 2次元
if key1 != nil and key2 != nil then
  xdomain = xcount.keys
  ydomain = ycount.keys

  outLineStr = <<EOT
var out_x = d3.scale.ordinal()
   .domain(#{xdomain})
   .rangeBands([0, out_axis_width]);

var out_x_axis = d3.svg.axis()
   .scale(out_x) //スケールの設定
   .orient("bottom");

var out_xaxis = d3.select("svg")
   .append("g")
   .attr("class", "axis")
   .attr("transform", "translate(" + outer_margin.left + "," + (out_axis_height + outer_margin.top) + ")")
   .call(out_x_axis);          

var out_y = d3.scale.ordinal()
   .domain(#{ydomain})          
   .rangeBands([0, out_axis_height]);

var out_y_axis = d3.svg.axis()
   .scale(out_y)
   .orient("left");

var out_yaxis = d3.select("svg")
   .append("g")
   .attr("class", "axis")
   .attr("transform", "translate(" + outer_margin.left + "," + outer_margin.top + ")") // x方向,y方向
   .call(out_y_axis);
EOT
else
  outLineStr = ""
end

svgStr = <<EOT
// 描画領域を作成(svgをデータ行分つくる)
var svg = d3.select("svg").selectAll(".bar")
     .data(data)
    .enter().append("svg")
    .attr("width", svgWidth)
    .attr("height", svgHeight)
     .attr("x", function(d,i) { 
        if (i < #{xNum}) { return svgWidth*i + outer_margin.left ; }
        else { return svgWidth*(i % #{xNum}) + outer_margin.left; } }) // width+0, width+1,...width+xNum, width+0..
     .attr("y", function(d,i) { return  outer_margin.top + svgHeight * parseInt(i/#{xNum}); }) // i/3を整数値で取得
     .attr("class", "bar")
     .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
EOT
# 1次元
if key1 != nil and key2 == nil then
titleY = barMarginT / 2
graphTitle = <<EOT
svg.append("text")
   .attr("class", "text")
   .style("text-anchor", "middle")
   .style("font-size", "10px")
   .attr("transform", "translate(0, -#{titleY})")
   .text( function(d) {return d.#{key1}});
EOT
end

comStr = <<EOT
var command = d3.select("body").append("div")
      .attr("x", "430")
      .attr("y", "20")
      .attr("text-anchor", "left")
      .style("font-size", "14px")
      .text("#{command} #{input_args}");
EOT

if minValue < 0 then
xZeroBar = <<EOT
svg.append("g")
   .attr("class", "x0 axis")
   .append("line")
   .attr("x1", 0)
   .attr("y1", y(0))
   .attr("x2",  inWidth )
   .attr("y2", y(0));
EOT
end

# ============
# 描画
html = STDOUT
if oFile != nil  then
  html = open(oFile,"w")
end

html.puts <<HEOF
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
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
  border-radius: 5px;
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

.axis text {
    font: 11px
    font-family: sans-serif;
}

.axis path,
.axis line {
    fill: none;
    stroke: #000;
    shape-rendering: crispEdges;
}
</style>
</head>
<body>
<script>
#{ViewJs::d3jsMin()}

#{dataStr}
// キャンパスサイズ
var out_w = #{xCampusSize};
var out_h = #{yCampusSize};

// キャンパスのマージン
var outer_margin = {top: #{outerMarginT}, right: #{outerMarginR}, bottom: #{outerMarginB}, left: #{outerMarginL}};

// 凡例の位置

// 外側のx軸サイズ
var out_axis_width  = out_w - outer_margin.left - outer_margin.right;
var out_axis_height = out_h - outer_margin.top - outer_margin.bottom;

// 棒グラフ表示用SVGのマージン
var margin = {top: #{barMarginT}, right: #{barMarginR}, bottom: #{barMarginB}, left: #{barMarginL}};

var svgWidth  = #{svgWidth};
var svgHeight = #{svgHeight};

var vbox_x = 0;
var vbox_y = 0;
var vbox_default_width = vbox_width = out_w;
var vbox_default_height = vbox_height = out_h;

var outline = d3.select("body").append("svg")
     .attr("width", out_w )
     .attr("height", out_h)
     .attr("viewBox", "" + vbox_x + " " + vbox_y + " " + vbox_width + " " + vbox_height);

var drag = d3.behavior.drag().on("drag", function(d) {
    vbox_x -= d3.event.dx;      
    vbox_y -= d3.event.dy;      
    return outline.attr("translate", "" + vbox_x + " " + vbox_y);
  });
  outline.call(drag);
  zoom = d3.behavior.zoom().on("zoom", function(d) {
        var befere_vbox_width, before_vbox_height, d_x, d_y;
        befere_vbox_width = vbox_width;
        before_vbox_height = vbox_height;
        vbox_width = vbox_default_width * d3.event.scale;
        vbox_height = vbox_default_height * d3.event.scale;
        d_x = (befere_vbox_width - vbox_width) / 2;
        d_y = (before_vbox_height - vbox_height) / 2;
        vbox_x += d_x;
        vbox_y += d_y;
        return outline.attr("viewBox", "" + vbox_x + " " + vbox_y + " " + vbox_width + " " + vbox_height);
  });
 outline.call(zoom); 

#{titleStr}

//outlineのX軸
//outlineのY軸
#{outLineStr}

// make colorlist
var color1 = d3.scale.category10();
var color2 = d3.scale.category20b();
var color3 = d3.scale.category20();
var color4 = d3.scale.category20c();
var cl = color1.range();
var colorList = cl.concat(color1.range());
colorList = colorList.concat(color2.range());
colorList = colorList.concat(color3.range());
colorList = colorList.concat(color4.range());

#{colorStyle}
var dataNames = tmpKeys.map(function(d) {return d.substr(1);});

// set color
var color = d3.scale.ordinal()
      .range(colorList)
      .domain(dataNames);

// レンジオブジェクト
// 棒グラフの横幅を0からwidthの間に、棒グラフの横幅を10%づつバディングして並べる
var inWidth = svgWidth - (margin.left + margin.right);
var x = d3.scale.ordinal()
    .rangeRoundBands([0, inWidth], .1);
    
// 棒グラフの縦幅を定義
var inHeight = svgHeight - margin.top - margin.bottom;
var y = d3.scale.linear()
    .range([inHeight, 0]);

// 棒グラフのx軸のオブジェクト
var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

// 棒グラフのy軸のオブジェクト
var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");

data.forEach(function(d) {
  d.datasets = color.domain().map(function(d1) {
    return {name: d1, value: +d["_" + d1]};
  });
});

// 棒グラフのx軸のドメインの設定
x.domain(dataNames);

// 棒グラフのy軸のドメインの最小値、最大値の設定(0からdataのvalの最大値)
y.domain([#{minValue}, #{maxValue}]);

// 個々のsvg領域の描画
#{svgStr}
#{graphTitle}

// 棒グラフのx軸
svg.append("g")
   .attr("class", "x axis")
   .attr("transform", "translate(0," + inHeight + ")")
   .call(xAxis)
   .selectAll("text")
   .style("text-anchor", "end")
   .style("font-size", "10px")
   .attr("dx", "-.8em")
   .attr("dy", ".15em")
   .attr("transform", function(d) {
     return "rotate(-90) translate(0,-10)"
   });

// マイナス対応
#{xZeroBar}

// 棒グラフのy軸
svg.append("g")
   .attr("class", "y axis")
   .call(yAxis);

svg.selectAll("rect")
    .data(function(d) { return d.datasets; })
  .enter().append("rect")
    .attr("width", x.rangeBand())
    .attr("x", function(d) { return x(d.name); })
    .attr("y", function(d) {return y(Math.max(0, d.value)); })
    .attr("height", function(d) { return Math.abs(y(d.value) - y(0)); })
    .style("fill", "steelblue")
    .on("mouseover", function(d) {
       d3.select("#tooltip")
         .style("left", (d3.event.pageX+10) +"px")
         .style("top", (d3.event.pageY-10) +"px")
         .select("#value")
         .text( d.name + " : " + d.value );
       d3.select("#tooltip").classed("hidden",false);
    })
    .on("mouseout", function() {
       d3.select("#tooltip").classed("hidden", true);
    });

var tooltip = d3.select("body").append("div")
    .attr("id", "tooltip")
    .attr("class", "hidden")
    .append("p")
      .attr("id", "value")
      .text("0");

#{comStr}
</script>
</body>
</html>

HEOF

# 終了メッセージ
MCMD::endLog(args.cmdline)
