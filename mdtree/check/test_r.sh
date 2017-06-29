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
rm -rf ./$op
mkdir -p $op

cat >xxscp.R <<'EOF'
library(pmml)
library(rpart)
iris.rp=rpart(Species~.,data=iris)
sink("model_r1.pmml")
pmml(iris.rp)
sink()

stagec$progstat <- factor(stagec$pgstat, levels = 0:1, labels = c("No", "Prog"))
cfit <- rpart(progstat ~ age + eet + g2 + grade + gleason + ploidy, data = stagec, method = 'class')
sink("model_r2.pmml")
pmml(cfit)
sink()
EOF

r --vanilla < xxscp.R


${lexe}mdtree.rb i=model_r1.pmml o=$op/out_r1.html
${lexe}mdtree.rb i=model_r2.pmml o=$op/out_r2.html


#diff -r -q answer $op
#diff -r answer $op > diffcheck.log
