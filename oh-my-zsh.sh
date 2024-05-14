#!/bin/bash

git clone https://github.com/ohmyzsh/ohmyzsh.git

rm -Rf ohmyzsh/.git

cp -a ohmyzsh /usr/local/share/oh-my-zsh

cat ohmyzsh/templates/zshrc.zsh-template > /etc/skel/.zshrc

sed -i 's|^export ZSH=$HOME/.oh-my-zsh$|export ZSH=/usr/local/share/oh-my-zsh|' /etc/skel/.zshrc
