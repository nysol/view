#!/usr/bin/env ruby
#-*- coding: utf-8 -*-

require "rubygems"
require "nysol/mcmd"
require "set"

# ver="1.0" # 初期リリース 2016/12/12
$cmd=$0.sub(/.*\//,"")

$version=1.0
$revision="###VERSION###"

def help

STDERR.puts <<EOF
------------------------
#{$cmd} version #{$version}
------------------------
概要) 値に応じた色を自動的に割り付ける

書式1) #{$cmd} f= col= [order=alpha|descend|ascend] [transmit=] o=

  f= : カラー項目名(この値に応じてカラーの値が決まる,1項目のみ指定可)。
  col=category|２色HEXコード(ex. FF0000,0000FF)
        categoryを指定した場合は、f=の値をカテゴリとして扱い、
          アルファベット順にRGBの値を以下の順番で設定していく。
          FF,80,C0,40,E0,60,A0,20,F0,70,B0,30,D0,50,90,10
          また上記各値の中でRGBの組合わせをR,G,B,RG,GB,RBの順に設定する。
          よって、16 x 6=96通りの色が設定される。
          カテゴリの数が96を超えた場合、超えた分は000000(黒)として出力される。
          FF0000,00FF00,0000FF,FFFF00,00FFFF,FF00FF,800000,008000,000080,...
        2色のHEXコードを指定した場合、f=の値を数値として扱い、
          指定した2色間のグラデーションを数値の大きさに応じて割り当てる。
          FF0000,0000FFの2色を指定した場合、f=項目の最小値がFF0000で、最大値が0000FFとなる。
          f=項目の値をv,最小値をmin,最大をmaxとすると、
          vに対して割り当てられるR(赤)要素のカラー値は以下の通り計算される。
            floor(r0+(r1-r0)*dist)  ただし、dist:(v-min)/(max-min)
            r0: color=で指定した色範囲開始のR要素
            r1: color=で指定した色範囲終了のR要素
            ex) color=FF0000,0000FFと指定していれば、r0=FF,r1=00
          与えられた値が全て同じ場合は計算不能のため、null値を出力する。
  order=: col=categoryの場合、色の割り付け順序を指定する(デフォルトはalpha)
     alpha: f=で指定した値をalphabet順
     descend: f=で指定した値の件数が多い順
     ascend:  f=で指定した値の件数が少ない順
  transmit= : 透過率を指定する。透過率は00からFFまでの値で、00で完全透明、FFで透明度0となる。
              色コードの後ろに追加される。
  o=  : 出力ファイル名

  -h,--help : ヘルプの表示

カテゴリデータをカラー化する例)
$ cat color.csv
num,class
01,B,10
02,A,15
03,C,11
04,D,29
05,B,32
06,A,
07,C,9
08,D,3
09,B,11
10,E,22
11,,21
12,C,35
$ mautocolor.rb f=class color=category a=color i=color.csv o=output1.csv↩
$ cat output1.csv
num,class1,value,color
01,B,10,00FF00
02,A,15,FF0000
03,C,11,0000FF
04,D,29,FFFF00
05,B,32,00FF00
06,A,,FF0000
07,C,9,0000FF
08,D,3,FFFF00
09,B,11,00FF00
10,E,22,00FFFF
11,,21,
12,C,35,0000FF

数値データをカラー化する例)
$ mautocolor.rb f=value color=FF0000,0000FF a=color i=color.csv o=output2.csv↩
$ cat output2.csv
num,class,value,color
01,B,10,c70037
02,A,15,9f005f
03,C,11,bf003f
04,D,29,2f00cf
05,B,32,1700e7
06,A,,
07,C,9,cf002f
08,D,3,ff0000
09,B,11,bf003f
10,E,22,670097
11,,21,6f008f
12,C,35,0000ff
EOF
exit
end
def ver()
	$revision ="0" if $revision =~ /VERSION/
	STDERR.puts "version #{$version} revision #{$revision}"
	exit
end

class Color
	def initialize(nc,ni,col,order)
		@nc=nc
		@ni=ni
		@col=col
		if @nc and @ni
			if col=="category"
				@type="category"
				# preparing a color pallet
				pallet=[]
				val=["FF","80","C0","40","E0","60","A0","20","F0","70","B0","30","D0","50","90","10"]
				val.each{|v|
					pallet << "#{v}0000"
					pallet << "00#{v}00"
					pallet << "0000#{v}"
					pallet << "#{v}#{v}00"
					pallet << "00#{v}#{v}"
					pallet << "#{v}00#{v}"
				}
				# read color field data and make a mapping table(data to pallet)
				temp=MCMD::Mtemp.new
				xxcTable=temp.file
				f=""
				f << "mcut f=#{nc}:ckey i=#{ni} |"
				f << "mdelnull f=ckey |"
				f << "mcount k=ckey a=freq |"
				if order=="descend"
					f << "mbest s=freq%nr,ckey from=0 size=96 o=#{xxcTable}"
				elsif order=="ascend"
					f << "mbest s=freq%n,ckey  from=0 size=96 o=#{xxcTable}"
				else
					f << "mbest s=ckey from=0 size=96 o=#{xxcTable}"
				end
				system(f)
				@cTable={}
				iCSV=MCMD::Mcsvin.new("i=#{xxcTable}")
				i=0
				iCSV.each{|flds|
					cKey=flds["ckey"]
					@cTable[cKey]=pallet[i]
					i+=1
				}
			else
				@type="numeric"
				ary=col.split(",")
				if ary.size!=2 or ary[0].size!=6 or ary[1].size!=6
					raise "col= takes two 6-digites HEX codes like FF0000,00FF00"
				end
				@r0=ary[0][0..1].hex
				@g0=ary[0][2..3].hex
				@b0=ary[0][4..5].hex
				@r1=ary[1][0..1].hex
				@g1=ary[1][2..3].hex
				@b1=ary[1][4..5].hex

				temp=MCMD::Mtemp.new
				xxcTable=temp.file
				f=""
				f << "mcut f=#{nc}:ckey i=#{ni} |"
				f << "mdelnull f=ckey |"
				f << "msummary f=ckey c=min,max o=#{xxcTable}"
				system(f)

				# fld,min,max
				# ckey,1,14
				tbl=MCMD::Mtable.new("i=#{xxcTable}")
				@min=tbl.cell(1)
				@max=tbl.cell(2)
				@min=@min.to_f if @min
				@max=@max.to_f if @max
				@range=@max-@min if @min and @max
			end
		end
	end

	def getRGB(val)
		return nil if val==nil or val==""
		if @type=="category"
			rgb=@cTable[val]
			rgb="000000" unless rgb
			return rgb
		else
			if @range==0 or @min==nil or @max==nil
				rgb=nil
			else
				val=val.to_f
				distance=(val-@min)/@range
				r=(@r0+(@r1-@r0)*distance).to_i.to_s(16)
				g=(@g0+(@g1-@g0)*distance).to_i.to_s(16)
				b=(@b0+(@b1-@b0)*distance).to_i.to_s(16)
				rgb=sprintf("%2s%2s%2s",r,g,b).gsub(" ","0")
			end
			return rgb
		end
	end
end

#############
# entry point
help() if ARGV.size <= 0 or ARGV[0]=="--help"
ver() if ARGV[0]=="--version"

# ===================================================================
# パラメータ処理
args=MCMD::Margs.new(ARGV,"f=,color=,order=,transmit=,a=,i=,o=","f=,i=,a=,color=")

# mcmdのメッセージは警告とエラーのみ
ENV["KG_VerboseLevel"]="2" unless args.bool("-mcmdenv")

iFile = args. file("i=","r")
fld   = args.field("f=", iFile)["names"][0]
color = args.str("color=","category")
aFld  = args.str("a=")
order = args.str("order=","alpha")
transmit = args.str("transmit=")
oFile = args.file("o=","w")

color=Color.new(fld,iFile,color,order)
iCSV=MCMD::Mcsvin.new("i=#{iFile} -array")

oFlds=[]
oFlds << iCSV.names
oFlds << aFld
oCSV=MCMD::Mcsvout.new("f=#{oFlds.join(',')} o=#{oFile}")
fldNum=iCSV.names.index(fld)
iCSV.each{|flds|
	colVal=flds[fldNum]
	colorStr=color.getRGB(colVal)
	colorStr="#{colorStr}#{transmit}" if colorStr and transmit
	flds << colorStr
	oCSV.write(flds)
}

# 終了メッセージ
MCMD::endLog(args.cmdline)

