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

#include "key_utils.h"
extern "C"
{
#include "common/api.h"
}

namespace yacl::crypto {

namespace {

    std::pair<std::vector<uint8_t>, std::vector<uint8_t> > GenMLkemKeyPairToPemBuf() {
        std::vector<uint8_t> ek;
        std::vector<uint8_t> dk;
        crypto_kem_keypair(ek.data(), dk.data());
        return {ek, dk};
    }
}
}