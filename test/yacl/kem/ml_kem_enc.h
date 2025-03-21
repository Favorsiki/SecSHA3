
// Copyright 2019 Ant Group Co., Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#pragma once

#include <memory>
#include <utility>
#include <vector>

// #include "yacl/crypto/key_utils.h"
// #include "yacl/secparam.h"
// #include "yacl/crypto/pqc/kem/kem_interface.h"


#include "kem_interface.h"

/* security parameter declaration */
// YACL_MODULE_DECLARE("ml_kem_enc", SecParam::C::UNKNOWN, SecParam::S::UNKNOWN);

namespace yacl::crypto {

// RSA with OAEP
class MLkemEncaps : public KemEncaps{
 public:
  explicit MLkemEncaps(std::vector<uint8_t>& ek) : ek_(std::move(ek)) {}

  KemScheme GetScheme() const override { return scheme_; }
  //std::vector<uint8_t> Encaps(ByteContainerView plaintext) override;
  std::pair<std::vector<uint8_t>, std::vector<uint8_t> > Encaps() override;

 private:
  const std::vector<uint8_t> ek_;
  const KemScheme scheme_ = KemScheme::MLKEM512;
};

class MLkemDecaps : public KemDecaps {
 public:
  explicit MLkemDecaps(std::vector<uint8_t>& dk) : dk_(std::move(dk)) {}


  KemScheme GetScheme() const override { return scheme_; }
  //std::vector<uint8_t> Decaps(ByteContainerView ciphertext) override;
  std::vector<uint8_t> Decaps(std::vector<uint8_t> ciphertext) override;

 private:
  const std::vector<uint8_t> dk_;
  const KemScheme scheme_ = KemScheme::MLKEM512;
};

}  // namespace yacl::crypto
