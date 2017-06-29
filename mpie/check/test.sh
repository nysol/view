
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
${lexe}mpie.rb i=$ip/input1.csv o=$op/out0-1.html v=人口 f=年代
${lexe}mpie.rb i=$ip/input1.csv o=$op/out0-2.html v=人口 f=年代 title=奈良県の年代ごとの人口
${lexe}mpie.rb i=$ip/input1-null.csv o=$op/out0-3.html v=人口 f=年代 title=データにnullあり
${lexe}mpie.rb i=$ip/input1-sort.csv o=$op/out0-4.html v=人口 f=年代 title=数値順ではない
# 1次元
${lexe}mpie.rb i=$ip/input2.csv o=$op/out1-1.html v=人口 f=年代 k=Pref title=奈良県と北海道の年代ごとの人口
${lexe}mpie.rb i=$ip/input2.csv o=$op/out1-2.html v=人口 f=年代 k=Pref title=奈良県と北海道の年代ごとの人口 cc=1
${lexe}mpie.rb i=$ip/input2-sort.csv o=$op/out1-3.html v=人口 f=年代 k=Pref title=奈良県と北海道の年代ごとの人口 cc=1  title=1つの円グラフで折り返し
${lexe}mpie.rb i=$ip/input2-null.csv o=$op/out1-4.html v=人口 f=年代 k=Pref title=奈良県と北海道の年代ごとの人口 title=データにnullあり
# 2次元
${lexe}mpie.rb i=$ip/input3.csv o=$op/out2-1.html k=性別,年代 v=回数 f=テーマパーク
${lexe}mpie.rb i=$ip/input3.csv o=$op/out2-2.html k=性別,年代 v=回数 f=テーマパーク title=男女別年齢ごとのテーマパーク体験回数
#${lexe}mpie.rb i=$ip/input3.csv o=$op/out2-3.html k=性別,年代 v=回数 f=テーマパーク title=男女別年齢ごとのテーマパーク体験回数 legw=100 title=凡例幅指定
${lexe}mpie.rb i=$ip/input3.csv o=$op/out2-4.html k=性別,年代 v=回数 f=テーマパーク title=男女別年齢ごとのテーマパーク体験回数 pr=50 title=円の半径指定
${lexe}mpie.rb i=$ip/input3-sort.csv o=$op/out2-5.html k=性別,年代 v=人数 f=点数 title=男女別年齢ごとの点数 title=数値順ではない
${lexe}mpie.rb i=$ip/input3-null.csv o=$op/out2-6.html k=性別,年代 v=回数 f=テーマパーク title=nullありテスト title=データにnullあり
# エラー
#${lexe}mpie.rb i=$ip/input2.csv o=$op/oute-1.html v=人口 f=年代 k=Pref title=奈良県と北海道の年代ごとの人口 cc=0
#${lexe}mpie.rb i=$ip/input1.csv o=$op/oute-2.html v=人口 f=年代 cc=10
#${lexe}mpie.rb i=$ip/input3.csv o=$op/oute-3.html k=性別,年代 v=回数 f=テーマパーク cc=10
#${lexe}mpie.rb i=$ip/input1-str.csv o=$op/oute-4.html v=人口 f=年代

diff -r -q answer xxresult
diff -r answer xxresult > diffcheck.log
