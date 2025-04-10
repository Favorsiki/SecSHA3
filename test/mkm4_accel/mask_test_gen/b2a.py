def psi(x, r, len):
    tmp1 = x^r
    tmp2 = tmp1 - r
    ans = 0
    if tmp2 < 0:
        ans = tmp2 + 2**len
    else :
        ans = tmp2
    return ans % (2**len)

def Goubin(x1, x2, s, r, len):
    a1 = x1 ^ s
    a2 = x2 ^ s
    u = a1 ^ psi(a1, r^a2, len)
    A1 = u ^ psi(a1, r, len)
    A2 = a2
    return A1, A2


def B2A_q(B0, B1, I_r0, I_r1, I_r2, I_r3):
    x0, x1 = Goubin(B0, B1, I_r0, I_r1, 12)
    y0_without = (x0*33556320) >> 24
    y1_without = (x1*10080*3329) >> 24
    y0 = y0_without % 6658
    y1 = y1_without % 6658
    y0 = y0 + 1
    
    b0 = y0 % 2
    b1 = y1 % 2
    a0, a1 = Goubin(b0, b1, I_r2, I_r3, 1)
    z0 = (y0 - a0) % 6658
    z1 = (y1 - a1) % 6658
    c0 = (z0 - z0%2) % 6658
    c1 = (z1 - z0%2) % 6658
    A0 = (c0 >> 1) % (2**12)
    A1 = (c1 >> 1) % (2**12)
    return A0, A1

# B0 = 0x1a7
# B1 = 0x50e
# I_r0 = 0xa01
# I_r1 = 0x39a
# I_r2 = 0
# I_r3 = 1
# A0, A1 = B2A_q(B0, B1, I_r0, I_r1, I_r2, I_r3)
# print(B0^B1, B0, B1)
# print(A0+A1, A0, A1)
# print()

# B0 = 0x3a7
# B1 = 0x5fe
# I_r0 = 0x201
# I_r1 = 0x32a
# I_r2 = 1
# I_r3 = 1
# A0, A1 = B2A_q(B0, B1, I_r0, I_r1, I_r2, I_r3)
# print(B0^B1, B0, B1)
# print(A0+A1, A0, A1)
# print()

# B0 = 0x15a
# B1 = 0x55e
# I_r0 = 0xb71
# I_r1 = 0x31a
# I_r2 = 0
# I_r3 = 0
# A0, A1 = B2A_q(B0, B1, I_r0, I_r1, I_r2, I_r3)
# print(B0^B1, B0, B1)
# print(A0+A1, A0, A1)
# print()
import random
pk_6400 = "115ACE0E64677CBB7DCFC93C16D3A305F67615A488D711AA56698C5663AB7AC9CE66D547C0595F98A43F4650BBE08C364D976789117D34F6AE51AC063CB55C6CA32558227DFEF807D19C30DE414424097F6AA236A1053B4A07A76BE372A5C6B6002791EBE0AFDAF54E1CA237FF545BA68343E745C04AD1639DBC590346B6B9569B56DBBFE53151913066E5C85527DC9468110A136A411497C227DCB8C9B25570B7A0E42AADA6709F23208F5D496EBAB7843F6483BF0C0C73A40296EC2C6440001394C99CA173D5C775B7F415D02A5A26A07407918587C41169F2B7178755ACC27FC8B19C4C4B3FCD41053F2C74C8A10A8321241B2802432875AE808B9EF1365C7B8A52902F1317BA2FB0269F47930672107B4726FEF64547394D3320C8F120B3C2F4725B0305FAB88CC7981FCB09A76A1CBF7F179F43BB0A4C8B0590857F1E69708466C7F8607391E7BC5268BFD3D7A1DFFCB4ECA2A1C9B597593013D5FC4202EC2B74E57AB76BBCF3632BBAF97CDC418A6F16392838CA9BF45DDF023777B7561833C105190F94F302C59B531900BBC816361FAA5B3380CA3A893104CA7388B185671B3E5FE3790E9A626EC46D9B0B33C7A419AF7B32B6859894F575D82AC5456B5490A7AF8FE61046360589ECBA7244236F4123116B6174AA179249A49195B356C72FC6641F0251812EAA98570B046699070E0819DC2713F469137DFC6A3D7B92B298995EE780369153AC366B06D7249CD09E1B3378FB04399CECB8650581D637C79AE67D6F2CAF6ABACF598159A7792CB3C971D1499D2373AD20F63F03BB59ED137384AC61A7155143B8CA4932612EC915E4CA346A9BCE5DD60417C6B2A89B1CC435643F875BDC5A7E5B3481CF919EA09172FEBC46D4FC3FB0CB9591704EE2DBB61844B2F3314A06BB6C6D34005E485CE667BDC7D098586928D2D91340F00419EA401351A240A0B041058BEFB0C2FD32645B7A2DF8F5CBFD873327C978D7B351A28088438837024C52B9C295CD713646FB5D6C0CCFB470734AC2B2BC8123C2C13DF6938E92455A862639FEB8A64B85163E32707E037B38D8AC3922B45187BB65EAFD465FC64A0C5F8F3F9003489415899D59A543D8208C54A3166529B53922"
m_256 = "0A55A4433DBAAC3B616D6C4338FCAEC4A9685E8AA37D6A5BD74D619495CD3FED"
r_256 = "803508F1A4EBA775DC5D5AEB661DBB94D688F94EC6137FC24148462D232527F8"
c_6144 = "EDF24145E43B4F6DC6BF8332F54E02CAB02DBF3B5605DDC90A15C886AD3ED489462699E4ABED44350BC3757E2696FBFB2534412E8DD201F1E4540A3970B055FE3B0BEC3A71F9E115B3F9F39102065B1CCA8314DCC795E3C0E8FA98EE83CA6628457028A4D09E839E554862CF0B7BF56C5C0A829E8657947945FE9C22564FBAEBC1B3AF350D7955508A26D8A8EB547B8B1A2CF03CCA1AABCE6C3497783B6465BA0B6E7ACBA821195124AEF09E628382A1F914043BE7096E952CBC4FB4AFED13609046117C011FD741EE286C83771690F0AEB50DA0D71285A179B215C6036DEB780F4D16769F72DE16FDADAC73BEFA5BEF8943197F44C59589DC9F4973DE1450BA1D0C3290D6B1D683F294E759C954ABE8A7DA5B1054FD6D21329B8E73D3756AFDA0DCB1FC8B1582D1F90CF275A102ABC6AC699DF0C5870E50A1F989E4E6241B60AAA2ECF9E8E33E0FFCF40FE831E8FDC2E83B52CA7AB6D93F146D29DCA53C7DA1DB4AC4F2DB39EA120D90FA60F4D437C6D00EF483BC94A3175CDA163FC1C2828BE4DBD6430507B584BB5177E171B8DDA9A4293C3200295C803A865D6D2166F66BA5401FB7A0E853168600A2948437E036E3BF19E12FD3F2A2B8B343F784248E8D685EB0AFDE6315338730E7A1001C27D8D2A76FA69D157BA1AC7AD56DA5A8C70FE4B5B8D786DC6FC0566BA8E1B8816334D32A3FB1CE7D4D5E4C332AF7B003D091741A3D5C965292255DFF8ED2BBF1F9116BE50C17B8E548748AD4B2E957BBD1953482A2E1718CEC66CD2C81F572D552B7187885E6B8943D6431413C59EBB7E036048490BE5289E95B20A89E8B159F61A9A9886E147568F4C9021F362F02688A1C8C3BB0D24086880E55B6EDB43F3745D2C166DC1CB743C76FE6BE523A893CC764D16435C37851252A81E2FFBA0F18971A3DEE37D4877CB928E36E5235037A6B2057897D518A5F0E348E3AB6D5B52DFC60757F3B41A4FEC7828F1DEEAF4587CCC8EADF647F4D203B2FAA05A649B582340CB4CACE57A30711BE752FACF0227D0A80C4128442DDC544BE805B9CFE8FE9B1237C80F96787CD9281CCF270C1AFC0670D"

din_file = "KYBER_PKE_ENC_DIN.txt"
dout_file = "KYBER_PKE_ENC_DOUT.txt"

def string_split(string, length):
    return [string[i:i+length] for i in range(0, len(string), length)]

pk = string_split(pk_6400, 8)
m = string_split(m_256, 8)
r = string_split(r_256, 8)
c = string_split(c_6144, 8)


file = open(din_file, "w")

for item in pk:
    file.write(item+'\n')
for item in r:
    file.write(item+'\n')
m_s1 = []
rand = 0x182679ef
for item in m:
    data = int(item, 16)
    rand = (rand + 0x1967af01) % (2**32)
    data = data ^ rand
    m_s1.append(rand)
    #print(hex(data), hex(rand))
    file.write(hex(data)[2:]+'\n')
for data in m_s1:
    file.write(hex(data)[2:]+'\n')
file.close()
file = open(dout_file, "w")
for item in c:
    file.write(item+'\n')
file.close()
