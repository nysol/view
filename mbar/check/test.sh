
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

# 0次元
${lexe}mbar.rb i=$ip/input1.csv o=$op/out0-1.html v=人口 f=年代
${lexe}mbar.rb i=$ip/input1.csv o=$op/out0-2.html v=人口 f=年代 title=奈良県の年代ごとの人口
${lexe}mbar.rb i=$ip/input1-null.csv o=$op/out0-3.html v=人口 f=年代 title=データにnullあり
${lexe}mbar.rb i=$ip/input1-sort.csv o=$op/out0-4.html v=人口 f=年代 title=vが数字でならびがばらばら
${lexe}mbar.rb i=$ip/input1.csv o=$op/out0-5.html v=人口 f=年代 title=グラフの縦横幅指定 height=500 width=700
${lexe}mbar.rb i=$ip/input1-float.csv o=$op/out0-6.html v=人口 f=年代 title=小数
${lexe}mbar.rb i=$ip/input1-mai.csv o=$op/out0-7.html v=人口 f=年代 title=マイナス
#${lexe}mbar.rb i=$ip/input1.csv o=$op/out0-5.html v=人口 f=年代 title=凡例幅指定 legw=10
# 1次元
${lexe}mbar.rb i=$ip/input2.csv o=$op/out1-1.html v=人口 f=年代 k=Pref title=奈良県と北海道の年代ごとの人口
${lexe}mbar.rb i=$ip/input2.csv o=$op/out1-2.html v=人口 f=年代 k=Pref title=グラフ１つで折り返し指定 cc=1
${lexe}mbar.rb i=$ip/input2-sort.csv o=$op/out1-3.html v=人口 f=年代 k=Pref title=vが数字で並びがばらばら
${lexe}mbar.rb i=$ip/input2-null.csv o=$op/out1-4.html v=人口 f=年代 k=Pref title=データにnullあり
${lexe}mbar.rb i=$ip/input2.csv o=$op/out1-5.html v=人口 f=年代 k=Pref title=縦横幅指定 height=200 width=400
${lexe}mbar.rb i=$ip/input2-float.csv o=$op/out1-6.html v=人口 f=年代 k=Pref title=小数
${lexe}mbar.rb i=$ip/input2-mai.csv o=$op/out1-7.html v=人口 f=年代 k=Pref title=マイナス
# 2次元
${lexe}mbar.rb i=$ip/input3.csv o=$op/out2-1.html k=性別,年代 v=回数 f=テーマパーク
${lexe}mbar.rb i=$ip/input3.csv o=$op/out2-2.html k=性別,年代 v=回数 f=テーマパーク title=男女別年齢ごとのテーマパーク体験回数
#${lexe}mbar.rb i=$ip/input3.csv o=$op/out2-3.html k=性別,年代 v=回数 f=テーマパーク title=凡例幅指定 legw=10
${lexe}mbar.rb i=$ip/input3.csv o=$op/out2-4.html k=性別,年代 v=回数 f=テーマパーク title=グラフの縦横幅指定 height=200 width=200
${lexe}mbar.rb i=$ip/input3-sort.csv o=$op/out2-5.html k=性別,年代 v=人数 f=点数 title=vが数字で並びがばらばら height=150 width=200
${lexe}mbar.rb i=$ip/input3-null.csv o=$op/out2-6.html k=性別,年代 v=回数 f=テーマパーク title=nullありテスト
${lexe}mbar.rb i=$ip/input3-float.csv o=$op/out2-7.html k=性別,年代 v=回数 f=テーマパーク
${lexe}mbar.rb i=$ip/input3-mai.csv o=$op/out2-8.html k=性別,年代 v=回数 f=テーマパーク title=マイナス
# エラー
#${lexe}mbar.rb i=$ip/input1-str.csv o=$op/oute-1.html v=人口 f=年代 title=奈良県と北海道の年代ごとの人口
#${lexe}mbar.rb i=$ip/input2-str.csv o=$op/oute-2.html v=人口 f=年代 k=Pref title=奈良県と北海道の年代ごとの人口
#${lexe}mbar.rb i=$ip/input3-str.csv o=$op/oute-3.html v=回数 f=テーマパーク k=性別,年代
#${lexe}mbar.rb i=$ip/input2.csv o=$op/oute-1.html v=人口 f=年代 k=Pref title=奈良県と北海道の年代ごとの人口 cc=0
#${lexe}mbar.rb i=$ip/input1.csv o=$op/oute-2.html v=人口 f=年代 cc=10
#${lexe}mbar.rb i=$ip/input3.csv o=$op/oute-3.html k=性別,年代 v=回数 f=テーマパーク cc=10
#${lexe}mbar.rb i=$ip/input1-str.csv o=$op/oute-4.html v=人口 f=年代

diff -r -q answer xxresult
diff -r answer xxresult > diffcheck.log
