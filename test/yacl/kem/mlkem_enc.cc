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


#include <vector>
// #include "yacl/base/exception.h"
#include "mlkem_enc.h"
extern "C"
{
#include "common/params.h"
#include "common/api.h"
}
namespace yacl::crypto {

namespace {
// see: https://www.openssl.org/docs/man3.0/man3/RSA_public_encrypt.html
// RSA_PKCS1_OAEP_PADDING: EME-OAEP as defined in PKCS #1 v2.0 with SHA-1, MGF1
// and an empty encoding parameter. This mode is recommended for all new
// applications.
// constexpr int kRsaPadding = RSA_PKCS1_OAEP_PADDING;
}  // namespace

std::pair<std::vector<uint8_t>, std::vector<uint8_t> > MLkemEncaps::Encaps()  {
    std::vector<uint8_t> ss(KYBER_SSBYTES);
    std::vector<uint8_t> ct(KYBER_CIPHERTEXTBYTES);

    crypto_kem_enc(ct.data(), ss.data(), ek_.data());

    return {ss, ct};
}

std::vector<uint8_t> MLkemDecaps::Decaps(std::vector<uint8_t> ciphertext) {
    std::vector<uint8_t> ss1(KYBER_SSBYTES);
    crypto_kem_dec(ss1.data(), ciphertext.data(), dk_.data());
    return ss1;
}


}  // namespace yacl::crypto
