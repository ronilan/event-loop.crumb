#!/bin/sh
default="v0.0.1"

arg=${1:-$default}
len=${#arg}
tag=$arg || $default

into=".tmp~crumb~inflate"

build_and_clean() {
  gcc src/*.c -Wall -lm -o crumb
  cd ..
  mv ./$into/crumb crumb
  rm -rf $into
}

if [ "$len" = 40 ] # its is a sha
then
  printf "\e[32m Building from SHA %s \e[0m \n" "$arg"
  git clone https://github.com/liam-ilan/crumb.git $into
  cd $into || exit
  git reset --hard "$arg"

  build_and_clean

  printf "\e[32m Crumb built successfully from %s! \e[0m \n" "$arg"
elif [ "$(printf '%s' "$tag" | cut -c 1)" = "v" ] # its is a sha
then # its is a tag
  printf "\e[32m Building version %s \e[0m \n" "$tag"
  git clone -c advice.detachedHead=false --branch "$tag" --depth 1 https://github.com/liam-ilan/crumb.git $into
  cd $into || exit

  build_and_clean

  printf "\e[32m Crumb version %s built successfully!\e[0m \n" "$tag"
else
  printf "\e[31m %s not valid version tag nor SHA \e[0m \n" "$arg"
fi
