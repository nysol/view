
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

${lexe}msankey.rb i=$ip/dat1.csv o=$op/out10.html f=node1,node2 v=val
${lexe}msankey.rb i=$ip/man.csv o=$op/out1.html f=node1,node2 v=val
${lexe}msankey.rb i=$ip/man.csv o=$op/out2.html f=node1,node2 v=val t=たいとる

diff -r -q answer xxresult
diff -r answer xxresult > diffcheck.log
