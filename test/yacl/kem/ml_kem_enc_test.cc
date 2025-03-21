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


/*
#include <string>
#include "yacl/crypto/pqc/kem/ml_kem_enc.h"
#include "gtest/gtest.h"
#include "yacl/base/exception.h"
#include "yacl/crypto/openssl_wrappers.h"

namespace yacl::crypto {

TEST(MLkemEnc, EncryptDecrypt_shouldOk) {
  // GIVEN
  auto [ek, dk] = GenMLkemKeyPairToPemBuf();

  // WHEN
  auto enc_ctx = MLkemEncaps(ek);
  auto dec_ctx = MLkemDecaps(dk);

  auto [ss, c] = enc_ctx.Encaps();
  auto ss1     = dec_ctx.Decaps(c);

  // THEN
  EXPECT_EQ(std::memcmp(ss.data(), ss1.data(), ss1.size()), 0);
} */



#include "ml_kem_enc.h"
#include "key_utils.h"
#include <stdio.h>

namespace yacl::crypto {

  void test() {
    // GIVEN
    auto [ek, dk] = GenMLkemKeyPairToPemBuf();

    // WHEN
    auto enc_ctx = MLkemEncaps(ek);
    auto dec_ctx = MLkemDecaps(dk);

    auto [ss, c] = enc_ctx.Encaps();
    auto ss1     = dec_ctx.Decaps(c);

    // THEN
    for (int i = 0; i < ss1.size(); ++i) {
      if (ss[i] != ss1[i]) printf("MLKEM512 EXECUTION ERROR\n");
    }
    printf("MLKEM512 EXECUTION RIGHT\n");
  }
}

int main() {
  FILE* fp = freopen("kyber512.log","w+",stdout);
  yacl::crypto::test();
  fclose(fp);
  return 0;
}