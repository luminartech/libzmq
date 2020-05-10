#!/bin/bash

set -euxo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

num_chars=1024
password=`openssl rand -base64 $num_chars`

namespaces=(
  semantic_segmentation
)
aarchs=(
  x86_64
  x86_64
  aarch64
  aarch64
)
model_types=(
  single
  multi
  single
  multi
)

num_namespaces=${#namespaces[@]}
num_models=${#aarchs[@]}
echo 'Found' $num_namespaces 'models'

for (( ns=0; ns<num_namespaces; ns++ ))
do
  namespace=${namespaces[$ns]}
  header_path="$DIR/../include/lum/pdk/internal/${namespace}/secret_key.h"

  echo 'Writing' $header_path
  echo "/// secret_key.h
/// Copyright (c) 2020, Luminar Technologies, Inc.
/// This material contains confidential and trade secret information of Luminar
/// Technologies. Reproduction, adaptation, and distribution are prohibited,
/// except to the extent expressly permitted in writing by Luminar Technologies.

#ifndef LUM_PDK_INTERNAL_${namespace^^}_SECRET_KEY_H
#define LUM_PDK_INTERNAL_${namespace^^}_SECRET_KEY_H

#include <string>
#include <unordered_map>

#include <lum/pdk/internal/common/encryption/string_obfuscator.h>

namespace lum {
namespace pdk {
namespace ${namespace} {
namespace aes {

// NOLINTNEXTLINE(cert-err58-cpp)
static const std::unordered_map<std::string, std::pair<std::string, std::string>> CONSTANTS = {
" > $header_path

  for (( c=0; c<num_models; c++ ))
  do
    aarch=${aarchs[$c]}
    model_type=${model_types[$c]}

    model_path="$DIR/../data/models/${namespace}/${aarch}/${model_type}.pt"
    echo 'Encrypting' $model_path 'to' $model_path.enc
    output=`openssl aes-256-cbc -p -salt -pbkdf2 -in $model_path -out $model_path.enc -k "$password" | cut -d '=' -f 2 | tail -2 | tr '\n' ' '`

    IFS=' ' read -r -a array <<< $output
    echo 'Key' ${array[0]}
    echo 'IV' ${array[1]}

    echo "  {\"/data/models/${namespace}/${aarch}/${model_type}.pt.enc\", {
      OBFUSCATE(\"${array[0]}\"),
      OBFUSCATE(\"${array[1]}\")
    }}," >> $header_path
  done

  echo "
};
} // namespace aes
} // namespace ${namespace}
} // namespace pdk
} // namespace lum

#endif
" >> $header_path
done
