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

#include <vector>

#include "yacl/base/byte_container_view.h"

namespace yacl::crypto {

enum class KemScheme { UNKNOWN, MLKEM512 };

class KemEncaps {
 public:
  virtual ~KemEncaps() = default;
  virtual KemScheme GetScheme() const = 0;
  virtual std::vector<uint8_t> Encaps(ByteContainerView plaintext) = 0;
}

class KemDecaps {
 public:
  virtual ~KemDecaps() = default;
  virtual KemScheme GetScheme() const = 0;
  virtual std::vector<uint8_t> Decaps(ByteContainerView ciphertext) = 0;
};

}  // namespace yacl::crypto
