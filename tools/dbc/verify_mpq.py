import struct, zlib, sys
MPQ_FILE_COMPRESS=0x00000200
def build_table(n=0x500):
    t=[0]*n; seed=0x00100001
    for i in range(0x100):
        idx=i
        for _ in range(5):
            seed=(seed*125+3)%0x2AAAAB; t1=(seed&0xFFFF)<<0x10
            seed=(seed*125+3)%0x2AAAAB; t2=seed&0xFFFF
            t[idx]=(t1|t2)&0xFFFFFFFF; idx+=0x100
    return t
T=build_table()
def hstr(name,kind):
    if kind==2: s=name.upper().replace("/","\\")
    elif kind==3: s=name.lower().replace("/","\\")
    else: s=name.replace("/","\\")
    s1,s2=0x7FED7FED,0xEEEEEEEE
    for ch in s.encode("ascii"):
        s1=(T[0x100+ch]^((s1+s2)&0xFFFFFFFF))&0xFFFFFFFF
        s2=(ch+s1+s2+((s2<<5)&0xFFFFFFFF)+3)&0xFFFFFFFF
    return s1 if kind in (0,1) else s2
def dec(data,key):
    key&=0xFFFFFFFF; seed=0xEEEEEEEE; out=bytearray()
    for i in range(0,len(data),4):
        seed=(seed+T[0x400+(key&0xFF)])&0xFFFFFFFF
        ch=struct.unpack_from("<I",data,i)[0]; sh=seed&0x1F
        if sh: ch=((ch>>sh)|(ch<<(32-sh)))&0xFFFFFFFF
        ch=(ch-(key+seed))&0xFFFFFFFF
        key=((((~key)&0xFFFFFFFF)<<0x15)+0x11111111|(key>>0x0B))&0xFFFFFFFF
        seed=(ch+seed+((seed<<5)&0xFFFFFFFF)+3)&0xFFFFFFFF
        out.extend(struct.pack("<I",ch))
    return bytes(out)

p=r"C:\Users\Orel\AppData\Local\Temp\gigatool\patch-x-build\patch-x.mpq"
d=open(p,"rb").read()
sig,hdrsize,arcsize,ver,ssh,ssh2,hts,hto,bto=struct.unpack_from("<4sIIHHIIII",d,0)
print(f"hdr: size={hdrsize} arc={arcsize} ver={ver} shift={ssh} hts={hts} hto={hto} bto={bto} len={len(d)}")
assert hdrsize==32 and arcsize==len(d)
htab=dec(d[hto:hto+hts*16], hstr("(hash table)",3))
btab=dec(d[bto:bto+16*8], hstr("(block table)",3))
n_blocks=3
blocks=[struct.unpack_from("<IIII",btab,i*16) for i in range(n_blocks)]
names=[]
for i in range(hts):
    h1,h2,loc,bi=struct.unpack_from("<IIII",htab,i*16)
    if h1!=0xFFFFFFFF and loc==0xFFFFFFFF: names.append(bi)
print("blocks:",blocks)
def extract(idx,sector_size):
    start,csize,fsize,flags=blocks[idx]
    raw=d[start:start+csize]
    if flags&MPQ_FILE_COMPRESS:
        ntab=fsize//sector_size+1
        tab=[struct.unpack_from("<I",raw,i*4)[0] for i in range(ntab+1)]
        out=bytearray()
        for k in range(ntab):
            a,b=tab[k],tab[k+1]
            out.extend(zlib.decompress(raw[a:b]))
        return bytes(out)
    return raw
data0=extract(0,4096)
print("file0 size:",len(data0),"from fsize:",blocks[0][2],"match:",len(data0)==blocks[0][2])
data1=extract(1,4096)
print("file1 size:",len(data1),"from fsize:",blocks[1][2],"match:",len(data1)==blocks[1][2])
src=open(r"C:\Users\Orel\AppData\Local\Temp\gigatool\patch-x-build\client_dbc\CharTitles.dbc","rb").read()
print("CharTitles byte-identical:", data0==src)
import hashlib
print("sha256 file0:", hashlib.sha256(data0).hexdigest()[:16], "src:", hashlib.sha256(src).hexdigest()[:16])
print("listfile:", d[blocks[2][0]:blocks[2][0]+blocks[2][1]])
