#!/usr/bin/env bash

# インストールされたコマンドでのチェック
if [ "$1" = "g" ] ; then
  lexe=""
# ローカルでのチェック
else
  lexe='ruby -I../../lib ../bin/'
fi

ip=indat
op=outdat


rm -f diffcheck.log
rm -rf xxans
rm -rf xxrsl
rm -rf ./$op
mkdir -p $op
mkdir -p xxans
mkdir -p xxrsl

mbonsai c=入院歴 n=来店距離 p=購入パターン d=性別 i=$ip/dat1.csv O=$op/out2_1 seed=11
${lexe}mdtree.rb i=$op/out2_1/model.pmml o=$op/out2_1/model.html
${lexe}mdtree.rb alpha=0.1 i=$op/out2_1/model.pmml o=$op/out2_1/model2.html

${lexe}mdtree.rb i=$op/out2_1/model.pmml o=$op/out2_1/model11.html -bar
${lexe}mdtree.rb alpha=0.1 i=$op/out2_1/model.pmml o=$op/out2_1/model12.html -bar


${lexe}mdtree.rb i=$ip/model1.pmml o=$op/out1.html
${lexe}mdtree.rb i=$ip/model2.pmml o=$op/out2.html
${lexe}mdtree.rb i=$ip/model3.pmml o=$op/out3.html
${lexe}mdtree.rb i=$ip/model4.pmml o=$op/out4.html
${lexe}mdtree.rb i=$ip/model5.pmml o=$op/out5.html
${lexe}mdtree.rb i=$ip/model6.pmml o=$op/out6.html
${lexe}mdtree.rb i=$ip/model7.pmml o=$op/out7.html

${lexe}mdtree.rb i=$ip/model1.pmml o=$op/out21.html -bar
${lexe}mdtree.rb i=$ip/model2.pmml o=$op/out22.html -bar
${lexe}mdtree.rb i=$ip/model3.pmml o=$op/out23.html -bar
${lexe}mdtree.rb i=$ip/model4.pmml o=$op/out24.html -bar
${lexe}mdtree.rb i=$ip/model5.pmml o=$op/out25.html -bar
${lexe}mdtree.rb i=$ip/model6.pmml o=$op/out26.html -bar
${lexe}mdtree.rb i=$ip/model7.pmml o=$op/out27.html -bar


${lexe}mdtree.rb i=$ip/model1.pmml alpha=0.01 o=$op/out8.html
${lexe}mdtree.rb i=$ip/model2.pmml alpha=0.01 o=$op/out9.html
${lexe}mdtree.rb i=$ip/model3.pmml alpha=0.01 o=$op/out10.html
${lexe}mdtree.rb i=$ip/model4.pmml alpha=0.01 o=$op/out11.html
${lexe}mdtree.rb i=$ip/model5.pmml alpha=0 o=$op/out12.html
${lexe}mdtree.rb i=$ip/model6.pmml alpha=0 o=$op/out13.html
${lexe}mdtree.rb i=$ip/model7.pmml alpha=1 o=$op/out14.html


${lexe}mdtree.rb i=$ip/model1.pmml alpha=0.01 o=$op/out28.html -bar
${lexe}mdtree.rb i=$ip/model2.pmml alpha=0.01 o=$op/out29.html -bar
${lexe}mdtree.rb i=$ip/model3.pmml alpha=0.01 o=$op/out30.html -bar
${lexe}mdtree.rb i=$ip/model4.pmml alpha=0.01 o=$op/out31.html -bar
${lexe}mdtree.rb i=$ip/model5.pmml alpha=0 o=$op/out32.html -bar
${lexe}mdtree.rb i=$ip/model6.pmml alpha=0 o=$op/out33.html -bar
${lexe}mdtree.rb i=$ip/model7.pmml alpha=1 o=$op/out34.html -bar

cp -r answer/* xxans/
cp -r $op/* xxrsl/

grep -v '<Timestamp>' < answer/out2_1/model.pmml > xxans/out2_1/model.pmml 
grep -v '<Timestamp>' <    $op/out2_1/model.pmml > xxrsl/out2_1/model.pmml 


diff -r -q xxans/ xxrsl/
diff -r xxans/ xxrsl/ > diffcheck.log
