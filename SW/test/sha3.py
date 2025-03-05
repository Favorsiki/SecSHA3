# Lane(x,y) = A[x,y,0] || A[x,y,1] || ... || A[x,y,63]
# Plane(y) = Lane(0,y) || ... || Lane(4,y) = A[0,y,0]...A[0,y,63] || A[1,y,0]...A[1,y,63] || ... || A[4,y,0]...A[4,y,63]
# state[5*y+x] = A[x,y,0] || A[x,y,1] || ... || A[x,y,63]
import copy

def RORN_(val, n, N=64):
    bit=int('1'*N,2)
    val &= bit
    return ((val <<(N - n))&bit) | ((val >> n)&bit)

def ROLN_(val,n,N=64):
    bit=int('1'*N,2)
    val &= bit
    return ((val >> (N - n))&bit) | ((val << n)&bit)

def verify(a, b, sel=False):
    if sel:
        for item in a:
            print(hex(item)[2:], end=" ")
        print()
        for item in b:
            print(hex(item)[2:], end=" ")
        print()
    a_len = len(a)
    b_len = len(b)
    if (a_len != b_len):
        print("Verify Fail1")
        return False
    for i in range(a_len):
        if a[i] != b[i]:
            print("Verify Fail2")
            return False
    return True

def Hexstr2ByteArray(hexstr):
    out = []
    str_data = ""
    for i,s in enumerate(hexstr):
        if i%2 == 0:
            str_data = s
        else :
            str_data += s
            out.append(int(str_data,16))
    return out

def LOAD64(data, length=8):
    tmp = 0
    for j in range(length):
        tmp = (tmp<<8) + data[length-1-j]
    return tmp
    
def STORE64(out, data64):
    tmp = data64
    for j in range(8):
        out.append(tmp&0xff)
        tmp = int (tmp>>8)

def keccak_StateXorBytes(state, data_in, length, offset):
    # 在特殊情况下: offset被设置为8的倍数, length被设置为8的倍数
    # indx = int (offset/8)
    # data_indx = 0
    # shift = offset - indx * 8
    # if shift:
    #     for i in range(shift,8):
    #         state[indx] = state | (data_in[data_indx] << (shift*8))
    #         data_indx += 1
    # while (data_indx + 8) < length:

    offset64 = int(offset/8)
    data = copy.deepcopy(data_in)
    indx = offset64
    while length >= 8:
        tmp = LOAD64(data)
        state[indx] = state[indx] ^ tmp
        indx = indx + 1
        data = data[8:]
        length = length - 8
    # if length%8 != 0
    tmp = LOAD64(data_in, length)
    state[indx] = state[indx] ^ tmp
        
def keccak_StateExtractBytes(state, data_out, length, offset):
    # 在特殊情况下: offset被设置为8的倍数, length被设置为8的倍数
    offset64 = int(offset/8)
    for i in range(int(length/8)): # there is a bug
        STORE64(data_out, state[i+offset64])

def theta(state):
    # C[x] = A[x,0] ^ A[x,1] ^ A[x,2] ^ A[x,3] ^ A[x,4]
    # D[x] = C[(x-1)%5] ^ C[(x+1)%5, (z-1)%64]
    # A[x,y,z] = A[x,y,z] ^ D[x,z]
    C = []
    D = []
    for x in range(5):
        C.append(state[x]^state[x+5]^state[x+10]^state[x+15]^state[x+20])
    for x in range(5):
        tmp1 = C[(x+1)%5]
        tmp2 = ROLN_(tmp1,1)
        D.append(C[(x+4)%5]^tmp2)
    for y in range(5):
        for x in range(5):
            tmp1 = D[x]
            state[5*y+x] = state[5*y+x] ^ tmp1

def rho(state):
    # A[0,0,z] = A[0,0,z]
    # for t in range(24):
    #    A[x,y,z] = A[x,y,(z-(t+1)(t+2)/2)%64]
    #    (x,y) = (y, (2x+3y)%5) 
    x = 1
    y = 0

    for tt in range(24):
        shift0 = int(((tt+1)*(tt+2))/2) % 64
        state[5*y+x] = ROLN_(state[5*y+x], shift0)
        tmp = (2*x + 3*y) % 5
        x = y
        y = tmp

def pi(state):
    # A'[x,y,z] = A[(x+3y)%5,x,z]
    tmp = []
    for y in range(5):
        for x in range(5):
            xx = (x+3*y) % 5
            tmp.append(state[(5*x+xx)%25])
    for y in range(5):
        for x in range(5):
            state[5*y+x]= tmp[5*y+x]

def chi(state):
    # A'[x,y,z] = A[z,y,z] ^ ((A[(x+1)%5,y,z]^ 1) & A[(x+2)%5,y,z])
    tmp = []
    for y in range(5):
        for x in range(5):
            t1 = state[5*y + ((x+1)%5)]
            t1 = ~t1
            tmp.append(state[5*y+x] ^ (t1 & state[5*y + ((x+2)%5)]))
    for y in range(5):
        for x in range(5):
            state[5*y+x] = tmp[5*y+x]

KeccakF_RoundConstants = [
    0x0000000000000001,
    0x0000000000008082,
    0x800000000000808a,
    0x8000000080008000,
    0x000000000000808b,
    0x0000000080000001,
    0x8000000080008081,
    0x8000000000008009,
    0x000000000000008a,
    0x0000000000000088,
    0x0000000080008009,
    0x000000008000000a,
    0x000000008000808b,
    0x800000000000008b,
    0x8000000000008089,
    0x8000000000008003,
    0x8000000000008002,
    0x8000000000000080,
    0x000000000000800a,
    0x800000008000000a,
    0x8000000080008081,
    0x8000000000008080,
    0x0000000080000001,
    0x8000000080008008]

def iota(state, ir):
    # A'[x,y,z] = A[x,y,z]
    # A'[0,0] = A[0,0] ^ RC
    state[0] = state[0] ^ KeccakF_RoundConstants[ir]

def keccakf1600_StatePermute(state):
    for ir in range(24):
        theta(state)
        rho(state)
        pi(state)
        chi(state)
        iota(state, ir)
        #print("y  %016x %016x %016x %016x " % (state[24],state[23],state[22],state[21]))

def keccak_absorb(state, r, m , mlen, sha3_padding):
    # int r; 
    # uint8_t*m; 
    # int mlen; 
    # uint8_t sha3_padding;

    m_r_base = 0
    while (mlen >= r):
        for i in range(int(r/8)):
            tmp = 0
            for j in range(8):
                tmp = (tmp<<8) + m[m_r_base+8*i+7-j]
            
            state[i] = state[i] ^ tmp
        
        keccakf1600_StatePermute(state)
        mlen = mlen - r
        m_r_base = m_r_base + r

    t = [0] * 200
    for i in range(mlen):
        t[i] = m[m_r_base+i]
    t[mlen] = sha3_padding
    t[r-1] = t[r-1] | 0x80
    for i in range(int(r/8)):
        tmp = 0
        for j in range(8):
            tmp = (tmp<<8) + t[8*i+7-j]
        state[i] = state[i] ^ tmp

def keccak_squeezeblocks(state, r, nblocks):
    cnt = nblocks
    out = []
    while cnt > 0:
        cnt = cnt - 1
        keccakf1600_StatePermute(state)
        for i in range(int(r/8)):
            tmp = state[i]
            for j in range(8):
                out.append(tmp&0xff)
                tmp = int (tmp>>8)
    return out

def keccak_inc_absorb(state_inc, r, m, mlen):
    while (mlen + state_inc[25] >= r):
        keccak_StateXorBytes(state_inc, m, r-state_inc[25], state_inc[25])
        # offset = int(state_inc[25]/8)
        # length = r - state_inc[25]
        # for i in range(int(length/8)):
        #     tmp = LOAD64(m)
        #     m = m[8:]
        #     state_inc[i+offset] = state_inc[i+offset] ^ tmp
        
        keccakf1600_StatePermute(state_inc)
        mlen = mlen - (r - state_inc[25])
        m = m[r-state_inc[25]:]
        state_inc[25] = 0

    keccak_StateXorBytes(state_inc, m, mlen, state_inc[25])
    # offset = int(state_inc[25]/8)
    # length = mlen
    # for i in range(int(length/8)):
    #     tmp = 0
    #     for j in range(8):
    #         tmp = (tmp<<8) + m[8*i+7-j]
    #     state_inc[i+offset] = state_inc[i+offset] ^ tmp
    
    state_inc[25] = state_inc[25] + mlen

def keccak_inc_finalize(state_inc, r, sha3_padding):
    t = [0] * 200
    t[state_inc[25]] = sha3_padding
    t[r - 1] |= 128

    keccak_StateXorBytes(state_inc, t, r, 0)
    # offset = 0
    # length = r
    # for i in range(int(length/8)):
    #     tmp = 0
    #     for j in range(8):
    #         tmp = (tmp<<8) + t[8*i+7-j]
    #     state_inc[i+offset] = state_inc[i+offset] ^ tmp
    
    state_inc[25] = 0

def keccak_inc_squeeze(state_inc, r, outlen):
    out = []
    if outlen < state_inc[25]:
        len = outlen
    else:
        len = state_inc[25]
    keccak_StateExtractBytes(state_inc[0:25], out, len, r-state_inc[25])
    outlen = int(outlen - len)
    state_inc[25] = state_inc[25] - len

    while (outlen > 0) :
        keccakf1600_StatePermute(state_inc)
        if outlen < r :
            len = outlen
        else:
            len = r
        keccak_StateExtractBytes(state_inc[0:25], out, len, 0)
        outlen = outlen - len
        state_inc[25] = r - len 
    return out

SHAKE128_RATE = 168
SHAKE256_RATE = 136
SHA3_256_RATE = 136
SHA3_512_RATE = 72

def xof_absorb(state, rho, indx1, indx2):
    # uint8_t rho[32];
    # uint8_t indx1, indx2;
    ext_seed = []
    for item in rho:
        ext_seed.append(item)
    ext_seed.append(indx1)
    ext_seed.append(indx2)
    keccak_absorb(state, 168, ext_seed, len(ext_seed), 0x1F)

def xof_squeezeblocks(state, nblocks):
    out = keccak_squeezeblocks(state, SHAKE128_RATE, nblocks)
    return out

def prf(sigma, nonce, outlen):
    # uint8_t sigma[32];
    ext_seed = []
    for item in sigma:
        ext_seed.append(item)
    ext_seed.append(nonce)

    nblocks = int(outlen / SHAKE256_RATE)
    state = [0] * 25
    keccak_absorb(state, SHA3_256_RATE, ext_seed, len(ext_seed), 0x1F)
    out = keccak_squeezeblocks(state, SHA3_256_RATE, nblocks)

    outlen = outlen - nblocks*SHA3_256_RATE
    if (outlen > 0):
        out_tmp = keccak_squeezeblocks(state,SHA3_256_RATE,1)
        for i in range(outlen):
            out.append(out_tmp[i])
    return out

def kdf(IN, INlen=64, outlen=32):
    nblocks = int(outlen / SHAKE256_RATE)
    state = [0] * 25
    keccak_absorb(state, SHAKE256_RATE, IN, INlen, 0x1F)
    out = keccak_squeezeblocks(state, SHAKE256_RATE, nblocks)

    outlen = outlen - nblocks*SHAKE256_RATE
    if (outlen > 0):
        out_tmp = keccak_squeezeblocks(state,SHAKE256_RATE,1)
        for item in out_tmp:
            out.append(item)
    return out

def hash_g(IN, INlen, outlen=64):
    out = []
    state = [0] * 25
    keccak_absorb(state, SHA3_512_RATE, IN, INlen, 0x06)
    out_tmp = keccak_squeezeblocks(state, SHA3_512_RATE, 1)
    for i in range(outlen):
        out.append(out_tmp[i])
    return out

def hash_h(IN, INlen, outlen=32):
    out = []
    state = [0] * 25
    keccak_absorb(state, SHA3_256_RATE, IN, INlen, 0x06)
    out_tmp = keccak_squeezeblocks(state, SHA3_256_RATE, 1)
    for i in range(outlen):
        out.append(out_tmp[i])
    return out

def shake128_inc_absorb(state_inc, data, data_len):
    keccak_inc_absorb(state_inc, SHAKE128_RATE, data, data_len)

def shake128_inc_finalize(state_inc):
    keccak_inc_finalize(state_inc, SHAKE128_RATE, 0x1F)

def shake128_inc_squeeze(state_inc, outlen):
    out = keccak_inc_squeeze(state_inc, SHAKE128_RATE, outlen)
    return out

if __name__ == "__main__":
    G_d = "7C9935A0B07694AA0C6D10E4DB6B1ADD2FD81A25CCB148032DCD739936737F2D"
    xof_rho = "65EAFD465FC64A0C5F8F3F9003489415899D59A543D8208C54A3166529B53922"
    prf_sigma = "ABB274A92ACEE034D3BAEE5C7BFAEDC2A7FAAAC404F37C9A3B15BCB3CFF80803"
    H_m = "147C03F7A5BEBBA406C8FAE1874D7F13C80EFE79A3A9A874CC09FE76F6997615"
    H_pk = "115ACE0E64677CBB7DCFC93C16D3A305F67615A488D711AA56698C5663AB7AC9CE66D547C0595F98A43F4650BBE08C364D976789117D34F6AE51AC063CB55C6CA32558227DFEF807D19C30DE414424097F6AA236A1053B4A07A76BE372A5C6B6002791EBE0AFDAF54E1CA237FF545BA68343E745C04AD1639DBC590346B6B9569B56DBBFE53151913066E5C85527DC9468110A136A411497C227DCB8C9B25570B7A0E42AADA6709F23208F5D496EBAB7843F6483BF0C0C73A40296EC2C6440001394C99CA173D5C775B7F415D02A5A26A07407918587C41169F2B7178755ACC27FC8B19C4C4B3FCD41053F2C74C8A10A8321241B2802432875AE808B9EF1365C7B8A52902F1317BA2FB0269F47930672107B4726FEF64547394D3320C8F120B3C2F4725B0305FAB88CC7981FCB09A76A1CBF7F179F43BB0A4C8B0590857F1E69708466C7F8607391E7BC5268BFD3D7A1DFFCB4ECA2A1C9B597593013D5FC4202EC2B74E57AB76BBCF3632BBAF97CDC418A6F16392838CA9BF45DDF023777B7561833C105190F94F302C59B531900BBC816361FAA5B3380CA3A893104CA7388B185671B3E5FE3790E9A626EC46D9B0B33C7A419AF7B32B6859894F575D82AC5456B5490A7AF8FE61046360589ECBA7244236F4123116B6174AA179249A49195B356C72FC6641F0251812EAA98570B046699070E0819DC2713F469137DFC6A3D7B92B298995EE780369153AC366B06D7249CD09E1B3378FB04399CECB8650581D637C79AE67D6F2CAF6ABACF598159A7792CB3C971D1499D2373AD20F63F03BB59ED137384AC61A7155143B8CA4932612EC915E4CA346A9BCE5DD60417C6B2A89B1CC435643F875BDC5A7E5B3481CF919EA09172FEBC46D4FC3FB0CB9591704EE2DBB61844B2F3314A06BB6C6D34005E485CE667BDC7D098586928D2D91340F00419EA401351A240A0B041058BEFB0C2FD32645B7A2DF8F5CBFD873327C978D7B351A28088438837024C52B9C295CD713646FB5D6C0CCFB470734AC2B2BC8123C2C13DF6938E92455A862639FEB8A64B85163E32707E037B38D8AC3922B45187BB65EAFD465FC64A0C5F8F3F9003489415899D59A543D8208C54A3166529B53922"
    H_c = "EDF24145E43B4F6DC6BF8332F54E02CAB02DBF3B5605DDC90A15C886AD3ED489462699E4ABED44350BC3757E2696FBFB2534412E8DD201F1E4540A3970B055FE3B0BEC3A71F9E115B3F9F39102065B1CCA8314DCC795E3C0E8FA98EE83CA6628457028A4D09E839E554862CF0B7BF56C5C0A829E8657947945FE9C22564FBAEBC1B3AF350D7955508A26D8A8EB547B8B1A2CF03CCA1AABCE6C3497783B6465BA0B6E7ACBA821195124AEF09E628382A1F914043BE7096E952CBC4FB4AFED13609046117C011FD741EE286C83771690F0AEB50DA0D71285A179B215C6036DEB780F4D16769F72DE16FDADAC73BEFA5BEF8943197F44C59589DC9F4973DE1450BA1D0C3290D6B1D683F294E759C954ABE8A7DA5B1054FD6D21329B8E73D3756AFDA0DCB1FC8B1582D1F90CF275A102ABC6AC699DF0C5870E50A1F989E4E6241B60AAA2ECF9E8E33E0FFCF40FE831E8FDC2E83B52CA7AB6D93F146D29DCA53C7DA1DB4AC4F2DB39EA120D90FA60F4D437C6D00EF483BC94A3175CDA163FC1C2828BE4DBD6430507B584BB5177E171B8DDA9A4293C3200295C803A865D6D2166F66BA5401FB7A0E853168600A2948437E036E3BF19E12FD3F2A2B8B343F784248E8D685EB0AFDE6315338730E7A1001C27D8D2A76FA69D157BA1AC7AD56DA5A8C70FE4B5B8D786DC6FC0566BA8E1B8816334D32A3FB1CE7D4D5E4C332AF7B003D091741A3D5C965292255DFF8ED2BBF1F9116BE50C17B8E548748AD4B2E957BBD1953482A2E1718CEC66CD2C81F572D552B7187885E6B8943D6431413C59EBB7E036048490BE5289E95B20A89E8B159F61A9A9886E147568F4C9021F362F02688A1C8C3BB0D24086880E55B6EDB43F3745D2C166DC1CB743C76FE6BE523A893CC764D16435C37851252A81E2FFBA0F18971A3DEE37D4877CB928E36E5235037A6B2057897D518A5F0E348E3AB6D5B52DFC60757F3B41A4FEC7828F1DEEAF4587CCC8EADF647F4D203B2FAA05A649B582340CB4CACE57A30711BE752FACF0227D0A80C4128442DDC544BE805B9CFE8FE9B1237C80F96787CD9281CCF270C1AFC0670D"
    KDF_K_Hc = "C6677D7111EAFA8A2570633CA5DD40AEF40C3789D94E4B85241AC810F6812B77"+"2B5C811B5A5D62B1FC79FCAFB1623E81AE164E3D71F75278DCC17A448F106A23"

    Gd_output = xof_rho + prf_sigma
    xof_A01_output = "FB7C700E5E8C851A6AB8A0425D554B9A63D57453F5F27CC0A41EC7951CA27B17AD2C7FD22DB7BDB9C39FD46F92B5415C983376558CAF594EB552CE9E688D0177D12BDA9B0354A6955FC4334266F653126B0E37D91A01E4365D56ED2BBCF494EC640BB5A5AAC3EE4CEA0803619F03CC8CA1E9EF47FAA2590CE2759E5032E51A1A7B29D67A4C9AE25C5910EACBDF6E45C2EA7F577728F65345CEBBB95DE2BB32C55DF4E480FBA014A1"
    prf_s0_output = "8A152D073B12162F4765DFF4CB658BE363173CE3969CF5E2F4E563CC3E55C6D7B2C2E30A904F3BA45838D896F795D98EDE4AA682AFD24618563CE292C53FB6B51A88192194BC0107E6921AC263043DF6089F5E08FBD5CC3F9D3913B4B054EEE5780512E6A86CDAEE4ACCD5369222ADE886D7BF5ABBEAF2D2437231B248857B9BA5CD26894A1B78343076561AA4DC1FF2DEC773CFD0737F248FD82E54FD90EBC2E3FBE56486E56288BE5F15BE51A5134D8CBFE4B33BACA2B41D9A2BF795F95E05"
    Hm_output = "0A55A4433DBAAC3B616D6C4338FCAEC4A9685E8AA37D6A5BD74D619495CD3FED"
    Hpk_ouput = "7FFAD1BC8AF73B7E874956B81C2A2EF0BFABE8DC93D77B2FBC9E0C64EFA01E84"
    Hc_output = "2B5C811B5A5D62B1FC79FCAFB1623E81AE164E3D71F75278DCC17A448F106A23"
    KDF_output = "0A6925676F24B22C286F4C81A4224CEC506C9B257D480E02E3B49F44CAA3237F"

    G_input = Hexstr2ByteArray(G_d)
    G_output = Hexstr2ByteArray(Gd_output)
    out = hash_g(G_input, len(G_input))
    verify(G_output, out)

    H_input = Hexstr2ByteArray(H_m)
    H_output = Hexstr2ByteArray(Hm_output)
    out = hash_h(H_input,len(H_input))
    verify(out, H_output)

    H_input = Hexstr2ByteArray(H_pk)
    H_output = Hexstr2ByteArray(Hpk_ouput)
    out = hash_h(H_input,len(H_input))
    verify(out, H_output)

    H_input = Hexstr2ByteArray(H_c)
    H_output = Hexstr2ByteArray(Hc_output)
    out = hash_h(H_input,len(H_input))
    verify(out, H_output)

    xof_input = Hexstr2ByteArray(xof_rho)
    xof_output = Hexstr2ByteArray(xof_A01_output)
    state = [0] * 25
    xof_absorb(state, xof_input, 0, 1)
    out = xof_squeezeblocks(state, 1)
    verify(out, xof_output)

    prf_input = Hexstr2ByteArray(prf_sigma)
    prf_output = Hexstr2ByteArray(prf_s0_output)
    out = prf(prf_input, 0, 192)
    verify(out, prf_output)

    state_inc = [0] * 26
    shake_inc_input1 = Hexstr2ByteArray(xof_rho)
    shake_inc_input2 = [0,1]
    shake_inc_output = Hexstr2ByteArray(xof_A01_output)
    shake128_inc_absorb(state_inc, shake_inc_input1, len(shake_inc_input1))
    shake128_inc_absorb(state_inc, shake_inc_input2, len(shake_inc_input2))
    shake128_inc_finalize(state_inc)
    out1 = shake128_inc_squeeze(state_inc, 80)
    out2 = shake128_inc_squeeze(state_inc, 88)
    for item in out2:
        out1.append(item)
    verify(shake_inc_output, out1)

