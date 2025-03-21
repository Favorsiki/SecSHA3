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

    std::pair<std::vector<uint8_t>, std::vector<uint8_t> > GenMLkemKeyPairToPemBuf() {
        // uint8_t ek[CRYPTO_PUBLICKEYBYTES], dk[CRYPTO_PUBLICKEYBYTES];
        // crypto_kem_keypair(ek, dk);
        // std::vector<uint8_t> vec_ek(ek, ek+CRYPTO_PUBLICKEYBYTES);
        // std::vector<uint8_t> vec_dk(dk, dk+CRYPTO_PUBLICKEYBYTES);
        std::vector<uint8_t> ek(CRYPTO_PUBLICKEYBYTES);
        std::vector<uint8_t> dk(CRYPTO_SECRETKEYBYTES);
        crypto_kem_keypair(ek.data(), dk.data());
        return {ek, dk};
    }

}