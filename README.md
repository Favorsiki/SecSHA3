# SecSHA3

### 1. Introduction

​        [MKM4](https://github.com/masked-kyber-m4/mkm4) is an open-source Post-Quantum-Cryptography algorithm library with anti side channel capability. In this work, we provided optimized software and hardware co-design for the SHA-3 algorithm on the Zynq-7020 SoC, improving the performance of MKM4 through hardware acceleration and software optimization while ensuring a certain level of anti side channel security. On the hardware side, we adopt a unified high-level architecture to summarize the different characteristics of the SHA-3 algorithm series, and design a dedicated keccak-f hardware accelerator to expand different security requirements. On the software side, we use command words to program hardware accelerators and use DMA technology to reduce performance degradation caused by communication overhead.
​        Combining these acceleration and optimization methods, experimental results show that the overall performance of the  SHA-3 algorithm in MKM4 project on the ARM has improved by 13.7 times, and the overall performance of the MKM4 project has increased by 2.2 times.

### 2. How to use

##### 2.1 environment

- Zynq-7000 SoC
- Vivado 2022.1
- Vitis 2022.1

##### 2.2 Design Rationale

![Design Png](/img/architecture.png)

##### 2.3 synthesize accelerator (PL)

​         In the Vivado, the platform is connected as shown in the following figure.


![Diagram Png](/img/diagram.png)


##### 2.4 compile software (PS)

![Diagram Png](/img/compile.png)



### 3. Test

##### 3.1 Performance

![Diagram Png](/img/performance.png)




