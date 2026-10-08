sabit AZAMİ_İZ=4096;
sabit AZAMİ_KAT=128;
sabit MAT=30000;
sabit SONSUZ=31000;
sabit YARIM=1;
sabit GEÇERKEN=2;
sabit ROK=3;

yapı Konum {
    tahta:u8[64]; bit_tahtası:u64[13]; renkler:u64[2]; şah:i64[2];
    sıra:i64; rok:i64; rok_kalesi:i64[4]; geçer:i64; elli:i64; tam:i64;
    anahtar:u64; geçmiş:u64[AZAMİ_İZ]; iz_sayısı:i64; dönüşsüz:i64; yol:u64;

    ağ_etkin:i64; öz:i16[6144];
}
yapı İz {
    kare:u8[4]; taş:u8[4]; yeni:u8[4]; adet:i64;
    rok:i64; geçer:i64; elli:i64; tam:i64; anahtar:u64; yol:u64; dönüşsüz:i64;
    tahta:u8[64]; dolu:u64; şah:u8[2];
}

yapı Hamleler { hamle:i64[512]; değer:i64[512]; alış:i32[512]; adet:i64; tehdit:i64; }

genel oyun:Konum;
genel taş_anahtarı:u64[832];
genel sıra_anahtarı:u64;
genel rok_anahtarı:u64[256];
genel geçer_anahtarı:u64[8];
genel satranç960:i64=0;
genel ağ:adres=0;

genel ağ_eşli:i64=0;
genel ayar_ilanı:i64=0;
işlev ağı_bırak() {
    eğer ağ!=0 { eğer ağ_eşli>0 { dosya_eşlemeyi_bırak(ağ,ağ_eşli); } yoksa { hizalı_bırak(ağ); } }
    ağ=0; ağ_eşli=0;
}

işlev büyük_ayır(n:i64):adres {
    eğer n<1048576 { dön hizalı_ayır(n,64); }
    m:=(n+2097151)/2097152*2097152;
    p:=hizalı_ayır(m,2097152);

    eğer p==0 { dön hizalı_ayır(n,64); }
    büyük_sayfa_öner(p,m);
    dön p;
}
genel ağ_türü:i64=0;
genel çıktı_kilidi:i64=0;
genel çıktı:dosya=0;

genel at_alanı:u64[64]; genel şah_alanı:u64[64]; genel piyon_alanı:u64[128];
genel kale_ışını:u64[64]; genel fil_ışını:u64[64];
genel aradaki_kareler:u64[4096]; genel aynı_hat:u64[4096];

işlev yaz(m:adres) { dosya_yaz(m,metin_uzunluğu(m),çıktı); }
işlev harf_yaz(c:i64) { b:=dizi(8); bayt_yaz(b,0,c); dosya_yaz(b,1,çıktı); }
işlev metin_satırı(m:adres) { yaz(m); harf_yaz(10); }
işlev rakam(n:i64) { b:=dizi(32); sayı_metin(b,n); yaz(b); }
işlev satır_sonu() { harf_yaz(10); dosya_boşalt(çıktı); }
işlev hata(m:adres) { kilit_al(&çıktı_kilidi); yaz("info string hata: "); metin_satırı(m); dosya_boşalt(çıktı); kilit_bırak(&çıktı_kilidi); }
işlev renk(t:i64):i64 { dön t>6; }
işlev tür(t:i64):i64 { dön seç(t>6,t-6,t); }
işlev bit(k:i64):u64 { dön u64(1)<<u64(k); }
işlev hamle_yapısı(a:i64,b:i64,t:i64):i64 { dön a|(b<<6)|(t<<12); }
işlev kaynak(h:i64):i64 { dön h&63; }
işlev hedef(h:i64):i64 { dön (h>>6)&63; }
işlev hamle_türü(h:i64):i64 { dön h>>12; }
işlev dolu(k:Konum):u64 { dön k.renkler[0]|k.renkler[1]; }

işlev anahtarları_kur() {
    geometriyi_kur();
    tohum:u64:=u64(0x544f4e59554b554b);
    yinele(i:=0;i<832;i+=1) { taş_anahtarı[i]=rastgele64(&tohum); }
    sıra_anahtarı=rastgele64(&tohum);
    yinele(i:=0;i<256;i+=1) { rok_anahtarı[i]=rastgele64(&tohum); }
    yinele(i:=0;i<8;i+=1) { geçer_anahtarı[i]=rastgele64(&tohum); }
}
işlev geometriyi_kur() {
    saldırı_çizgilerini_kur(); sihir_kur();
    yinele(a:=0;a<64;a+=1) {
        at_alanı[a]=satranç_at(a); şah_alanı[a]=satranç_şah(a);
        piyon_alanı[a]=satranç_piyon(a,0); piyon_alanı[64+a]=satranç_piyon(a,1);
        kale_ışını[a]=kale_saldırısı(a,u64(0)); fil_ışını[a]=fil_saldırısı(a,u64(0));
        yinele(b:=0;b<64;b+=1) {
            dx:=b%8-a%8; dy:=b/8-a/8; i:=a*64+b;
            aradaki_kareler[i]=u64(0); aynı_hat[i]=u64(0);
            eğer a==b || !(dx==0 || dy==0 || dx==dy || dx == -dy) { sürdür; }
            sx:=seç(dx>0,1,seç(dx<0,-1,0)); sy:=seç(dy>0,1,seç(dy<0,-1,0));
            x:=a%8+sx; y:=a/8+sy;
            iken x!=b%8 || y!=b/8 { aradaki_kareler[i]|=bit(y*8+x); x+=sx; y+=sy; }
            x=a%8; y=a/8;
            iken x-sx>=0 && x-sx<8 && y-sy>=0 && y-sy<8 { x-=sx; y-=sy; }
            iken x>=0 && x<8 && y>=0 && y<8 { aynı_hat[i]|=bit(y*8+x); x+=sx; y+=sy; }
        }
    }
}

yapı SaldırıÇizgisi { çift:u64; ters_çift:u64; dikey:u64; çapraz:u64; ters:u64; }
genel saldırı_çizgisi:SaldırıÇizgisi[64];
genel sıra_saldırısı:u8[2048];
işlev saldırı_çizgilerini_kur() {
    yinele(a:=0;a<64;a+=1) {
        g:=saldırı_çizgisi[a]; b:=bit(a); g.çift=b<<u64(1); g.ters_çift=bayt_ters(b)<<u64(1);
        g.dikey=u64(0); g.çapraz=u64(0); g.ters=u64(0);
        yinele(c:=0;c<64;c+=1) {
            eğer c%8==a%8 { g.dikey|=bit(c); }
            eğer c/8-c%8==a/8-a%8 { g.çapraz|=bit(c); }
            eğer c/8+c%8==a/8+a%8 { g.ters|=bit(c); }
        }
    }
    yinele(f:=0;f<8;f+=1) {
        yinele(o:=0;o<256;o+=1) {
            alan:=0;
            yinele(x:=f-1;x>=0;x-=1) { alan|=1<<x; eğer (o&(1<<x))!=0 { kır; } }
            yinele(x:=f+1;x<8;x+=1) { alan|=1<<x; eğer (o&(1<<x))!=0 { kır; } }
            sıra_saldırısı[f*256+o]=u8(alan);
        }
    }
}
işlev çizgi_saldırısı(d:u64,m:u64,b:u64,t:u64):u64 {
    o:=d&m; dön ((o-b)^bayt_ters(bayt_ters(o)-t))&m;
}
işlev kale_çizgi(a:i64,d:u64):u64 {
    g:=saldırı_çizgisi[a]; m:=g.dikey; b:=g.çift; t:=g.ters_çift; y:=a&56;
    sıra:=u64(sıra_saldırısı[(a&7)*256+i64((d>>u64(y))&u64(255))])<<u64(y);
    dön sıra|çizgi_saldırısı(d,m,b,t);
}
işlev fil_çizgi(a:i64,d:u64):u64 {
    g:=saldırı_çizgisi[a]; m:=g.çapraz; n:=g.ters; b:=g.çift; t:=g.ters_çift;
    dön çizgi_saldırısı(d,m,b,t)|çizgi_saldırısı(d,n,b,t);
}

yapı Sihir { maske:u64; çarpan:u64; tablo:adres; kaydır:u64; }
genel sihir:Sihir[128]; genel sihir_saldırı:u64[107648];
tablo kale_çarpan:u64[64]={0x09800110400080a0,0xc940001008402000,0x0200220080100841,0x4100100004210009,0x0280020400080080,0x0300120400090008,0x0480020000800100,0x8180104420800100,0x2a00802040008000,0x011300400100a180,0x0240801000200080,0x000200200a001040,0x8000808008000400,0x849e001005720028,0x2005002401000200,0x0001000041000082,0x3040888000304001,0x0400808040002000,0x40c3888020001000,0x0020808008001002,0x8012020010040820,0x0200808002000400,0x0008040010028841,0x502802000410a041,0x0000410100208000,0x0050850100204000,0x8042004200182080,0x8000100080800800,0x0a04008080080006,0x4020020080800400,0x1205620400083001,0x0004024200049403,0x1400804002800023,0x0400401002402002,0x04a2820046002012,0x2400204202000810,0xa080100501000800,0x0002000400808002,0x0b02820824007001,0x0048908c02002041,0x0480004020014009,0x01a0008040008020,0x8200200010008080,0x1000100101090020,0x5000080100910004,0x2002000204008080,0x9215020148140010,0x0880240040820001,0x1801008040220200,0x0001004626058200,0x2029200040150100,0x0408204810030300,0x0020080004008080,0x0044001008200401,0x0806c11002080400,0x4001000271820500,0x0809028000205441,0x8047020082102442,0x1000120040800822,0x0025441000210009,0x408a000820100402,0x0242008801441002,0x0900080241100084,0x0002008100204402};
tablo fil_çarpan:u64[64]={0x7004480200421200,0x2402300102208060,0x0048083100200040,0x041c10d206090060,0x040424200040a091,0x0002080444004000,0x480a011002110014,0x208810880108202a,0x9430420419140300,0x2201220444440141,0x0000105102003004,0x0010044408840000,0x0500445040081204,0x0000220802083008,0x8009028804026204,0x0800008221100204,0x2010008404304400,0x80c8206022040040,0x0002000104040280,0x0208020082004000,0x4004200202010003,0x008a002108112401,0x0080400212300410,0x0000420200621808,0x2168040822208200,0x0204200031810300,0x080c101001044080,0x086c040000410200,0x0021010001904004,0x1002810002806001,0x5100840306013400,0x650081000a111080,0x104410080004202c,0x0001041015823048,0x1001840108100840,0x0000400808408200,0x8101020400220102,0x4048120088041002,0x0808022080104800,0x0288020032004104,0x0004522050000404,0x0662081c020c0408,0x0000c86190001800,0x0040002018001100,0x8000210202000420,0xc0300510010000a4,0x0020420401000040,0x0048010050800200,0x24a2020144422004,0x1000808088204001,0x0002104402210902,0x0210001020880410,0x2801008410440002,0x0001200902082444,0x20400302040100c2,0x0005240c004208c0,0x1004208210a0202a,0x0040008084012008,0x0090838452009000,0x018228114c20a800,0x1021086a44208220,0x0082424a10102081,0x1800102441184600,0x04400244240c2040};
işlev kale_saldırısı(a:i64,d:u64):u64 {
    m:=sihir[a]; dön u64_oku(m.tablo,i64(((d&m.maske)*m.çarpan)>>m.kaydır));
}
işlev fil_saldırısı(a:i64,d:u64):u64 {
    m:=sihir[64+a]; dön u64_oku(m.tablo,i64(((d&m.maske)*m.çarpan)>>m.kaydır));
}
işlev sihir_kur() {
    baş:=0;
    yinele(k:=0;k<2;k+=1) { yinele(a:=0;a<64;a+=1) {
        m:=sihir[k*64+a]; mask:=u64(0);

        yinele(b:=0;b<64;b+=1) {
            dx:=b%8-a%8; dy:=b/8-a/8;
            uygun:=seç(k==0,(dx==0)!=(dy==0),(dx==dy || dx == -dy) && dx!=0);
            sx:=seç(dx>0,1,seç(dx<0,-1,0)); sy:=seç(dy>0,1,seç(dy<0,-1,0));
            x:=b%8+sx; y:=b/8+sy;
            eğer uygun && x>=0 && x<8 && y>=0 && y<8 { mask|=bit(b); }
        }
        m.maske=mask; m.çarpan=seç(k==0,kale_çarpan[a],fil_çarpan[a]);
        m.kaydır=u64(64-bit_say(i64(mask))); m.tablo=adres_ekle(adres(sihir_saldırı),baş*8);
        baş+=1<<bit_say(i64(mask)); b:=u64(0);
        iken 1 {
            v:=seç(k==0,kale_çizgi(a,b),fil_çizgi(a,b));
            i:=i64((b*m.çarpan)>>m.kaydır);
            u64_yaz(m.tablo,i,v); b=(b-mask)&mask; eğer b==u64(0) { kır; }
        }
    } }
}
işlev saldırı(t:i64,s:i64,d:u64,r:i64):u64 {
    eğer t==1 { dön piyon_alanı[r*64+s]; }
    eğer t==2 { dön at_alanı[s]; }
    eğer t==3 { dön fil_saldırısı(s,d); }
    eğer t==4 { dön kale_saldırısı(s,d); }
    eğer t==5 { dön fil_saldırısı(s,d)|kale_saldırısı(s,d); }
    dön şah_alanı[s];
}
işlev saldıranlar(k:Konum,s:i64,r:i64,d:u64):u64 {
    a:=r*6;
    dön (piyon_alanı[(1-r)*64+s]&k.bit_tahtası[a+1]) |
        (at_alanı[s]&k.bit_tahtası[a+2]) |
        (fil_saldırısı(s,d)&(k.bit_tahtası[a+3]|k.bit_tahtası[a+5])) |
        (kale_saldırısı(s,d)&(k.bit_tahtası[a+4]|k.bit_tahtası[a+5])) |
        (şah_alanı[s]&k.bit_tahtası[a+6]);
}
işlev saldırıda(k:Konum,s:i64,r:i64,d:u64):i64 {
    a:=r*6;
    dön ((piyon_alanı[(1-r)*64+s]&k.bit_tahtası[a+1])!=u64(0)) ||
        ((at_alanı[s]&k.bit_tahtası[a+2])!=u64(0)) ||
        ((fil_saldırısı(s,d)&(k.bit_tahtası[a+3]|k.bit_tahtası[a+5]))!=u64(0)) ||
        ((kale_saldırısı(s,d)&(k.bit_tahtası[a+4]|k.bit_tahtası[a+5]))!=u64(0)) ||
        ((şah_alanı[s]&k.bit_tahtası[a+6])!=u64(0));
}
işlev şah_tehditte(k:Konum):i64 { dön saldırıda(k,k.şah[k.sıra],1-k.sıra,dolu(k)); }

işlev taş_koy(k:Konum,s:i64,t:i64) {
    eski:=i64(k.tahta[s]); b:=bit(s);
    eğer eski!=0 {
        k.bit_tahtası[eski]^=b; k.renkler[renk(eski)]^=b;
        k.anahtar^=taş_anahtarı[eski*64+s];
        eğer tür(eski)==6 { k.şah[renk(eski)]=-1; }
    }
    k.tahta[s]=u8(t);
    eğer t!=0 {
        k.bit_tahtası[t]|=b; k.renkler[renk(t)]|=b;
        k.anahtar^=taş_anahtarı[t*64+s];
        eğer tür(t)==6 { k.şah[renk(t)]=s; }
    }
}
işlev iz_kare(k:Konum,g:İz,s:i64) {
    yinele(i:=0;i<g.adet;i+=1) { eğer i64(g.kare[i])==s { dön 0; } }
    g.kare[g.adet]=u8(s); g.taş[g.adet]=k.tahta[s]; g.adet+=1;
}
işlev hak_anahtarı(k:Konum):u64 {
    h:u64:=0;
    yinele(i:=0;i<4;i+=1) { eğer (k.rok&(1<<i))!=0 { h^=rok_anahtarı[i*64+k.rok_kalesi[i]]; } }
    dön h;
}

işlev geçer_yasal(k:Konum):i64 {
    eğer k.geçer<0 { dön 0; }
    r:=k.sıra; alınan:=k.geçer+seç(r==0,-8,8);
    aday:=satranç_piyon(k.geçer,1-r)&k.bit_tahtası[r*6+1];
    iken aday!=u64(0) {
        a:=ilk_bit(i64(aday)); aday&=aday-u64(1);

        p:=(1-r)*6+1; k.bit_tahtası[p]^=bit(alınan);
        d:=(dolu(k)&~(bit(a)|bit(alınan)))|bit(k.geçer);
        yasak:=saldırıda(k,k.şah[r],1-r,d);
        k.bit_tahtası[p]^=bit(alınan);
        eğer !yasak { dön 1; }
    }
    dön 0;
}
işlev konum_anahtarı(k:Konum):u64 {
    h:=hak_anahtarı(k);
    eğer k.sıra!=0 { h^=sıra_anahtarı; }
    yinele(s:=0;s<64;s+=1) { eğer k.tahta[s]!=u8(0) { h^=taş_anahtarı[i64(k.tahta[s])*64+s]; } }
    eğer geçer_yasal(k) { h^=geçer_anahtarı[k.geçer%8]; }
    dön h;
}
işlev ilerle(k:Konum,h:i64,g:İz) {
    g.adet=0; g.rok=k.rok; g.geçer=k.geçer; g.elli=k.elli; g.tam=k.tam;
    g.anahtar=k.anahtar; g.yol=k.yol; g.dönüşsüz=k.dönüşsüz;
    a:=kaynak(h); b:=hedef(h); ht:=hamle_türü(h); t:=i64(k.tahta[a]); r:=k.sıra;
    k.anahtar^=hak_anahtarı(k);
    eğer geçer_yasal(k) { k.anahtar^=geçer_anahtarı[k.geçer%8]; }
    k.geçer=-1; k.elli+=1;
    eğer tür(t)==1 || (ht!=ROK && k.tahta[b]!=u8(0)) { k.elli=0; }
    iz_kare(k,g,a); iz_kare(k,g,b);
    eğer ht==ROK {
        son:=r*56+seç(b>a,6,2); kale_son:=r*56+seç(b>a,5,3);
        iz_kare(k,g,son); iz_kare(k,g,kale_son);
        taş_koy(k,a,0); taş_koy(k,b,0); taş_koy(k,son,t); taş_koy(k,kale_son,r*6+4);
    } yoksa {
        taş_koy(k,a,0);
        eğer ht==GEÇERKEN { s:=b+seç(r==0,-8,8); iz_kare(k,g,s); taş_koy(k,s,0); }
        taş_koy(k,b,seç(ht>=4,r*6+ht-2,t));
        eğer ht==YARIM { k.geçer=(a+b)/2; }
    }
    yinele(i:=0;i<4;i+=1) {
        eğer (tür(t)==6 && i/2==r) || a==k.rok_kalesi[i] || b==k.rok_kalesi[i] { k.rok&=~(1<<i); }
    }
    k.sıra=1-r; k.tam+=r;
    k.anahtar^=sıra_anahtarı^hak_anahtarı(k);
    eğer geçer_yasal(k) { k.anahtar^=geçer_anahtarı[k.geçer%8]; }
    eğer k.elli==0 || k.rok!=g.rok { k.dönüşsüz=k.iz_sayısı; k.yol=u64(0); }
    k.yol=döndür_sola(k.yol,7)^k.anahtar;
    k.geçmiş[k.iz_sayısı]=k.anahtar; k.iz_sayısı+=1;
    yinele(i:=0;i<g.adet;i+=1) { g.yeni[i]=k.tahta[i64(g.kare[i])]; }
    bellek_kopyala(adres(g.tahta),adres(k.tahta),64); g.dolu=dolu(k);
    g.şah[0]=u8(k.şah[0]); g.şah[1]=u8(k.şah[1]);
    eğer k.ağ_etkin { ağ_tazele(k); }
}
işlev geri(k:Konum,g:İz) {

    yinele(i:=g.adet-1;i>=0;i-=1) { taş_koy(k,i64(g.kare[i]),i64(g.taş[i])); }
    k.sıra=1-k.sıra; k.rok=g.rok; k.geçer=g.geçer; k.elli=g.elli; k.tam=g.tam;
    k.anahtar=g.anahtar; k.yol=g.yol; k.dönüşsüz=g.dönüşsüz; k.iz_sayısı-=1;
    eğer k.ağ_etkin { ağ_tazele(k); }
}
işlev ekle_hamle(l:Hamleler,a:i64,b:i64,t:i64) {
    l.hamle[l.adet]=hamle_yapısı(a,b,t); l.adet+=1;
}
işlev piyon_hedefi(l:Hamleler,a:i64,b:i64,t:i64) {
    eğer b<8 || b>=56 { yinele(i:=4;i<=7;i+=1) { ekle_hamle(l,a,b,i); } }
    yoksa { ekle_hamle(l,a,b,t); }
}
işlev rok_yasal(k:Konum,i:i64):i64 {
    eğer (k.rok&(1<<i))==0 { dön 0; }
    r:=k.sıra; a:=k.şah[r]; b:=k.rok_kalesi[i]; c:=r*56+seç(i%2==0,6,2); d:=r*56+seç(i%2==0,5,3);
    doluluk:=dolu(k); arındırılmış:=doluluk&~(bit(a)|bit(b));
    yinele(s:=enaz(a,c);s<=ençok(a,c);s+=1) { eğer (arındırılmış&bit(s))!=u64(0) { dön 0; } }
    yinele(s:=enaz(b,d);s<=ençok(b,d);s+=1) { eğer (arındırılmış&bit(s))!=u64(0) { dön 0; } }
    eğer saldırıda(k,a,1-r,doluluk) { dön 0; }
    adım:=seç(c>a,1,-1); s:=a;
    iken s!=c {
        s+=adım;
        eğer s!=c && saldırıda(k,s,1-r,doluluk&~bit(a)) { dön 0; }
    }
    dön !saldırıda(k,c,1-r,arındırılmış|bit(d));
}

işlev tek_hamle_yasal(k:Konum,h:i64,tehdit:i64):i64 {
    eğer h<=0 || h>=32768 { dön 0; }
    a:=kaynak(h); b:=hedef(h); ht:=hamle_türü(h); r:=k.sıra;
    t:=i64(k.tahta[a])-r*6;
    eğer a==b || t<1 || t>6 { dön 0; }
    eğer ht==ROK {
        eğer t!=6 || k.tahta[b]!=u8(r*6+4) { dön 0; }
        yinele(i:=r*2;i<r*2+2;i+=1) { eğer k.rok_kalesi[i]==b { dön rok_yasal(k,i); } }
        dön 0;
    }
    eğer (k.renkler[r]&bit(b))!=u64(0) || k.tahta[b]==u8((1-r)*6+6) { dön 0; }
    d:=dolu(k); alınan:=b;
    eğer t==1 {
        adım:=seç(r==0,8,-8); son:=b/8==seç(r==0,7,0);
        eğer ht==YARIM {
            eğer a/8!=seç(r==0,1,6) || b!=a+2*adım || k.tahta[b]!=u8(0) || k.tahta[a+adım]!=u8(0) { dön 0; }
        } yoksa eğer ht==GEÇERKEN {
            alınan=b-adım;
            eğer b!=k.geçer || b/8!=seç(r==0,5,2) || k.tahta[b]!=u8(0) ||
                (piyon_alanı[r*64+a]&bit(b))==u64(0) || k.tahta[alınan]!=u8((1-r)*6+1) { dön 0; }
        } yoksa {
            eğer (son && ht<4) || (!son && ht!=0) { dön 0; }
            eğer b==a+adım { eğer k.tahta[b]!=u8(0) { dön 0; } }
            yoksa eğer (piyon_alanı[r*64+a]&bit(b))==u64(0) || k.tahta[b]==u8(0) { dön 0; }
        }
    } yoksa eğer ht!=0 || (saldırı(t,a,d,r)&bit(b))==u64(0) { dön 0; }
    yeni_d:=(d&~(bit(a)|bit(alınan)))|bit(b); şah:=seç(t==6,b,k.şah[r]);

    eğer !tehdit && t!=6 && ht!=GEÇERKEN {
        eğer ((kale_ışını[şah]|fil_ışını[şah])&bit(a))==u64(0) || (aynı_hat[şah*64+a]&bit(b))!=u64(0) { dön 1; }
        düşman:=(1-r)*6;
        eğer (kale_ışını[şah]&bit(a))!=u64(0) { dön (kale_saldırısı(şah,yeni_d)&(k.bit_tahtası[düşman+4]|k.bit_tahtası[düşman+5])&~bit(alınan))==u64(0); }
        dön (fil_saldırısı(şah,yeni_d)&(k.bit_tahtası[düşman+3]|k.bit_tahtası[düşman+5])&~bit(alınan))==u64(0);
    }
    dön (saldıranlar(k,şah,1-r,yeni_d)&~bit(alınan))==u64(0);
}

işlev piyon_hedefi_n(l:Hamleler,n:i64,a:i64,b:i64,t:i64):i64 {
    eğer b<8 || b>=56 { yinele(i:=4;i<=7;i+=1) { l.hamle[n]=hamle_yapısı(a,b,i); n+=1; } }
    yoksa { l.hamle[n]=hamle_yapısı(a,b,t); n+=1; }
    dön n;
}
işlev taslak_hamleler(k:Konum,l:Hamleler) {
    n:=0; r:=k.sıra; d:=dolu(k); dost:=k.renkler[r]; düşman:=k.renkler[1-r]&~k.bit_tahtası[(1-r)*6+6];
    taşlar:=dost;
    iken taşlar!=u64(0) {
        a:=ilk_bit(i64(taşlar)); taşlar&=taşlar-u64(1); t:=i64(k.tahta[a])-r*6;
        eğer t==1 {
            adım:=seç(r==0,8,-8); b:=a+adım;
            eğer b>=0 && b<64 && k.tahta[b]==u8(0) {
                n=piyon_hedefi_n(l,n,a,b,0);
                eğer a/8==seç(r==0,1,6) && k.tahta[a+2*adım]==u8(0) { l.hamle[n]=hamle_yapısı(a,a+2*adım,YARIM); n+=1; }
            }
            av:=piyon_alanı[r*64+a]&düşman;
            iken av!=u64(0) { b=ilk_bit(i64(av)); av&=av-u64(1); n=piyon_hedefi_n(l,n,a,b,0); }
            eğer k.geçer>=0 && (piyon_alanı[r*64+a]&bit(k.geçer))!=u64(0) { l.hamle[n]=hamle_yapısı(a,k.geçer,GEÇERKEN); n+=1; }
        } yoksa {
            alan:=saldırı(t,a,d,r)&~dost&~k.bit_tahtası[(1-r)*6+6];
            iken alan!=u64(0) { b:=ilk_bit(i64(alan)); alan&=alan-u64(1); l.hamle[n]=hamle_yapısı(a,b,0); n+=1; }
        }
    }
    yinele(i:=r*2;i<r*2+2;i+=1) { eğer rok_yasal(k,i) { l.hamle[n]=hamle_yapısı(k.şah[r],k.rok_kalesi[i],ROK); n+=1; } }
    l.adet=n;
}

işlev taslak_alışlar(k:Konum,l:Hamleler) {
    n:=0; r:=k.sıra; d:=dolu(k); dost:=k.renkler[r]; düşman:=k.renkler[1-r]&~k.bit_tahtası[(1-r)*6+6];
    taşlar:=dost;
    iken taşlar!=u64(0) {
        a:=ilk_bit(i64(taşlar)); taşlar&=taşlar-u64(1); t:=i64(k.tahta[a])-r*6;
        eğer t==1 {
            adım:=seç(r==0,8,-8); b:=a+adım;
            eğer b>=0 && b<64 && (b<8 || b>=56) && k.tahta[b]==u8(0) { n=piyon_hedefi_n(l,n,a,b,0); }
            av:=piyon_alanı[r*64+a]&düşman;
            iken av!=u64(0) { b=ilk_bit(i64(av)); av&=av-u64(1); n=piyon_hedefi_n(l,n,a,b,0); }
            eğer k.geçer>=0 && (piyon_alanı[r*64+a]&bit(k.geçer))!=u64(0) { l.hamle[n]=hamle_yapısı(a,k.geçer,GEÇERKEN); n+=1; }
        } yoksa {
            alan:=saldırı(t,a,d,r)&düşman;
            iken alan!=u64(0) { b:=ilk_bit(i64(alan)); alan&=alan-u64(1); l.hamle[n]=hamle_yapısı(a,b,0); n+=1; }
        }
    }
    l.adet=n;
}
işlev yasal_hamleler(k:Konum,l:Hamleler) { taslak_hamleler(k,l); yasallaştır(k,l); }
işlev yasal_alışlar(k:Konum,l:Hamleler) { taslak_alışlar(k,l); yasallaştır(k,l); }
işlev yasallaştır(k:Konum,l:Hamleler) {
    n:=0; r:=k.sıra; şah:=k.şah[r]; d:=dolu(k);
    tehdit:=saldıranlar(k,şah,1-r,d); çift:=(tehdit&(tehdit-u64(1)))!=u64(0);
    l.tehdit=tehdit!=u64(0);
    kaçış:u64:=~u64(0);
    eğer tehdit!=u64(0) { s:=ilk_bit(i64(tehdit)); kaçış=tehdit|aradaki_kareler[şah*64+s]; }
    düşman:=(1-r)*6; çivililer:u64:=0;
    ışıncılar:=(kale_ışını[şah]&(k.bit_tahtası[düşman+4]|k.bit_tahtası[düşman+5])) |
        (fil_ışını[şah]&(k.bit_tahtası[düşman+3]|k.bit_tahtası[düşman+5]));
    iken ışıncılar!=u64(0) {
        s:=ilk_bit(i64(ışıncılar)); ışıncılar&=ışıncılar-u64(1);
        arada:=aradaki_kareler[şah*64+s]&d;
        eğer (arada&(arada-u64(1)))==u64(0) { çivililer|=arada&k.renkler[r]; }
    }

    eğer tehdit==u64(0) && çivililer==u64(0) && k.geçer<0 {
        yinele(i:=0;i<l.adet;i+=1) {
            h:=i64(l.hamle[i]); uygun:=1;
            eğer kaynak(h)==şah && hamle_türü(h)!=ROK {
                b:=hedef(h); yeni_d:=(d&~bit(şah))|bit(b);
                uygun=(saldıranlar(k,b,1-r,yeni_d)&~bit(b))==u64(0);
            }
            eğer uygun { l.hamle[n]=h; n+=1; }
        }
        l.adet=n; dön 0;
    }
    yinele(i:=0;i<l.adet;i+=1) {
        h:=i64(l.hamle[i]); a:=kaynak(h); b:=hedef(h); ht:=hamle_türü(h); uygun:=0;
        eğer ht==ROK { uygun=1; }
        yoksa eğer a==şah {
            yeni_d:=(d&~bit(a))|bit(b);
            uygun=(saldıranlar(k,b,1-r,yeni_d)&~bit(b))==u64(0);
        } yoksa eğer ht==GEÇERKEN {

            alınan:=b+seç(r==0,-8,8); yeni_d:=(d&~(bit(a)|bit(alınan)))|bit(b);
            uygun=(saldıranlar(k,şah,1-r,yeni_d)&~bit(alınan))==u64(0);
        } yoksa {
            uygun=!çift && (kaçış&bit(b))!=u64(0) &&
                ((çivililer&bit(a))==u64(0) || (aynı_hat[şah*64+a]&bit(b))!=u64(0));
        }
        eğer uygun { l.hamle[n]=h; n+=1; }
    }
    l.adet=n;
}

işlev şahsız_yasal_var(k:Konum):i64 {
    r:=k.sıra; şah:=k.şah[r]; d:=dolu(k); dost:=k.renkler[r]; düşman:=(1-r)*6;

    serbest_piyon:=k.bit_tahtası[r*6+1]&~(kale_ışını[şah]|fil_ışını[şah]);
    sürüş:=seç(r==0,serbest_piyon<<u64(8),serbest_piyon>>u64(8));
    eğer (sürüş&~d)!=u64(0) { dön 1; }
    çivililer:u64:=0;
    ışıncılar:=(kale_ışını[şah]&(k.bit_tahtası[düşman+4]|k.bit_tahtası[düşman+5])) |
        (fil_ışını[şah]&(k.bit_tahtası[düşman+3]|k.bit_tahtası[düşman+5]));
    iken ışıncılar!=u64(0) {
        s:=ilk_bit(i64(ışıncılar)); ışıncılar&=ışıncılar-u64(1); arada:=aradaki_kareler[şah*64+s]&d;
        eğer (arada&(arada-u64(1)))==u64(0) { çivililer|=arada&dost; }
    }
    taşlar:=dost; avlar:=k.renkler[1-r]&~k.bit_tahtası[düşman+6];
    iken taşlar!=u64(0) {
        a:=ilk_bit(i64(taşlar)); taşlar&=taşlar-u64(1); t:=i64(k.tahta[a])-r*6;
        hat:=seç((çivililer&bit(a))!=u64(0),aynı_hat[şah*64+a],~u64(0));
        eğer t==1 {
            adım:=seç(r==0,8,-8); b:=a+adım;
            eğer b>=0 && b<64 && k.tahta[b]==u8(0) {
                eğer (hat&bit(b))!=u64(0) { dön 1; }
                eğer a/8==seç(r==0,1,6) && k.tahta[a+2*adım]==u8(0) && (hat&bit(a+2*adım))!=u64(0) { dön 1; }
            }
            eğer (piyon_alanı[r*64+a]&avlar&hat)!=u64(0) { dön 1; }
        } yoksa {
            alan:=saldırı(t,a,d,r)&~dost&~k.bit_tahtası[düşman+6]&hat;
            eğer t!=6 { eğer alan!=u64(0) { dön 1; } }
            yoksa {
                iken alan!=u64(0) {
                    b:=ilk_bit(i64(alan)); alan&=alan-u64(1); yeni_d:=(d&~bit(a))|bit(b);
                    eğer (saldıranlar(k,b,1-r,yeni_d)&~bit(b))==u64(0) { dön 1; }
                }
            }
        }
    }
    eğer geçer_yasal(k) { dön 1; }
    yinele(i:=r*2;i<r*2+2;i+=1) { eğer rok_yasal(k,i) { dön 1; } }
    dön 0;
}

işlev perft(k:Konum,derinlik:i64):i64 {
    eğer derinlik==0 { dön 1; }
    l:=yerel(Hamleler); yasal_hamleler(k,l);
    eğer derinlik==1 { dön l.adet; }
    toplam:=0; g:=yerel(İz);
    yinele(i:=0;i<l.adet;i+=1) { ilerle(k,i64(l.hamle[i]),g); toplam+=perft(k,derinlik-1); geri(k,g); }
    dön toplam;
}

işlev kare_oku(m:adres):i64 {
    a:=bayt_oku(m,0); b:=bayt_oku(m,1);
    eğer a<97 || a>104 || b<49 || b>56 { dön -1; }
    dön a-97+(b-49)*8;
}
işlev hamle_metni(h:i64,k:Konum,b:adres) {
    a:=kaynak(h); s:=hedef(h); t:=hamle_türü(h);
    eğer t==ROK && !satranç960 { s=(a/8)*8+seç(s>a,6,2); }
    bayt_yaz(b,0,97+a%8); bayt_yaz(b,1,49+a/8); bayt_yaz(b,2,97+s%8); bayt_yaz(b,3,49+s/8);
    n:=4;
    eğer t>=4 { bayt_yaz(b,4,bayt_oku("nbrq",t-4)); n=5; }
    bayt_yaz(b,n,0);
}
işlev hamle_oku(k:Konum,m:adres):i64 {
    l:=yerel(Hamleler); yasal_hamleler(k,l); b:=dizi(8);
    yinele(i:=0;i<l.adet;i+=1) { hamle_metni(i64(l.hamle[i]),k,b); eğer metin_eşit(b,m) { dön i64(l.hamle[i]); } }
    dön 0;
}
işlev tamsayı(m:adres):i64 {
    n:=metin_uzunluğu(m); eğer n<1 || n>9 { dön -1; } x:=0;
    yinele(i:=0;i<n;i+=1) { c:=bayt_oku(m,i); eğer c<48 || c>57 { dön -1; } x=x*10+c-48; }
    dön x;
}
işlev sözcüklere_böl(m:adres,s:adres,kapasite:i64):i64 {
    n:=0; i:=0;
    iken bayt_oku(m,i)!=0 {
        iken bayt_oku(m,i)==32 || bayt_oku(m,i)==9 { bayt_yaz(m,i,0); i+=1; }
        eğer bayt_oku(m,i)==0 { kır; }
        eğer n==kapasite { dön -1; }
        adres_yaz(s,n,adres_ekle(m,i)); n+=1;
        iken bayt_oku(m,i)!=0 && bayt_oku(m,i)!=32 && bayt_oku(m,i)!=9 { i+=1; }
    }
    dön n;
}
işlev fen_oku(k:Konum,s:adres):i64 {
    bellek_sıfırla(adres(k),boyut(Konum)); k.geçer=-1; k.şah[0]=-1; k.şah[1]=-1;
    yinele(i:=0;i<4;i+=1) { k.rok_kalesi[i]=-1; }
    m:=adres_oku(s,0); sıra:=7; sütun:=0; şahlar:=yerel_dizi(i64,2); şahlar[0]=0; şahlar[1]=0;
    yinele(i:=0;bayt_oku(m,i)!=0;i+=1) {
        c:=bayt_oku(m,i);
        eğer c==47 { eğer sütun!=8 || sıra==0 { dön 0; } sıra-=1; sütun=0; }
        yoksa eğer c>=49 && c<=56 { sütun+=c-48; eğer sütun>8 { dön 0; } }
        yoksa {
            t:=0; yinele(j:=0;j<12;j+=1) { eğer c==bayt_oku("PNBRQKpnbrqk",j) { t=j+1; } }
            eğer t==0 || sütun>=8 || (tür(t)==1 && (sıra==0 || sıra==7)) { dön 0; }
            taş_koy(k,sıra*8+sütun,t); sütun+=1;
            eğer tür(t)==6 { şahlar[renk(t)]+=1; }
        }
    }
    eğer sıra!=0 || sütun!=8 || şahlar[0]!=1 || şahlar[1]!=1 { dön 0; }
    yinele(r:=0;r<2;r+=1) { eğer bit_say(i64(k.renkler[r]))>16 || bit_say(i64(k.bit_tahtası[r*6+1]))>8 { dön 0; } }
    m=adres_oku(s,1); eğer metin_eşit(m,"w") { k.sıra=0; } yoksa eğer metin_eşit(m,"b") { k.sıra=1; } yoksa { dön 0; }
    m=adres_oku(s,2);
    eğer !metin_eşit(m,"-") {
        yinele(i:=0;bayt_oku(m,i)!=0;i+=1) {
            c:=bayt_oku(m,i); r:=seç(c>=97,1,0); kale:=-1; kanat:=-1;
            eğer c==75 || c==107 { kanat=0; kale=r*56+7; }
            yoksa eğer c==81 || c==113 { kanat=1; kale=r*56; }
            yoksa eğer satranç960 && ((c>=65 && c<=72)||(c>=97 && c<=104)) { kale=r*56+c-seç(r==0,65,97); kanat=seç(kale>k.şah[r],0,1); }
            yoksa { dön 0; }
            eğer satranç960 && (c==75 || c==107 || c==81 || c==113) {
                kale=-1;
                yinele(f:=0;f<8;f+=1) {
                    z:=r*56+f;
                    eğer k.tahta[z]==u8(r*6+4) && ((kanat==0 && z>k.şah[r]) || (kanat==1 && z<k.şah[r])) {
                        eğer kale<0 || kanat==0 { kale=z; }
                    }
                }
            }
            eğer kale<0 || k.tahta[kale]!=u8(r*6+4) || k.şah[r]/8!=r*7 || (!satranç960 && k.şah[r]!=r*56+4) { dön 0; }
            j:=r*2+kanat; eğer (k.rok&(1<<j))!=0 { dön 0; } k.rok|=1<<j; k.rok_kalesi[j]=kale;
        }
    }
    m=adres_oku(s,3);
    eğer !metin_eşit(m,"-") {
        eğer metin_uzunluğu(m)!=2 { dön 0; } k.geçer=kare_oku(m);
        eğer k.geçer<0 || k.geçer/8!=seç(k.sıra==0,5,2) || k.tahta[k.geçer]!=u8(0) { dön 0; }
        geride:=k.geçer+seç(k.sıra==0,-8,8); önce:=k.geçer+seç(k.sıra==0,8,-8);
        eğer k.tahta[geride]!=u8((1-k.sıra)*6+1) || k.tahta[önce]!=u8(0) { dön 0; }
    }
    k.elli=tamsayı(adres_oku(s,4)); k.tam=tamsayı(adres_oku(s,5));
    eğer k.elli<0 || k.tam<1 || saldırıda(k,k.şah[1-k.sıra],k.sıra,dolu(k)) { dön 0; }
    k.anahtar=konum_anahtarı(k); k.geçmiş[0]=k.anahtar; k.iz_sayısı=1; k.yol=k.anahtar;
    eğer ağ!=0 { ağ_tazele(k); }
    dön 1;
}
işlev başlangıç(k:Konum) {
    m:=dizi(128); bellek_kopyala(m,"rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",57);
    s:=dizi(48); sözcüklere_böl(m,s,6); fen_oku(k,s);
}

genel deneme_ağı:i64=0;
genel deneme_izni:i64=0;

işlev ağ_parmakizi(p:adres,n:i64):u64 {
    h:u64:=u64(0xcbf29ce484222325);
    yinele(i:=0;i<n;i+=1) { h=(h^u64(bayt_oku(p,i)))*u64(0x100000001b3); }
    dön h;
}

sabit GÖMÜLÜ_AĞ=1;

sabit GÖMÜLÜ_BAYT=49082144;

sabit DURUM_BOYU=12288;
tablo gömülü_ağ:u8[GÖMÜLÜ_AĞ*GÖMÜLÜ_BAYT+64];
işlev ağ_yükle(yol:adres):i64 {
    utf:=dizi(131080); f:=dosya_aç_utf8(yol,"rb",utf,131080); eğer f==0 { hata("ag dosyasi acilamadi"); dön 0; }
    ertele { dosya_kapat(f); }
    başlık:=dizi(64);
    eğer dosya_oku(başlık,64,f)!=64 { hata("ag basligi eksik"); dön 0; }
    eğer bellek_karşılaştır(başlık,"TYKTNNS8",8)==0 { dön s8_dosyadan(f,başlık); }
    hata("ag bicimi taninmiyor (TYKTNNS8 bekleniyor)"); dön 0;
}

işlev gömülüyü_yükle():i64 {
    eğer GÖMÜLÜ_AĞ==0 { dön 0; }
    başlık:=adres(gömülü_ağ);
    eğer bellek_karşılaştır(başlık,"TYKTNNS8",8)==0 { dön s8_bellekten(başlık,1); }
    eğer bayt_oku(başlık,0)==0 { dön 0; }
    hata("gomulu ag bicimi taninmiyor"); dön 0;
}

genel kn_blok_etkin:i64=0;

işlev kn_paketle(dst:adres,db:adres,src:adres,sb:adres,n:i64,m:i64) {
    yinele(o:=0;o<m;o+=1) {
        toplam:=0;
        yinele(i:=0;i<n;i+=1) {
            v:=i64(i8_oku(src,o*n+i)); toplam+=v;
            i8_yaz(dst,((o/16)*(n/4)+i/4)*64+(o%16)*4+i%4,i8(v));
        }
        i32_yaz(db,o,i32(i64(i32_oku(sb,o))+toplam*128));
    }
}

işlev kn_bağlam(şah:i64,p:i64):i64 {
    s:=şah^(p*56); a:=seç(s%8>=4,7,0); s=s^a;
    dön (2*(s/8)+(s%8)/2)*8+a;
}

işlev s8_bağlam(şah:i64,p:i64):i64 {
    eğer s8_PSQ==12288 { dön kn_bağlam(şah,p); }
    s:=şah^(p*56); a:=seç(s%8>=4,7,0); s=s^a;
    dön ((s/8)*4+s%8)*8+a;
}
işlev kn_kimlik(t:i64,s:i64,p:i64,c:i64):i64 {
    dön (c/8)*768+((renk(t)^p)*6+tür(t)-1)*64+(s^(p*56)^(c&7));
}
işlev kn_baş(dst:adres,src:adres,w:adres,b:adres,giriş:i64,çıkış:i64) {
    z:=yerel_dizi(i32,128);
    yinele(j:=0;j<çıkış;j+=1) {

        z[j]=i32(i64(nokta_u8_i8_i32(src,adres_ekle(w,j*giriş),giriş))+i64(i32_oku(b,j)));
    }
    kırp_çift_i32_u8(dst,adres(z),çıkış,6);
}
işlev kn_blok(dst:adres,src:adres,w:adres,b:adres,n:i64,m:i64) {
    z:=yerel_dizi(i32,128); yoğun_blok_u8_i8_i32(adres(z),src,w,b,n,m);
    kırp_çift_i32_u8(dst,adres(z),m,6);
}
işlev ağ_değeri(k:Konum,d:adres):i64 { dön s8_değeri(k,d); }

sabit ARAMA_KN_ÖLÇEĞİ=500;
işlev arama_ağ_değeri(k:Konum,d:adres):i64 {
    eğer ağ_türü==2 && s8_çapa { dön s8_değeri_ölçekli(k,d,ARAMA_KN_ÖLÇEĞİ); }

    dön enaz(24000,ençok(-24000,ağ_değeri(k,d)*ARAMA_KN_ÖLÇEĞİ/400));
}
işlev ağ_güncelle(dst:adres,src:adres,g:İz) {
    s8_güncelle(dst,src,g);
}

genel s8_A:i64=768; genel s8_AB:i64=1536; genel s8_H:i64=384; genel s8_BK:i64=1600; genel s8_PQ:i64=384; genel s8_L1:i64=32; genel s8_TRO:i64=3200;
genel s8_R:i64=0; genel s8_RK:i64=768; genel s8_ph:i64=0; genel s8_psqt_eksi:adres=0; genel s8_relset:i64=0; genel s8_hata:i64=0; genel s8_BAYT:i64=0;
genel s8_REL:i64=0; genel s8_BIAS:i64=0; genel s8_PSQT:i64=0; genel s8_W1:i64=0; genel s8_B1:i64=0;

genel s8_direkt:i64=0; genel s8_asılı:i64=0; genel s8_HB:i64=0; genel s8_gerilim:i64=0; genel s8_asılı2:i64=0; genel s8_HB2:i64=0;
genel s8_klasik:i64=0; genel s8_HB3:i64=0; genel s8_klasik2:i64=0; genel s8_HB4:i64=0; genel s8_rakip_yalnız:i64=0; genel s8_rel_hızlı:i64=0;
genel s8_PSQ:i64=12288; genel s8_S:i64=0; genel s8_AX:i64=768;
genel s8_çapa:i64=0;
genel s8_rel_süz:i64=0;
genel s8_rel_bayt:i64=2;
genel s8_W2:i64=0; genel s8_B2:i64=0; genel s8_WO:i64=0; genel s8_BO:i64=0; genel s8_WE:i64=0; genel s8_BE:i64=0;

genel s8_karma_ptr:u64[4160];
işlev s8_karma_paketle(tab:adres,w8:adres,w16:adres,n:i64) {
    yinele(g:=0;g<n/4;g+=1) {
        p:=adres_ekle(w8,g*128); güvenli:=1;
        yinele(o:=0;o<32;o+=1) { yinele(j:=0;j<4;j+=2) {
            a:=i64(i8_oku(p,o*4+j)); b:=i64(i8_oku(p,o*4+j+1));
            artı:=seç(a>0,a,0)+seç(b>0,b,0);
            eksi:=seç(a<0,a,0)+seç(b<0,b,0);
            eğer artı>128 || eksi < -128 { güvenli=0; }
        } }
        eğer güvenli { adres_yaz(tab,g,p); }
        yoksa {
            q:=adres_ekle(w16,g*256);
            yinele(o:=0;o<32;o+=1) { yinele(j:=0;j<4;j+=1) {
                i16_yaz(q,(j/2*32+o)*2+j%2,i16(i8_oku(p,o*4+j)));
            } }
            adres_yaz(tab,g,adres_ekle(q,1));
        }
    }
}
genel s8_çift_etkin:i64=0; genel s8_w1ç:i16[532480]; genel s8_w2ç:i16[8192];
işlev s8_çift_paketle(dst:adres,src:adres,n:i64,m:i64) {
    yinele(i:=0;i<n;i+=1) { yinele(o:=0;o<m;o+=1) {
        i16_yaz(dst,((i/4*2+i%4/2)*m+o)*2+i%2,i16(i8_oku(src,o*n+i)));
    } }
}
genel s8_w1p:i8[2129920]; genel s8_w2p:i8[131072]; genel s8_b1p:i32[1024]; genel s8_b2p:i32[512];

genel s8_w1s:i8[2129920]; genel s8_seyrek:i64=0;

genel s8_toplu_etkin:i64=0; genel s8_indis_tablo:u16[2048]; genel s8_w1g:i8[2129920]; genel s8_grup_etkin:i64=0;
genel s8_L2:i64=16;
genel tr_taban:i32[768]; genel tr_sıra:u8[49152]; genel tr_çift:i64=0; genel tr_hazır:i64=0;
işlev tr_hedef_mi(sınıf:i64,o:i64,t:i64):i64 {
    c:=sınıf/6; k:=sınıf%6; df:=t%8-o%8; dr:=t/8-o/8;
    eğer t==o { dön 0; }
    eğer k==0 { eğer o<8 || o>=56 { dön 0; } dön mutlak(df)==1 && dr==seç(c==0,1,-1); }
    eğer k==1 { dön (mutlak(df)==1 && mutlak(dr)==2) || (mutlak(df)==2 && mutlak(dr)==1); }
    eğer k==5 { dön mutlak(df)<=1 && mutlak(dr)<=1; }
    çapraz:=mutlak(df)==mutlak(dr); düz:=df==0 || dr==0;
    eğer k==2 { dön çapraz; }
    eğer k==3 { dön düz; }
    dön çapraz || düz;
}
işlev tr_kur() {
    eğer tr_hazır { dön 0; }
    n:=0;
    yinele(sınıf:=0;sınıf<12;sınıf+=1) { yinele(o:=0;o<64;o+=1) {
        tr_taban[sınıf*64+o]=i32(n); say:=0;
        yinele(t:=0;t<64;t+=1) {
            eğer tr_hedef_mi(sınıf,o,t) { tr_sıra[(sınıf*64+o)*64+t]=u8(say); say+=1; } yoksa { tr_sıra[(sınıf*64+o)*64+t]=u8(255); }
        }
        n+=say;
    } }
    tr_çift=n;
    tr_hazır=1;
}

işlev s8_rel_satır(d:adres,f:i64) {
    eğer s8_rel_bayt==1 {
        w:=adres_ekle(ağ,s8_REL+f*s8_RK);
        eğer s8_RK==s8_A || s8_ph>0 { vektör_topla_i8_i16(d,d,w,s8_RK); dön 0; }
        h:=s8_RK/2; e:=adres_ekle(d,s8_A);
        vektör_topla_i8_i16(d,d,w,h); vektör_topla_i8_i16(e,e,adres_ekle(w,h),h); dön 0;
    }
    w:=adres_ekle(ağ,s8_REL+f*s8_RK*2);
    eğer s8_RK==s8_A { vektör_topla_i16(d,d,w,s8_A); dön 0; }
    eğer s8_ph>0 { vektör_topla_i16(d,d,w,s8_RK); dön 0; }
    h:=s8_RK/2; e:=adres_ekle(d,s8_A);
    vektör_topla_i16(d,d,w,h); vektör_topla_i16(e,e,adres_ekle(w,h*2),h);
}
işlev s8_rel_çıkar(d:adres,f:i64) {
    eğer s8_rel_bayt==1 {
        w:=adres_ekle(ağ,s8_REL+f*s8_RK);
        eğer s8_RK==s8_A || s8_ph>0 { vektör_çıkar_i8_i16(d,d,w,s8_RK); dön 0; }
        h:=s8_RK/2; e:=adres_ekle(d,s8_A);
        vektör_çıkar_i8_i16(d,d,w,h); vektör_çıkar_i8_i16(e,e,adres_ekle(w,h),h); dön 0;
    }
    w:=adres_ekle(ağ,s8_REL+f*s8_RK*2);
    eğer s8_RK==s8_A { vektör_çıkar_i16(d,d,w,s8_A); dön 0; }
    eğer s8_ph>0 { vektör_çıkar_i16(d,d,w,s8_RK); dön 0; }
    h:=s8_RK/2; e:=adres_ekle(d,s8_A);
    vektör_çıkar_i16(d,d,w,h); vektör_çıkar_i16(e,e,adres_ekle(w,h*2),h);
}

genel tr_da:i64=1;

işlev tr_piyonlar(tahta:adres,r:i64):u64 {
    p:=seç(r!=0,7,1); m:=u64(0);
    yinele(q:=0;q<64;q+=1) { eğer i64(bayt_oku(tahta,q))==p { m|=bit(q); } }
    dön m;
}
işlev tr_d_saldıran(a0:adres,a1:adres,bayrak:i64,çevler:i64,tahta:adres,s:i64,att:u64,dolu:u64) {
    e0:=(bayrak&1)!=0; e1:=(bayrak&2)!=0; ekle:=(bayrak&4)!=0; ç0:=çevler&255; ç1:=çevler>>8;
    t:=i64(bayt_oku(tahta,s)); k:=tür(t); r:=renk(t);
    eğer (s8_rel_süz&1)!=0 && k==6 { dön 0; }
    s0:=(r*6+k-1)*64+(s^ç0); s1:=((r^1)*6+k-1)*64+(s^ç1);
    h:=att&dolu;

    eğer (s8_rel_süz&2)!=0 && k==1 { h&=~(dolu&tr_piyonlar(tahta,r)); }
    eğer s8_rakip_yalnız { h&=~tr_renk_kareleri(tahta,h,r); }
    eğer !s8_rel_hızlı {
        iken h!=u64(0) {
            q:=ilk_bit(i64(h)); h&=h-u64(1);
            tt:=i64(bayt_oku(tahta,q)); rt:=renk(tt); kt:=tür(tt);
            eğer e0 { id:=(i64(tr_taban[s0])+i64(tr_sıra[s0*64+(q^ç0)]))*12+rt*6+kt-1; eğer ekle { s8_rel_satır(a0,id); } yoksa { s8_rel_çıkar(a0,id); } }
            eğer e1 { id:=(i64(tr_taban[s1])+i64(tr_sıra[s1*64+(q^ç1)]))*12+(rt^1)*6+kt-1; eğer ekle { s8_rel_satır(a1,id); } yoksa { s8_rel_çıkar(a1,id); } }
        }
        dön 0;
    }

    RK:=s8_RK; taban:=adres_ekle(ağ,s8_REL); adım:=RK*s8_rel_bayt; i8:=s8_rel_bayt==1;
    t0:=i64(tr_taban[s0])*12; t1:=i64(tr_taban[s1])*12; r0:=s0*64; r1:=s1*64;
    iken h!=u64(0) {
        q:=ilk_bit(i64(h)); h&=h-u64(1);
        tt:=i64(bayt_oku(tahta,q)); kc:=seç(tt>6,tt-7,tt+5);
        eğer e0 {
            w:=adres_ekle(taban,(t0+i64(tr_sıra[r0+(q^ç0)])*12+tt-1)*adım);
            eğer i8 { eğer ekle { vektör_topla_i8_i16(a0,a0,w,RK); } yoksa { vektör_çıkar_i8_i16(a0,a0,w,RK); } }
            yoksa { eğer ekle { vektör_topla_i16(a0,a0,w,RK); } yoksa { vektör_çıkar_i16(a0,a0,w,RK); } }
        }
        eğer e1 {
            w:=adres_ekle(taban,(t1+i64(tr_sıra[r1+(q^ç1)])*12+kc)*adım);
            eğer i8 { eğer ekle { vektör_topla_i8_i16(a1,a1,w,RK); } yoksa { vektör_çıkar_i8_i16(a1,a1,w,RK); } }
            yoksa { eğer ekle { vektör_topla_i16(a1,a1,w,RK); } yoksa { vektör_çıkar_i16(a1,a1,w,RK); } }
        }
    }
}

işlev tr_renk_kareleri(tahta:adres,h:u64,r:i64):u64 {
    m:=u64(0); x:=h;
    iken x!=u64(0) { q:=ilk_bit(i64(x)); x&=x-u64(1); eğer renk(i64(bayt_oku(tahta,q)))==r { m|=bit(q); } }
    dön m;
}

işlev tr_da_saldırılar(tahta:adres,dolu:u64,A:adres) {
    bellek_sıfırla(A,512); bb:=dolu;
    iken bb!=u64(0) { s:=ilk_bit(i64(bb)); bb&=bb-u64(1); t:=i64(bayt_oku(tahta,s)); u64_yaz(A,s,saldırı(tür(t),s,dolu,renk(t))); }
}

işlev tr_da_bakış(d:adres,tahta:adres,dolu:u64,p:i64,çev:i64,A:adres) {
    bb:=dolu;
    iken bb!=u64(0) {
        s:=ilk_bit(i64(bb)); bb&=bb-u64(1);
        tr_d_saldıran(d,d,seç(p==0,5,6),çev|(çev<<8),tahta,s,u64_oku(A,s),dolu);
    }
}
işlev s8_satır(d:adres,f:i64,işaret:i64) {
    w:=adres_ekle(ağ,f*s8_AB);
    eğer işaret==1 { vektör_topla_i16(d,d,w,s8_A); } yoksa { vektör_çıkar_i16(d,d,w,s8_A); }

    e:=adres_ekle(d,s8_AB);
    eğer işaret==1 { vektör_topla_i16_i32(e,e,adres_ekle(ağ,s8_PSQT+f*16),8); }
    yoksa { vektör_topla_i32(e,e,adres_ekle(s8_psqt_eksi,f*32),8); }
}
işlev s8_bakış_kur(d:adres,tahta:adres,dolu:u64,p:i64,c:i64,A:adres) {
    bellek_sıfırla(d,s8_BK); bellek_kopyala(d,adres_ekle(ağ,s8_BIAS),s8_AB);
    i32_yaz(d,s8_PQ+8,i32(c));
    yinele(s:=0;s<64;s+=1) { t:=bayt_oku(tahta,s); eğer t!=0 { s8_satır(d,kn_kimlik(t,s,p,c),1); } }
    eğer s8_direkt && tr_da { tr_da_bakış(d,tahta,dolu,p,(p*56)^(c&7),A); }
}
işlev s8_tazele(k:Konum) {
    k.ağ_etkin=1; A:=adres_ekle(adres(k.öz),s8_TRO);
    eğer s8_direkt && tr_da { tr_da_saldırılar(adres(k.tahta),dolu(k),A); }
    yinele(p:=0;p<2;p+=1) {
        s8_bakış_kur(adres_ekle(adres(k.öz),p*s8_BK),adres(k.tahta),dolu(k),p,s8_bağlam(k.şah[p],p),A);
    }
}
işlev s8_güncelle(dst:adres,src:adres,g:İz) {

    eğer g.adet==0 { bellek_kopyala(dst,src,s8_TRO+seç(s8_direkt!=0,512,0)); dön 0; }
    eğer s8_direkt && tr_da {
        eğer s8_toplu_etkin { s8_güncelle_toplu(dst,src,g,0,0); }
        yoksa { s8_güncelle_da(dst,src,g); } dön 0;
    }
    yinele(p:=0;p<2;p+=1) {
        a:=adres_ekle(dst,p*s8_BK); b:=adres_ekle(src,p*s8_BK);
        c:=s8_bağlam(i64(g.şah[p]),p);
        eğer c!=i64(i32_oku(b,s8_PQ+8)) { s8_bakış_kur(a,adres(g.tahta),g.dolu,p,c,0); sürdür; }
        başla:=s8_psq_hızlı(a,b,g,p,c);
        yinele(i:=başla;i<g.adet;i+=1) {
            s:=i64(g.kare[i]); önce:=i64(g.taş[i]); sonra:=i64(g.yeni[i]);
            eğer önce==sonra { sürdür; }
            eğer önce!=0 { s8_satır(a,kn_kimlik(önce,s,p,c),-1); }
            eğer sonra!=0 { s8_satır(a,kn_kimlik(sonra,s,p,c),1); }
        }
    }
}

işlev s8_güncelle_da(dst:adres,src:adres,g:İz) {
    Aes:=adres_ekle(src,s8_TRO); Ay:=adres_ekle(dst,s8_TRO);
    bellek_kopyala(Ay,Aes,512);

    eski:=yerel_dizi(u8,64); bellek_kopyala(adres(eski),adres(g.tahta),64); C:=u64(0);
    yinele(i:=g.adet-1;i>=0;i-=1) { sq:=i64(g.kare[i]); eski[sq]=g.taş[i]; C|=bit(sq); }
    E:=u64(0); yinele(i:=0;i<g.adet;i+=1) { sq:=i64(g.kare[i]); eğer eski[sq]==u8(0) { E|=bit(sq); } }
    eski_dolu:=(g.dolu^(g.dolu&C))|(C^E);
    etkin:=yerel_dizi(i64,2); çev:=yerel_dizi(i64,2);
    yinele(p:=0;p<2;p+=1) {
        a:=adres_ekle(dst,p*s8_BK); b:=adres_ekle(src,p*s8_BK);
        c:=s8_bağlam(i64(g.şah[p]),p); çev[p]=(p*56)^(c&7);
        eğer c!=i64(i32_oku(b,s8_PQ+8)) { etkin[p]=0; sürdür; }
        etkin[p]=1;
        başla:=s8_psq_hızlı(a,b,g,p,c);
        yinele(i:=başla;i<g.adet;i+=1) {
            sq:=i64(g.kare[i]); önce:=i64(g.taş[i]); sonra:=i64(g.yeni[i]);
            eğer önce==sonra { sürdür; }
            eğer önce!=0 { s8_satır(a,kn_kimlik(önce,sq,p,c),-1); }
            eğer sonra!=0 { s8_satır(a,kn_kimlik(sonra,sq,p,c),1); }
        }
    }
    a0:=dst; a1:=adres_ekle(dst,s8_BK); e0:=etkin[0]!=0; e1:=etkin[1]!=0;

    Etk:=C; bb:=eski_dolu;
    iken bb!=u64(0) { sq:=ilk_bit(i64(bb)); bb&=bb-u64(1); eğer (u64_oku(Aes,sq)&C)!=u64(0) { Etk|=bit(sq); } }
    bb=Etk; ilişki:=(e0 || e1) && s8_direkt!=0; bay:=seç(e0,1,0)|seç(e1,2,0); çv:=çev[0]|(çev[1]<<8);
    iken bb!=u64(0) {
        sq:=ilk_bit(i64(bb)); bb&=bb-u64(1);
        t:=i64(g.tahta[sq]); eskiA:=u64_oku(Aes,sq);
        yeni:=u64(0); eğer t!=0 { yeni=saldırı(tür(t),sq,g.dolu,renk(t)); }
        u64_yaz(Ay,sq,yeni);
        eğer !ilişki { sürdür; }
        eğer (C&bit(sq))!=u64(0) {

            eğer eski[sq]!=u8(0) { tr_d_saldıran(a0,a1,bay,çv,adres(eski),sq,eskiA,eski_dolu); }
            eğer t!=0 { tr_d_saldıran(a0,a1,bay|4,çv,adres(g.tahta),sq,yeni,g.dolu); }
        } yoksa {

            T:=((eskiA&eski_dolu)^(yeni&g.dolu))|((eskiA|yeni)&C);
            eğer T!=u64(0) {
                tr_d_saldıran(a0,a1,bay,çv,adres(eski),sq,eskiA&T,eski_dolu);
                tr_d_saldıran(a0,a1,bay|4,çv,adres(g.tahta),sq,yeni&T,g.dolu);
            }
        }
    }

    yinele(p:=0;p<2;p+=1) {
        eğer etkin[p]!=0 { sürdür; }
        a:=adres_ekle(dst,p*s8_BK); c:=s8_bağlam(i64(g.şah[p]),p);
        bellek_sıfırla(a,s8_BK); bellek_kopyala(a,adres_ekle(ağ,s8_BIAS),s8_AB); i32_yaz(a,s8_PQ+8,i32(c));
        yinele(sq:=0;sq<64;sq+=1) { t:=i64(g.tahta[sq]); eğer t!=0 { s8_satır(a,kn_kimlik(t,sq,p,c),1); } }
        eğer s8_direkt { tr_da_bakış(a,adres(g.tahta),g.dolu,p,çev[p],Ay); }
    }
}

yapı S8Satırlar { ek:u64[576]; çıkar:u64[576]; ne:i64; nc:i64; pe:i64; pc:i64; }
işlev s8_liste_ekle(l:S8Satırlar,w:adres,ekle:i64) {
    eğer ekle { adres_yaz(adres(l.ek),l.ne,w); l.ne+=1; } yoksa { adres_yaz(adres(l.çıkar),l.nc,w); l.nc+=1; }
}
işlev s8_liste_psq(l:S8Satırlar,d:adres,f:i64,ekle:i64) {
    s8_liste_ekle(l,adres_ekle(ağ,f*s8_AB),ekle);
    e:=adres_ekle(d,s8_AB);
    eğer ekle { vektör_topla_i16_i32(e,e,adres_ekle(ağ,s8_PSQT+f*16),8); }
    yoksa { vektör_topla_i32(e,e,adres_ekle(s8_psqt_eksi,f*32),8); }
}

genel tr_ofs_adım:i64=-1; genel tr_ofs_sıra:i64[64]; genel tr_ofs_t0:i64[16]; genel tr_ofs_t1:i64[16]; genel tr_ofs_t:i64[32];
işlev tr_ofs_kur(adım:i64) {
    yinele(i:=0;i<64;i+=1) { tr_ofs_sıra[i]=i*12*adım; }
    yinele(tt:=0;tt<16;tt+=1) { tr_ofs_t0[tt]=(tt-1)*adım; tr_ofs_t1[tt]=seç(tt>6,tt-7,tt+5)*adım; tr_ofs_t[tt]=tr_ofs_t0[tt]; tr_ofs_t[16+tt]=tr_ofs_t1[tt]; }
    tr_ofs_adım=adım;
}
işlev tr_liste_saldıran(a0:S8Satırlar,a1:S8Satırlar,bayrak:i64,çevler:i64,tahta:adres,s:i64,att:u64,dolu:u64) {
    e0:=(bayrak&1)!=0; e1:=(bayrak&2)!=0; ekle:=(bayrak&4)!=0;
    t:=i64(bayt_oku(tahta,s)); k:=tür(t); r:=renk(t);
    eğer (s8_rel_süz&1)!=0 && k==6 { dön 0; }
    h:=att&dolu;
    eğer (s8_rel_süz&2)!=0 && k==1 { h&=~tr_piyonlar(tahta,r); }
    eğer s8_rakip_yalnız { h&=~tr_renk_kareleri(tahta,h,r); }
    eğer h==u64(0) { dön 0; }
    adım:=s8_RK*2; eğer adım!=tr_ofs_adım { tr_ofs_kur(adım); }
    taban:=adres_ekle(ağ,s8_REL);

    eğer e0 {
        ç0:=çevler&255; s0:=(r*6+k-1)*64+(s^ç0);
        B0:=adres_ekle(taban,i64(tr_taban[s0])*12*adım); S0:=adres_ekle(adres(tr_sıra),s0*64);
        d0:=seç(ekle,adres(a0.ek),adres(a0.çıkar)); n0:=seç(ekle,a0.ne,a0.nc); x:=h;
        iken x!=u64(0) {
            q:=ilk_bit(i64(x)); x&=x-u64(1);
            adres_yaz(d0,n0,adres_ekle(B0,tr_ofs_sıra[i64(bayt_oku(S0,q^ç0))]+tr_ofs_t0[i64(bayt_oku(tahta,q))])); n0+=1;
        }
        eğer ekle { a0.ne=n0; } yoksa { a0.nc=n0; }
    }
    eğer e1 {
        ç1:=çevler>>8; s1:=((r^1)*6+k-1)*64+(s^ç1);
        B1:=adres_ekle(taban,i64(tr_taban[s1])*12*adım); S1:=adres_ekle(adres(tr_sıra),s1*64);
        d1:=seç(ekle,adres(a1.ek),adres(a1.çıkar)); n1:=seç(ekle,a1.ne,a1.nc); x:=h;
        iken x!=u64(0) {
            q:=ilk_bit(i64(x)); x&=x-u64(1);
            adres_yaz(d1,n1,adres_ekle(B1,tr_ofs_sıra[i64(bayt_oku(S1,q^ç1))]+tr_ofs_t1[i64(bayt_oku(tahta,q))])); n1+=1;
        }
        eğer ekle { a1.ne=n1; } yoksa { a1.nc=n1; }
    }
}

işlev tr_liste_fark(a0:S8Satırlar,a1:S8Satırlar,bayrak:i64,çevler:i64,eski:adres,yeni:adres,s:i64,çık:u64,gir:u64) {
    t:=i64(bayt_oku(yeni,s)); k:=tür(t); r:=renk(t);
    eğer (s8_rel_süz&1)!=0 && k==6 { dön 0; }
    eğer (s8_rel_süz&2)!=0 && k==1 { çık&=~tr_piyonlar(eski,r); gir&=~tr_piyonlar(yeni,r); }
    eğer s8_rakip_yalnız { çık&=~tr_renk_kareleri(eski,çık,r); gir&=~tr_renk_kareleri(yeni,gir,r); }
    eğer (çık|gir)==u64(0) { dön 0; }
    adım:=s8_RK*2; eğer adım!=tr_ofs_adım { tr_ofs_kur(adım); }
    taban:=adres_ekle(ağ,s8_REL);
    eğer (bayrak&1)!=0 {
        ç0:=çevler&255; s0:=(r*6+k-1)*64+(s^ç0);
        B0:=adres_ekle(taban,i64(tr_taban[s0])*12*adım); S0:=adres_ekle(adres(tr_sıra),s0*64);
        n:=a0.nc; x:=çık; d:=adres(a0.çıkar);
        iken x!=u64(0) { q:=ilk_bit(i64(x)); x&=x-u64(1); adres_yaz(d,n,adres_ekle(B0,tr_ofs_sıra[i64(bayt_oku(S0,q^ç0))]+tr_ofs_t0[i64(bayt_oku(eski,q))])); n+=1; }
        a0.nc=n; n=a0.ne; x=gir; d=adres(a0.ek);
        iken x!=u64(0) { q:=ilk_bit(i64(x)); x&=x-u64(1); adres_yaz(d,n,adres_ekle(B0,tr_ofs_sıra[i64(bayt_oku(S0,q^ç0))]+tr_ofs_t0[i64(bayt_oku(yeni,q))])); n+=1; }
        a0.ne=n;
    }
    eğer (bayrak&2)!=0 {
        ç1:=çevler>>8; s1:=((r^1)*6+k-1)*64+(s^ç1);
        B1:=adres_ekle(taban,i64(tr_taban[s1])*12*adım); S1:=adres_ekle(adres(tr_sıra),s1*64);
        n:=a1.nc; x:=çık; d:=adres(a1.çıkar);
        iken x!=u64(0) { q:=ilk_bit(i64(x)); x&=x-u64(1); adres_yaz(d,n,adres_ekle(B1,tr_ofs_sıra[i64(bayt_oku(S1,q^ç1))]+tr_ofs_t1[i64(bayt_oku(eski,q))])); n+=1; }
        a1.nc=n; n=a1.ne; x=gir; d=adres(a1.ek);
        iken x!=u64(0) { q:=ilk_bit(i64(x)); x&=x-u64(1); adres_yaz(d,n,adres_ekle(B1,tr_ofs_sıra[i64(bayt_oku(S1,q^ç1))]+tr_ofs_t1[i64(bayt_oku(yeni,q))])); n+=1; }
        a1.ne=n;
    }
}

işlev tr_liste_bakış(l:S8Satırlar,p:i64,çev:i64,tahta:adres,dolu:u64,A:adres) {
    adım:=s8_RK*2; eğer adım!=tr_ofs_adım { tr_ofs_kur(adım); }
    taban:=adres_ekle(ağ,s8_REL); d:=adres(l.ek); n:=l.ne;
    pt:=p*16;
    bb:=dolu;
    iken bb!=u64(0) {
        sq:=ilk_bit(i64(bb)); bb&=bb-u64(1);
        t:=i64(bayt_oku(tahta,sq)); k:=tür(t); r:=renk(t);
        eğer (s8_rel_süz&1)!=0 && k==6 { sürdür; }
        h:=u64_oku(A,sq)&dolu;
        eğer (s8_rel_süz&2)!=0 && k==1 { h&=~tr_piyonlar(tahta,r); }
        eğer s8_rakip_yalnız { h&=~tr_renk_kareleri(tahta,h,r); }
        eğer h==u64(0) { sürdür; }
        s0:=(seç(p==0,r,r^1)*6+k-1)*64+(sq^çev);
        B:=adres_ekle(taban,i64(tr_taban[s0])*12*adım); S:=adres_ekle(adres(tr_sıra),s0*64);
        iken h!=u64(0) {
            q:=ilk_bit(i64(h)); h&=h-u64(1);
            adres_yaz(d,n,adres_ekle(B,tr_ofs_sıra[i64(bayt_oku(S,q^çev))]+tr_ofs_t[pt+i64(bayt_oku(tahta,q))])); n+=1;
        }
    }
    l.ne=n;
}
işlev s8_güncelle_toplu(dst:adres,src:adres,g:İz,önbellek:adres,bb_yeni:adres) {
    listeler:=yerel_dizi(S8Satırlar,2);
    Aes:=adres_ekle(src,s8_TRO); Ay:=adres_ekle(dst,s8_TRO);
    bellek_kopyala(Ay,Aes,512);

    eski:=yerel_dizi(u8,64); bellek_kopyala(adres(eski),adres(g.tahta),64); C:=u64(0);
    E:=u64(0);
    yinele(i:=g.adet-1;i>=0;i-=1) { sq:=i64(g.kare[i]); eski[sq]=g.taş[i]; C|=bit(sq); eğer g.taş[i]==u8(0) { E|=bit(sq); } }
    eski_dolu:=(g.dolu^(g.dolu&C))|(C^E);
    etkin:=yerel_dizi(i64,2); çev:=yerel_dizi(i64,2);
    yinele(p:=0;p<2;p+=1) {
        a:=adres_ekle(dst,p*s8_BK); b:=adres_ekle(src,p*s8_BK);
        c:=s8_bağlam(i64(g.şah[p]),p); çev[p]=(p*56)^(c&7);
        eğer c!=i64(i32_oku(b,s8_PQ+8)) { etkin[p]=0; sürdür; }
        etkin[p]=1;
        l:=listeler[p]; l.ne=0; l.nc=0;
        bellek_kopyala(adres_ekle(a,s8_AB),adres_ekle(b,s8_AB),64);
        yinele(i:=0;i<g.adet;i+=1) {
            sq:=i64(g.kare[i]); önce:=i64(g.taş[i]); sonra:=i64(g.yeni[i]);
            eğer önce==sonra { sürdür; }
            eğer önce!=0 { s8_liste_psq(l,a,kn_kimlik(önce,sq,p,c),0); }
            eğer sonra!=0 { s8_liste_psq(l,a,kn_kimlik(sonra,sq,p,c),1); }
        }
        l.pe=l.ne; l.pc=l.nc;
    }
    a0:=listeler[0]; a1:=listeler[1]; e0:=etkin[0]!=0; e1:=etkin[1]!=0;

    Etk:=C; bb:=eski_dolu;
    eğer bb_yeni!=0 {
        eski_bb:=yerel_dizi(u64,13); bellek_kopyala(adres(eski_bb),bb_yeni,104);
        yinele(i:=0;i<g.adet;i+=1) { b:=bit(i64(g.kare[i])); eski_bb[i64(g.taş[i])]^=b; eski_bb[i64(g.yeni[i])]^=b; }
        çapraz:=eski_bb[3]|eski_bb[5]|eski_bb[9]|eski_bb[11];
        düz:=eski_bb[4]|eski_bb[5]|eski_bb[10]|eski_bb[11];
        atlar:=eski_bb[2]|eski_bb[8]; şahlar:=eski_bb[6]|eski_bb[12];
        bb=C;
        iken bb!=u64(0) {
            sq:=ilk_bit(i64(bb)); bb&=bb-u64(1);
            Etk|=(piyon_alanı[64+sq]&eski_bb[1])|(piyon_alanı[sq]&eski_bb[7])|(at_alanı[sq]&atlar)|(şah_alanı[sq]&şahlar)|
                 (fil_saldırısı(sq,eski_dolu)&çapraz)|(kale_saldırısı(sq,eski_dolu)&düz);
        }
    } yoksa {
        iken bb!=u64(0) { sq:=ilk_bit(i64(bb)); bb&=bb-u64(1); eğer (u64_oku(Aes,sq)&C)!=u64(0) { Etk|=bit(sq); } }
    }
    bb=Etk; ilişki:=(e0 || e1) && s8_direkt!=0; bay:=seç(e0,1,0)|seç(e1,2,0); çv:=çev[0]|(çev[1]<<8);
    iken bb!=u64(0) {
        sq:=ilk_bit(i64(bb)); bb&=bb-u64(1);
        t:=i64(g.tahta[sq]); eskiA:=u64_oku(Aes,sq);
        yeni:=u64(0); eğer t!=0 { yeni=saldırı(tür(t),sq,g.dolu,renk(t)); }
        u64_yaz(Ay,sq,yeni);
        eğer !ilişki { sürdür; }
        eğer (C&bit(sq))!=u64(0) {

            eğer eski[sq]!=u8(0) { tr_liste_saldıran(a0,a1,bay,çv,adres(eski),sq,eskiA,eski_dolu); }
            eğer t!=0 { tr_liste_saldıran(a0,a1,bay|4,çv,adres(g.tahta),sq,yeni,g.dolu); }
        } yoksa {

            T:=((eskiA&eski_dolu)^(yeni&g.dolu))|((eskiA|yeni)&C);
            eğer T!=u64(0) { tr_liste_fark(a0,a1,bay,çv,adres(eski),adres(g.tahta),sq,eskiA&T&eski_dolu,yeni&T&g.dolu); }
        }
    }
    yinele(p:=0;p<2;p+=1) {
        eğer etkin[p]==0 { sürdür; }
        l:=listeler[p]; a:=adres_ekle(dst,p*s8_BK); b:=adres_ekle(src,p*s8_BK); rk:=s8_RK;
        satır_topla_çıkar_i16(a,b,rk,adres(l.ek),l.ne,adres(l.çıkar),l.nc);
        eğer rk<s8_A {
            yinele(j:=0;j<l.pe;j+=1) { adres_yaz(adres(l.ek),j,adres_ekle(adres_oku(adres(l.ek),j),rk*2)); }
            yinele(j:=0;j<l.pc;j+=1) { adres_yaz(adres(l.çıkar),j,adres_ekle(adres_oku(adres(l.çıkar),j),rk*2)); }
            satır_topla_çıkar_i16(adres_ekle(a,rk*2),adres_ekle(b,rk*2),s8_A-rk,adres(l.ek),l.pe,adres(l.çıkar),l.pc);
        }
    }

    yinele(p:=0;p<2;p+=1) {
        eğer etkin[p]!=0 { sürdür; }
        a:=adres_ekle(dst,p*s8_BK); c:=s8_bağlam(i64(g.şah[p]),p);
        s8_bakış_önbellek(a,adres(g.tahta),g.dolu,p,c,Ay,önbellek);
    }
}

yapı S8Yenileme { geçerli:i64; tahta:u8[64]; öz:i16[2080]; }
işlev s8_bakış_önbellek(d:adres,tahta:adres,dolu:u64,p:i64,c:i64,A:adres,önbellek:adres) {
    eğer önbellek==0 { s8_bakış_kur(d,tahta,dolu,p,c,A); dön 0; }
    yuva:=p*64+(c/8)*2+(c&7)/7;
    e:=gör(S8Yenileme,adres_ekle(önbellek,yuva*boyut(S8Yenileme))); acc:=adres(e.öz);
    eğer !e.geçerli {
        bellek_sıfırla(adres(e.tahta),64); bellek_sıfırla(acc,s8_BK);
        bellek_kopyala(acc,adres_ekle(ağ,s8_BIAS),s8_AB); i32_yaz(acc,s8_PQ+8,i32(c)); e.geçerli=1;
    }
    l:=yerel(S8Satırlar); l.ne=0; l.nc=0;
    yinele(sq:=0;sq<64;sq+=1) {

        eğer (sq&7)==0 && u64_oku(adres(e.tahta),sq>>3)==u64_oku(tahta,sq>>3) { sq+=7; sürdür; }
        eski:=i64(e.tahta[sq]); yeni:=i64(bayt_oku(tahta,sq));
        eğer eski==yeni { sürdür; }
        eğer eski!=0 { s8_liste_psq(l,acc,kn_kimlik(eski,sq,p,c),0); }
        eğer yeni!=0 { s8_liste_psq(l,acc,kn_kimlik(yeni,sq,p,c),1); }
        e.tahta[sq]=u8(yeni);
    }
    eğer l.ne!=0 || l.nc!=0 { satır_topla_çıkar_i16(acc,acc,s8_A,adres(l.ek),l.ne,adres(l.çıkar),l.nc); }
    bellek_kopyala(d,acc,s8_BK);
    l.ne=0; l.nc=0; çev:=(p*56)^(c&7);
    tr_liste_bakış(l,p,çev,tahta,dolu,A);
    eğer l.ne!=0 { satır_topla_çıkar_i16(d,d,s8_RK,adres(l.ek),l.ne,adres(l.çıkar),0); }
}
işlev ağ_güncelle_arama(dst:adres,src:adres,g:İz,a:Arayıcı,bb:adres) {
    eğer ağ_türü==2 && s8_toplu_etkin && s8_direkt && tr_da && g.adet!=0 { s8_güncelle_toplu(dst,src,g,a.yenileme,bb); }
    yoksa { ağ_güncelle(dst,src,g); }
}

işlev s8_çift(x:adres,a:adres) {
    eğer s8_ph==0 { çarp_kırp_i16_u8(x,a,adres_ekle(a,s8_A),s8_H); dön 0; }
    h:=s8_ph;
    çarp_kırp_i16_u8(x,a,adres_ekle(a,h*2),h);
    çarp_kırp_i16_u8(adres_ekle(x,h),adres_ekle(a,h*4),adres_ekle(a,(s8_H+h)*2),s8_H-h);
}
işlev s8_sırala(p:adres,h:i64) {
    t:=yerel_dizi(i16,2048);
    yinele(j:=0;j<s8_A;j+=1) {
        o:=seç(j<h,j,seç(j<2*h,s8_H+j-h,seç(j<s8_H+h,h+j-2*h,j)));
        t[j]=i16_oku(p,o);
    }
    bellek_kopyala(p,adres(t),s8_AB);
}

işlev s8_psq_hızlı(a:adres,b:adres,g:İz,p:i64,c:i64):i64 {
    eğer g.adet>=2 && g.taş[0]!=u8(0) && g.yeni[0]==u8(0) && g.yeni[1]==g.taş[0] {
        fa:=kn_kimlik(i64(g.taş[0]),i64(g.kare[0]),p,c); fb:=kn_kimlik(i64(g.yeni[1]),i64(g.kare[1]),p,c);
        vektör_topla_çıkar_i16(a,b,adres_ekle(ağ,fb*s8_AB),adres_ekle(ağ,fa*s8_AB),s8_A);
        bellek_kopyala(adres_ekle(a,s8_AB),adres_ekle(b,s8_AB),64);
        e:=adres_ekle(a,s8_AB);
        vektör_topla_i16_i32(e,e,adres_ekle(ağ,s8_PSQT+fb*16),8); vektör_topla_i32(e,e,adres_ekle(s8_psqt_eksi,fa*32),8);
        eğer g.taş[1]!=u8(0) { s8_satır(a,kn_kimlik(i64(g.taş[1]),i64(g.kare[1]),p,c),-1); }
        dön 2;
    }
    bellek_kopyala(a,b,s8_BK);
    dön 0;
}

genel s8_geçer_mask:u64[128]; genel s8_geçer_hazır:i64=0;
işlev s8_geçer_kur() {
    eğer s8_geçer_hazır { dön 0; }
    yinele(c:=0;c<2;c+=1) { yinele(s:=0;s<64;s+=1) {
        m:=u64(0); f:=s%8; r:=s/8;
        yinele(df:=-1;df<=1;df+=1) {
            x:=f+df; eğer x<0 || x>7 { sürdür; }
            y:=seç(c==0,r+1,r-1);
            iken y>=0 && y<8 { m|=bit(y*8+x); y+=seç(c==0,1,-1); }
        }
        s8_geçer_mask[c*64+s]=m;
    } }
    s8_geçer_hazır=1;
}

işlev s8_saldırı_birleştir(att:adres,bb:u64):u64 {
    h:=u64(0); iken bb!=u64(0) { s:=ilk_bit(i64(bb)); bb&=bb-u64(1); h|=u64_oku(att,s); } dön h;
}
işlev s8_asılı_yalın(k:Konum,G:adres,att:adres) {
    P:=yerel_dizi(u64,2); M:=yerel_dizi(u64,2); R:=yerel_dizi(u64,2); A:=yerel_dizi(u64,2);
    wp:=k.bit_tahtası[1]; bp:=k.bit_tahtası[7];
    P[0]=((wp<<u64(7))&u64(0x7f7f7f7f7f7f7f7f))|((wp<<u64(9))&u64(0xfefefefefefefefe));
    P[1]=((bp>>u64(9))&u64(0x7f7f7f7f7f7f7f7f))|((bp>>u64(7))&u64(0xfefefefefefefefe));
    yinele(c:=0;c<2;c+=1) {
        o:=6*c; M[c]=s8_saldırı_birleştir(att,k.bit_tahtası[o+2]|k.bit_tahtası[o+3]);
        R[c]=s8_saldırı_birleştir(att,k.bit_tahtası[o+4]);
        A[c]=P[c]|M[c]|R[c]|s8_saldırı_birleştir(att,k.bit_tahtası[o+5])|şah_alanı[k.şah[c]];
    }
    yinele(c:=0;c<2;c+=1) {
        o:=6*c;e:=1-c; hafif:=k.bit_tahtası[o+2]|k.bit_tahtası[o+3];
        u64_yaz(G,c,(hafif&P[e])|(k.bit_tahtası[o+4]&(P[e]|M[e]))|(k.bit_tahtası[o+5]&(P[e]|M[e]|R[e])));
        u64_yaz(G,2+c,(k.renkler[c]&~k.bit_tahtası[o+6])&A[e]&~A[c]);
    }
}
işlev s8_asılı_bul(k:Konum,G:adres,X:adres,Y:adres,att:adres) {
    eğer att!=0 && !s8_asılı2 && !s8_klasik && !s8_klasik2 && s8_S==0 { s8_asılı_yalın(k,G,att); dön 0; }
    aP:=yerel_dizi(u64,2); aM:=yerel_dizi(u64,2); aR:=yerel_dizi(u64,2); a1:=yerel_dizi(u64,2); a2:=yerel_dizi(u64,2);
    bat:=yerel_dizi(u64,2); doğ:=yerel_dizi(u64,2);
    d:=dolu(k); nm:=0;
    byT:=yerel_dizi(u64,12); zc:=yerel_dizi(i64,10); bölgeler:=yerel_dizi(u64,2); mob:=yerel_dizi(i64,2);
    tam:=s8_klasik2!=0 || s8_S>0; mob[0]=0; mob[1]=0;
    eğer tam {
        yinele(i:=0;i<12;i+=1) { byT[i]=u64(0); } yinele(i:=0;i<10;i+=1) { zc[i]=0; }
        yinele(c:=0;c<2;c+=1) { bölgeler[c]=şah_alanı[k.şah[c]]|bit(k.şah[c]); }
    }
    yinele(c:=0;c<2;c+=1) {
        P:=k.bit_tahtası[6*c+1];
        eğer c==0 { bat[c]=(P<<u64(7))&u64(0x7f7f7f7f7f7f7f7f); doğ[c]=(P<<u64(9))&u64(0xfefefefefefefefe); }
        yoksa { bat[c]=(P>>u64(9))&u64(0x7f7f7f7f7f7f7f7f); doğ[c]=(P>>u64(7))&u64(0xfefefefefefefefe); }
    }
    yinele(c:=0;c<2;c+=1) {
        o:=6*c; e:=1-c; serbest:=~k.renkler[c]&~(bat[e]|doğ[e]);
        h1:=bat[c]; h2:=bat[c]&doğ[c]; h1|=doğ[c]; p1:=bat[c]|doğ[c]; m1:=u64(0); r1:=u64(0);
        eğer tam {
            byT[o]=p1; bb:=k.bit_tahtası[o+1];
            iken bb!=u64(0) { s:=ilk_bit(i64(bb)); bb&=bb-u64(1); eğer (piyon_alanı[c*64+s]&bölgeler[e])!=u64(0) { zc[e*5]+=1; } }
        }
        yinele(t:=2;t<=5;t+=1) {
            bb:=k.bit_tahtası[o+t];
            iken bb!=u64(0) {
                s:=ilk_bit(i64(bb)); bb&=bb-u64(1);
                a:=u64(0);
                eğer att!=0 { a=u64_oku(att,s); } yoksa eğer t==2 { a=at_alanı[s]; } yoksa eğer t==3 { a=fil_saldırısı(s,d); } yoksa eğer t==4 { a=kale_saldırısı(s,d); } yoksa { a=fil_saldırısı(s,d)|kale_saldırısı(s,d); }
                h2|=h1&a; h1|=a;
                eğer t<=3 { m1|=a; } yoksa eğer t==4 { r1|=a; }
                eğer tam { byT[o+t-1]|=a; eğer (a&bölgeler[e])!=u64(0) { zc[e*5+t-1]+=1; } mob[c]+=bit_say(i64(a&serbest)); }
                eğer s8_klasik && nm<32 { u64_yaz(X,5+nm,u64((c<<8)|((t-2)<<4)|enaz(15,bit_say(i64(a&serbest))))); nm+=1; }
            }
        }
        a:=şah_alanı[k.şah[c]]; h2|=h1&a; h1|=a;
        aP[c]=p1; aM[c]=m1; aR[c]=r1; a1[c]=h1; a2[c]=h2;
    }
    eğer s8_S>0 {
        yinele(c:=0;c<2;c+=1) { u64_yaz(Y,c,a1[c]); u64_yaz(Y,2+c,a2[c]); u64_yaz(Y,4+c,aP[c]); u64_yaz(Y,18+c,u64(mob[c])); }
        yinele(i:=0;i<12;i+=1) { u64_yaz(Y,6+i,byT[i]); }
    }
    eğer s8_klasik2 {
        boş:=~d;
        yinele(c:=0;c<2;c+=1) {
            e:=1-c; şah:=k.şah[c];
            yinele(t:=0;t<5;t+=1) { u64_yaz(X,40+c*5+t,u64(zc[c*5+t])); }
            kn:=at_alanı[şah]; kd:=fil_saldırısı(şah,d); ko:=kale_saldırısı(şah,d);
            yinele(t:=1;t<5;t+=1) {
                ch:=seç(t==1,kn,seç(t==2,kd,seç(t==3,ko,kd|ko)));
                u64_yaz(X,50+c*4+t-1,u64(bit_say(i64(ch&~k.renkler[e]&byT[e*6+t]&~a1[c]))));
            }
            geç:=u64(0); bb:=k.bit_tahtası[6*c+1]; ep:=k.bit_tahtası[6*e+1];
            iken bb!=u64(0) { s:=ilk_bit(i64(bb)); bb&=bb-u64(1); eğer (s8_geçer_mask[c*64+s]&ep)==u64(0) { geç|=bit(s); } }
            u64_yaz(X,58+c,geç);
            P:=k.bit_tahtası[6*c+1]; tek:=u64(0); çift:=u64(0);
            eğer c==0 { tek=(P<<u64(8))&boş; çift=((tek&u64(0xff0000))<<u64(8))&boş; }
            yoksa { tek=(P>>u64(8))&boş; çift=((tek&u64(0xff0000000000))>>u64(8))&boş; }
            güv:=(tek|çift)&(~a1[e]|a1[c]); sa:=u64(0);
            eğer c==0 { sa=((güv<<u64(7))&u64(0x7f7f7f7f7f7f7f7f))|((güv<<u64(9))&u64(0xfefefefefefefefe)); }
            yoksa { sa=((güv>>u64(9))&u64(0x7f7f7f7f7f7f7f7f))|((güv>>u64(7))&u64(0xfefefefefefefefe)); }
            hedef:=k.renkler[e]&~k.bit_tahtası[6*e+1]&~k.bit_tahtası[6*e+6];
            u64_yaz(X,60+c,u64(bit_say(i64(sa&hedef))));
        }
    }
    eğer s8_klasik {
        u64_yaz(X,4,u64(nm));
        yinele(c:=0;c<2;c+=1) {
            e:=1-c; bölge:=şah_alanı[k.şah[c]]|bit(k.şah[c]);
            u64_yaz(X,c,u64(bit_say(i64(a1[e]&bölge))+bit_say(i64(a2[e]&bölge))));
            geç:=u64(0); bb:=k.bit_tahtası[6*c+1]; ep:=k.bit_tahtası[6*e+1];
            iken bb!=u64(0) { s:=ilk_bit(i64(bb)); bb&=bb-u64(1); eğer (s8_geçer_mask[c*64+s]&ep)==u64(0) { geç|=bit(s); } }
            u64_yaz(X,2+c,geç);
        }
    }
    yinele(c:=0;c<2;c+=1) {
        e:=1-c; o:=6*c; eo:=6*e;
        hafif:=k.bit_tahtası[o+2]|k.bit_tahtası[o+3];
        u64_yaz(G,c,(hafif&aP[e])|(k.bit_tahtası[o+4]&(aP[e]|aM[e]))|(k.bit_tahtası[o+5]&(aP[e]|aM[e]|aR[e])));
        taş:=k.renkler[c]&~k.bit_tahtası[o+6];
        u64_yaz(G,2+c,taş&a1[e]&~a1[c]);
        eğer s8_asılı2 {
            u64_yaz(G,4+c,taş&a2[e]&a1[c]&~a2[c]);
            şah:=k.şah[c]; çivili:=u64(0);
            ışıncılar:=(kale_ışını[şah]&(k.bit_tahtası[eo+4]|k.bit_tahtası[eo+5]))|(fil_ışını[şah]&(k.bit_tahtası[eo+3]|k.bit_tahtası[eo+5]));
            iken ışıncılar!=u64(0) {
                s:=ilk_bit(i64(ışıncılar)); ışıncılar&=ışıncılar-u64(1);
                arada:=aradaki_kareler[şah*64+s]&d;
                eğer (arada&(arada-u64(1)))==u64(0) { çivili|=arada&k.renkler[c]; }
            }
            u64_yaz(G,6+c,çivili);
        }
    }
}

yapı S8İlişkiListesi { ek:u64[1024]; ne:i64; }
işlev s8_rs(d:adres,l:adres,f:i64) {
    eğer l!=0 { ll:=gör(S8İlişkiListesi,l); adres_yaz(adres(ll.ek),ll.ne,adres_ekle(ağ,s8_REL+f*s8_RK*2)); ll.ne+=1; dön 0; }
    eğer s8_rel_hızlı && s8_rel_bayt==1 { vektör_topla_i8_i16(d,d,adres_ekle(ağ,s8_REL+f*s8_RK),s8_RK); }
    yoksa eğer s8_rel_hızlı { vektör_topla_i16(d,d,adres_ekle(ağ,s8_REL+f*s8_RK*2),s8_RK); } yoksa { s8_rel_satır(d,f); }
}
işlev s8_asılı_ekle(d:adres,tahta:adres,p:i64,çev:i64,G:adres,X:adres,l:adres) {
    eğer s8_asılı {
        yinele(j:=0;j<4;j+=1) {
            bb:=u64_oku(G,j);
            iken bb!=u64(0) {
                s:=ilk_bit(i64(bb)); bb&=bb-u64(1); t:=i64(bayt_oku(tahta,s));
                s8_rs(d,l,s8_HB+(((renk(t)^p)*6+tür(t)-1)*64+(s^çev))*2+(j>>1));
            }
        }
    }
    eğer s8_klasik {
        yinele(c:=0;c<2;c+=1) {
            cr:=c^p;
            s8_rs(d,l,s8_HB3+cr*16+enaz(15,i64(u64_oku(X,c))));
            bb:=u64_oku(X,2+c);
            iken bb!=u64(0) { s:=ilk_bit(i64(bb)); bb&=bb-u64(1); s8_rs(d,l,s8_HB3+160+cr*64+(s^çev)); }
        }
        n:=i64(u64_oku(X,4));
        yinele(i:=0;i<n;i+=1) {
            v:=i64(u64_oku(X,5+i)); c:=v>>8;
            s8_rs(d,l,s8_HB3+32+((c^p)*4+((v>>4)&15))*16+(v&15));
        }
    }
    eğer s8_klasik2 {
        yinele(c:=0;c<2;c+=1) {
            cr:=c^p;
            yinele(t:=0;t<5;t+=1) { n:=i64(u64_oku(X,40+c*5+t)); eğer n>0 { s8_rs(d,l,s8_HB4+cr*40+t*8+enaz(7,n)); } }
            yinele(t:=1;t<5;t+=1) { n:=i64(u64_oku(X,50+c*4+t-1)); eğer n>0 { s8_rs(d,l,s8_HB4+80+cr*16+(t-1)*4+enaz(3,n)); } }
            bb:=u64_oku(X,58+c);
            iken bb!=u64(0) {
                s:=ilk_bit(i64(bb)); bb&=bb-u64(1);
                sr:=seç(c==0,s/8,7-s/8); ön:=seç(c==0,s+8,s-8);
                s8_rs(d,l,s8_HB4+112+cr*16+sr*2+seç(i64(bayt_oku(tahta,ön))==0,1,0));
            }
            n:=i64(u64_oku(X,60+c)); eğer n>0 { s8_rs(d,l,s8_HB4+144+cr*4+enaz(3,n)); }
        }
    }
    eğer s8_asılı2 {
        yinele(j:=0;j<8;j+=1) {
            bb:=u64_oku(G,j);
            iken bb!=u64(0) {
                s:=ilk_bit(i64(bb)); bb&=bb-u64(1); t:=i64(bayt_oku(tahta,s));
                s8_rs(d,l,s8_HB2+(((renk(t)^p)*6+tür(t)-1)*64+(s^çev))*4+(j>>1));
            }
        }
    }
}

işlev s8_atla(k:Konum,G:adres,Y:adres,x:adres) {
    d:=dolu(k);
    yinele(i:=0;i<2;i+=1) {
        c:=k.sıra^i; e:=1-c; o:=6*c; eo:=6*e; şah:=k.şah[c];
        a1c:=u64_oku(Y,c); a1e:=u64_oku(Y,e); a2c:=u64_oku(Y,2+c); a2e:=u64_oku(Y,2+e); pac:=u64_oku(Y,4+c); pae:=u64_oku(Y,4+e);
        own:=k.renkler[c]&~k.bit_tahtası[o+6];
        v:=yerel_dizi(i64,16);
        v[0]=32*bit_say(i64(u64_oku(G,c))); v[1]=32*bit_say(i64(u64_oku(G,2+c)));
        bölge:=şah_alanı[şah]|bit(şah); v[2]=16*(bit_say(i64(a1e&bölge))+bit_say(i64(a2e&bölge)));
        kn:=at_alanı[şah]; kd:=fil_saldırısı(şah,d); ko:=kale_saldırısı(şah,d); ch:=0;
        yinele(t:=1;t<5;t+=1) {
            m:=seç(t==1,kn,seç(t==2,kd,seç(t==3,ko,kd|ko)));
            ch+=bit_say(i64(m&~k.renkler[e]&u64_oku(Y,6+eo+t)&~a1c));
        }
        v[3]=32*ch; v[4]=4*i64(u64_oku(Y,18+c));
        np:=0; mr:=0; bb:=k.bit_tahtası[o+1]; ep:=k.bit_tahtası[eo+1];
        iken bb!=u64(0) {
            s:=ilk_bit(i64(bb)); bb&=bb-u64(1);
            eğer (s8_geçer_mask[c*64+s]&ep)==u64(0) { np+=1; mr=ençok(mr,seç(c==0,s/8,7-s/8)); }
        }
        v[5]=32*np; v[6]=32*mr;
        P:=k.bit_tahtası[o+1]; boş:=~d; tek:=u64(0); çift:=u64(0);
        eğer c==0 { tek=(P<<u64(8))&boş; çift=((tek&u64(0xff0000))<<u64(8))&boş; }
        yoksa { tek=(P>>u64(8))&boş; çift=((tek&u64(0xff0000000000))>>u64(8))&boş; }
        güv:=(tek|çift)&(~a1e|a1c); sa:=u64(0);
        eğer c==0 { sa=((güv<<u64(7))&u64(0x7f7f7f7f7f7f7f7f))|((güv<<u64(9))&u64(0xfefefefefefefefe)); }
        yoksa { sa=((güv>>u64(9))&u64(0x7f7f7f7f7f7f7f7f))|((güv>>u64(7))&u64(0xfefefefefefefefe)); }
        v[7]=64*bit_say(i64(sa&k.renkler[e]&~k.bit_tahtası[eo+1]&~k.bit_tahtası[eo+6]));
        v[8]=32*bit_say(i64(own&a1e));
        çivili:=u64(0);
        ışıncılar:=(kale_ışını[şah]&(k.bit_tahtası[eo+4]|k.bit_tahtası[eo+5]))|(fil_ışını[şah]&(k.bit_tahtası[eo+3]|k.bit_tahtası[eo+5]));
        iken ışıncılar!=u64(0) {
            s:=ilk_bit(i64(ışıncılar)); ışıncılar&=ışıncılar-u64(1);
            arada:=aradaki_kareler[şah*64+s]&d;
            eğer (arada&(arada-u64(1)))==u64(0) { çivili|=arada&k.renkler[c]; }
        }
        v[9]=32*bit_say(i64(çivili));
        yarı:=seç(c==0,u64(0xffffffff00000000),u64(0x00000000ffffffff));
        v[10]=8*bit_say(i64(a1c)); v[11]=16*bit_say(i64(a1c&yarı));
        v[12]=32*bit_say(i64(pac&k.renkler[e]&~k.bit_tahtası[eo+1]&~k.bit_tahtası[eo+6]));
        v[13]=32*bit_say(i64(own&~a1c));
        v[14]=seç((a1e&k.bit_tahtası[o+6])!=u64(0),255,0); v[15]=16*bit_say(i64(a2c));
        yinele(j:=0;j<16;j+=1) { bayt_yaz(x,s8_A+i*16+j,enaz(255,v[j])); }
    }
}
işlev s8_girdi(k:Konum,d:adres,x:adres,G:adres,X:adres,Y:adres) {
    tmp:=yerel_dizi(i16,2048); A:=yerel_dizi(u64,64);
    Ap:=adres(A);
    eğer s8_direkt && !tr_da { tr_da_saldırılar(adres(k.tahta),dolu(k),Ap); }
    eğer s8_asılı || s8_asılı2 || s8_gerilim || s8_klasik || s8_klasik2 || s8_S>0 { s8_asılı_bul(k,G,X,Y,seç(s8_direkt && tr_da,adres_ekle(d,s8_TRO),0)); }
    ek:=(s8_direkt!=0 && !tr_da) || s8_asılı!=0 || s8_asılı2!=0 || s8_klasik!=0 || s8_klasik2!=0;

    liste_yolu:=s8_rel_bayt==2 && s8_rel_hızlı!=0; rl:=yerel(S8İlişkiListesi);
    yinele(v:=0;v<2;v+=1) {
        p:=k.sıra^v; a:=adres_ekle(d,p*s8_BK);
        eğer ek && s8_ph>0 && (tr_da || !s8_direkt) {

            h:=s8_ph; çev:=(p*56)^(i64(i32_oku(a,s8_PQ+8))&7);
            eğer liste_yolu {
                rl.ne=0; s8_asılı_ekle(adres(tmp),adres(k.tahta),p,çev,G,X,adres(rl));
                satır_topla_çıkar_i16(adres(tmp),a,h*2,adres(rl.ek),rl.ne,adres(rl.ek),0);
            } yoksa {
                bellek_kopyala(adres(tmp),a,h*4);
                s8_asılı_ekle(adres(tmp),adres(k.tahta),p,çev,G,X,0);
            }
            xv:=adres_ekle(x,v*s8_H);
            çarp_kırp_i16_u8(xv,adres(tmp),adres_ekle(adres(tmp),h*2),h);
            çarp_kırp_i16_u8(adres_ekle(xv,h),adres_ekle(a,h*4),adres_ekle(a,(s8_H+h)*2),s8_H-h);
        } yoksa eğer ek {
            bellek_kopyala(adres(tmp),a,s8_AB);
            çev:=(p*56)^(i64(i32_oku(a,s8_PQ+8))&7);
            eğer s8_direkt && !tr_da { tr_da_bakış(adres(tmp),adres(k.tahta),dolu(k),p,çev,Ap); }
            eğer s8_asılı || s8_asılı2 || s8_klasik || s8_klasik2 { s8_asılı_ekle(adres(tmp),adres(k.tahta),p,çev,G,X,0); }
            s8_çift(adres_ekle(x,v*s8_H),adres(tmp));
        } yoksa {
            s8_çift(adres_ekle(x,v*s8_H),a);
        }
    }
}
işlev s8_kova(k:Konum):i64 { dön enaz(7,(bit_say(i64(dolu(k)))-1)/4); }

işlev s8_baş_çift32_16(x:adres,h2:adres,bk:i64) {
    h1:=yerel_dizi(u8,64); z:=yerel_dizi(i32,32); indis:=yerel_dizi(u16,528);
    adet:=indis4_u8(x,s8_AX,adres(indis),adres(s8_indis_tablo));
    seyrek_karma_indis_u8_i8_i32(adres(z),x,adres_ekle(adres(s8_karma_ptr),bk*s8_AX*2),adres_ekle(ağ,s8_B1+bk*128),s8_AX,32,adres(indis),adet);
    kırp_çift_i32_u8(adres(h1),adres(z),32,6);
    yoğun_çift_u8_i16_i32(adres(z),adres(h1),adres_ekle(adres(s8_w2ç),bk*2048),adres_ekle(ağ,s8_B2+bk*64),64,16);
    kırp_çift_i32_u8(h2,adres(z),16,6);
}
işlev s8_baş(x:adres,h2:adres,bk:i64) {
    h1:=yerel_dizi(u8,256); g2:=2*s8_L1;
    eğer s8_grup_etkin {
        z:=yerel_dizi(i32,128); indis:=yerel_dizi(u16,1032); adet:=0;
        adet=indis4_u8(x,s8_AX,adres(indis),adres(s8_indis_tablo));
        seyrek_blok_indis_u8_i8_i32(adres(z),x,adres_ekle(adres(s8_w1g),bk*s8_L1*s8_AX),adres_ekle(ağ,s8_B1+bk*s8_L1*4),s8_AX,s8_L1,adres(indis),adet);
        kırp_çift_i32_u8(adres(h1),adres(z),s8_L1,6);
        eğer kn_blok_etkin { kn_blok(h2,adres(h1),adres_ekle(adres(s8_w2p),bk*s8_L2*g2),adres_ekle(adres(s8_b2p),bk*s8_L2*4),g2,s8_L2); }
        yoksa { kn_baş(h2,adres(h1),adres_ekle(ağ,s8_W2+bk*s8_L2*g2),adres_ekle(ağ,s8_B2+bk*s8_L2*4),g2,s8_L2); }
    } yoksa eğer s8_seyrek {
        z:=yerel_dizi(i32,128);
        seyrek_u8_i8_i32(adres(z),x,adres_ekle(adres(s8_w1s),bk*s8_L1*s8_AX),adres_ekle(ağ,s8_B1+bk*s8_L1*4),s8_AX,s8_L1);
        kırp_çift_i32_u8(adres(h1),adres(z),s8_L1,6);
        eğer kn_blok_etkin { kn_blok(h2,adres(h1),adres_ekle(adres(s8_w2p),bk*s8_L2*g2),adres_ekle(adres(s8_b2p),bk*s8_L2*4),g2,s8_L2); }
        yoksa { kn_baş(h2,adres(h1),adres_ekle(ağ,s8_W2+bk*s8_L2*g2),adres_ekle(ağ,s8_B2+bk*s8_L2*4),g2,s8_L2); }
    } yoksa eğer kn_blok_etkin {
        kn_blok(adres(h1),x,adres_ekle(adres(s8_w1p),bk*s8_L1*s8_AX),adres_ekle(adres(s8_b1p),bk*s8_L1*4),s8_AX,s8_L1);
        kn_blok(h2,adres(h1),adres_ekle(adres(s8_w2p),bk*s8_L2*g2),adres_ekle(adres(s8_b2p),bk*s8_L2*4),g2,s8_L2);
    } yoksa {
        kn_baş(adres(h1),x,adres_ekle(ağ,s8_W1+bk*s8_L1*s8_AX),adres_ekle(ağ,s8_B1+bk*s8_L1*4),s8_AX,s8_L1);
        kn_baş(h2,adres(h1),adres_ekle(ağ,s8_W2+bk*s8_L2*g2),adres_ekle(ağ,s8_B2+bk*s8_L2*4),g2,s8_L2);
    }
}
işlev s8_değeri_ölçekli(k:Konum,d:adres,ölçek:i64):i64 {
    x:=yerel_dizi(u8,2080); h2:=yerel_dizi(u8,128);
    G:=yerel_dizi(u64,8); X:=yerel_dizi(u64,64); Y:=yerel_dizi(u64,24);
    s8_girdi(k,d,adres(x),adres(G),adres(X),adres(Y));
    eğer s8_S>0 { s8_atla(k,adres(G),adres(Y),adres(x)); } bk:=s8_kova(k);
    eğer s8_gerilim { bk=enaz(3,(bit_say(i64(dolu(k)))-1)/8)*2+seç((G[1-k.sıra]|G[3-k.sıra])!=u64(0),1,0); }
    eğer s8_çapa { bk=0; }
    eğer T_ÖNPAKET_AVX2 && s8_çift_etkin { s8_baş_çift32_16(adres(x),adres(h2),bk); }
    yoksa { s8_baş(adres(x),adres(h2),bk); }
    a:=adres_ekle(d,k.sıra*s8_BK); b:=adres_ekle(d,(1-k.sıra)*s8_BK);
    eğer s8_çapa {
        z4:=yerel_dizi(i64,4); evre:=enaz(30,ençok(0,bit_say(i64(dolu(k)))-2)); alt:=evre/10; pay:=evre%10;
        yinele(j:=alt;j<=enaz(3,alt+1);j+=1) {
            z4[j]=i64(nokta_u8_i8_i32(adres(h2),adres_ekle(ağ,s8_WO+j*32),32))+i64(i32_oku(adres_ekle(ağ,s8_BO),j))+
                  32*(i64(i32_oku(a,s8_PQ+j))-i64(i32_oku(b,s8_PQ+j)));
        }
        cp4:=((10-pay)*z4[alt]+pay*z4[enaz(3,alt+1)])*ölçek/(10*255*64);
        dön enaz(24000,ençok(-24000,cp4));
    }
    z:=i64(nokta_u8_i8_i32(adres(h2),adres_ekle(ağ,s8_WO+bk*2*s8_L2),2*s8_L2))+i64(i32_oku(adres_ekle(ağ,s8_BO),bk))+
       32*(i64(i32_oku(a,s8_PQ+bk))-i64(i32_oku(b,s8_PQ+bk)));

    eğer s8_hata { i32_yaz(d,s8_PQ+12,i32(i64(nokta_u8_i8_i32(adres(h2),adres_ekle(ağ,s8_WE+bk*2*s8_L2),2*s8_L2))+i64(i32_oku(adres_ekle(ağ,s8_BE),bk)))); }
    cp:=z*ölçek/(255*64);
    dön enaz(24000,ençok(-24000,cp));
}
işlev s8_değeri(k:Konum,d:adres):i64 { dön s8_değeri_ölçekli(k,d,400); }
işlev s8_adresler(h:adres) {
    s8_çapa=seç(u32_oku(h,2)==u32(2),1,0);
    s8_R=i64(u32_oku(h,10)); bay:=i64(u32_oku(h,11)); s8_relset=bay&255; s8_hata=(bay>>8)&1; s8_rel_süz=(bay>>10)&3; s8_direkt=s8_relset&1; s8_asılı=(s8_relset>>1)&1; s8_gerilim=(s8_relset>>4)&1; s8_asılı2=(s8_relset>>3)&1; s8_klasik=(s8_relset>>5)&1; s8_klasik2=(s8_relset>>6)&1; s8_rakip_yalnız=(s8_relset>>7)&1;
    s8_A=i64(u32_oku(h,5)); s8_AB=2*s8_A; s8_H=s8_A/2; s8_BK=s8_AB+64; s8_PQ=s8_H; s8_TRO=2*s8_BK;
    s8_L1=i64(u32_oku(h,7));
    s8_RK=seç(((bay>>16)&255)==0,s8_A,((bay>>16)&255)*16); s8_S=((bay>>24)&255)*8; s8_AX=s8_A+s8_S;
    s8_rel_bayt=seç((bay&512)!=0,1,2);
    s8_PSQ=i64(u32_oku(h,9));
    o:=s8_PSQ*s8_AB; s8_REL=o; o+=s8_R*s8_RK*s8_rel_bayt; s8_BIAS=o; o+=s8_AB; s8_PSQT=o; o+=s8_PSQ*16;
    s8_L2=i64(u32_oku(h,8));
    s8_W1=o; o+=8*s8_L1*s8_AX; s8_B1=o; o+=8*s8_L1*4; s8_W2=o; o+=8*s8_L2*2*s8_L1; s8_B2=o; o+=8*s8_L2*4;
    s8_WO=o; o+=8*2*s8_L2; s8_BO=o; o+=8*4;
    eğer s8_hata { s8_WE=o; o+=8*2*s8_L2; s8_BE=o; o+=8*4; }
    s8_BAYT=o;
}
işlev s8_başlık_denetle(h:adres):i64 {
    eğer (u32_oku(h,2)!=u32(1) && u32_oku(h,2)!=u32(2)) || u32_oku(h,3)>u32(1) || (u32_oku(h,5)!=u32(256) && u32_oku(h,5)!=u32(384) && u32_oku(h,5)!=u32(512) && u32_oku(h,5)!=u32(768) && u32_oku(h,5)!=u32(1024) && u32_oku(h,5)!=u32(1536) && u32_oku(h,5)!=u32(2048) && !(u32_oku(h,2)==u32(2) && (u32_oku(h,5)==u32(832) || u32_oku(h,5)==u32(896)))) || u32_oku(h,6)!=u32(8) ||
          (u32_oku(h,7)!=u32(16) && u32_oku(h,7)!=u32(32) && u32_oku(h,7)!=u32(64) && u32_oku(h,7)!=u32(128)) || (u32_oku(h,8)!=u32(16) && u32_oku(h,8)!=u32(32) && u32_oku(h,8)!=u32(64)) || (u32_oku(h,9)!=u32(12288) && u32_oku(h,9)!=u32(24576)) || u64_oku(h,7)!=u64(0) {
        hata("TNN-S8 mimari basligi gecersiz"); dön -1;
    }
    s8_adresler(h);

    eğer s8_S!=0 && s8_S!=32 { hata("TNN-S8: klasik giris uzunlugu 0 veya 32 olmali"); dön -1; }
    eğer s8_RK>s8_A { hata("TNN-S8: iliski genisligi govdeyi asamaz"); dön -1; }
    tr_kur();
    eğer s8_çapa && (s8_A!=768+s8_RK || (s8_RK!=64 && s8_RK!=128 && s8_RK!=256) || s8_L1!=32 || s8_L2!=16 || s8_PSQ!=12288 || s8_relset!=3 || s8_hata || s8_S!=0 || s8_rel_süz!=0 || s8_rel_bayt!=1) {
        hata("TNN-S8 v2: K768-R ortak bas mimarisi gecersiz"); dön -1;
    }
    s8_HB=seç(s8_direkt!=0,tr_çift*12,0);
    s8_HB2=s8_HB+seç(s8_asılı!=0,1536,0);
    s8_HB3=s8_HB2+seç(s8_asılı2!=0,3072,0); s8_geçer_kur();
    s8_HB4=s8_HB3+seç(s8_klasik!=0,288,0);
    eğer (s8_relset&~251)!=0 || s8_R!=s8_HB4+seç(s8_klasik2!=0,152,0) { hata("TNN-S8: relset 0..3 (dogrudan iliski, tehdit durumu) desteklenir"); dön -1; }
    eğer i64(u32_oku(h,4))!=s8_BAYT { hata("TNN-S8 govde uzunlugu baslikla uyusmuyor"); dön -1; }
    deneme:=i64(u32_oku(h,3));
    eğer deneme && !deneme_izni { hata("egitilmemis deneme agi icin AllowTestNet=true gerekli"); dön -1; }
    dön deneme;
}

tablo s8_avx2_model_pi:u16[448]={
    146,203,265,364,433,95,330,190,175,411,97,107,119,291,189,395,
    441,210,237,345,121,312,104,292,384,326,281,510,475,164,89,222,
    304,467,298,397,317,294,385,82,191,287,396,105,402,351,168,131,
    353,344,493,454,130,69,496,459,88,303,398,347,449,300,238,346,
    349,371,367,319,103,170,328,162,380,329,461,134,262,160,183,225,
    85,239,406,471,357,125,358,431,350,270,479,372,78,157,482,75,
    176,233,477,399,478,171,279,311,161,106,339,377,379,434,445,165,
    466,102,67,229,77,251,318,428,153,143,334,307,174,140,429,485,
    267,110,137,439,260,188,154,145,118,213,221,271,66,309,438,218,
    99,435,381,83,480,400,368,501,269,71,231,295,93,115,132,416,
    424,258,200,305,184,494,249,331,241,458,122,194,108,423,327,220,
    425,91,490,388,504,116,492,186,90,163,447,275,342,412,413,123,
    502,341,207,484,158,284,457,201,322,113,391,403,325,437,443,206,
    252,169,127,500,124,226,472,390,495,414,129,378,70,80,314,248,
    195,208,470,286,135,288,440,290,488,187,483,509,448,199,289,503,
    283,499,465,373,178,111,232,257,92,217,511,148,332,333,147,256,
    74,320,335,142,422,316,436,442,370,285,340,255,173,476,455,310,
    68,86,389,491,141,204,417,139,453,308,375,236,324,408,81,216,
    185,361,253,506,120,263,246,277,273,360,321,138,446,451,261,72,
    250,374,181,192,393,299,247,323,382,228,126,343,313,354,264,278,
    272,159,432,240,348,215,336,392,366,430,473,266,197,180,468,112,
    505,355,224,315,383,464,100,133,114,489,387,151,487,427,149,359,
    244,407,117,73,306,415,460,235,280,276,243,296,337,211,420,209,
    452,418,196,409,167,405,87,96,198,376,150,297,219,508,193,293,
    419,76,223,242,64,179,172,469,274,302,128,444,144,410,84,177,
    98,338,268,463,65,282,205,363,356,401,234,259,152,245,79,456,
    101,497,426,254,352,156,109,182,486,369,386,394,498,404,362,450,
    94,474,227,212,301,166,214,421,155,507,230,462,202,481,365,136
};
tablo s8_avx2_rel_pi:u8[64]={
    28,21,60,45,27,19,47,18,34,7,0,31,23,40,51,26,
    50,38,6,48,62,13,14,44,9,41,1,25,39,3,5,29,
    52,37,43,54,20,53,30,16,32,10,11,2,58,42,24,22,
    8,35,12,63,4,46,15,36,49,56,33,59,61,57,55,17
};
işlev s8_kanal_düzenle(parmakizi:u64) {
    eğer s8_ph<=0 { dön 0; }
    say:=yerel_dizi(i64,1024); pi:=yerel_dizi(i64,1024);
    yinele(j:=0;j<s8_H;j+=1) { pi[j]=j; }
    eğer parmakizi==u64(0x846eeeec37a8e4bb) && s8_A==1024 && s8_L1==32 && s8_L2==16 && s8_ph==64 && s8_AX==1024 {
        yinele(j:=64;j<512;j+=1) { pi[j]=i64(s8_avx2_model_pi[j-64]); }
        eğer s8_RK==128 && s8_rel_bayt==2 { yinele(j:=0;j<64;j+=1) { pi[j]=i64(s8_avx2_rel_pi[j]); } }
    } yoksa {
        bellek_sıfırla(adres(say),8192);
        k:=yerel(Konum); l:=yerel(Hamleler); g:=yerel(İz);
        x:=yerel_dizi(u8,4096); G:=yerel_dizi(u64,8); X:=yerel_dizi(u64,64); Y:=yerel_dizi(u64,24);
        metin:=yerel_dizi(u8,128); sözcük:=yerel_dizi(u64,6);
        tohum:u64:=u64(0x544b4348414e4e4c);
        yinele(i:=0;i<1024;i+=1) {
            eğer i%64==0 {
                bellek_kopyala(adres(metin),"rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",57);
                sözcüklere_böl(adres(metin),adres(sözcük),6); fen_oku(k,adres(sözcük));
            }
            s8_girdi(k,adres(k.öz),adres(x),adres(G),adres(X),adres(Y));
            yinele(j:=s8_ph;j<s8_H;j+=1) { say[j]+=(x[j]!=u8(0))+(x[j+s8_H]!=u8(0)); }
            yasal_hamleler(k,l);
            eğer l.adet!=0 { ilerle(k,i64(l.hamle[i64(rastgele64(&tohum)%u64(l.adet))]),g); }
        }
        yinele(j:=s8_ph+1;j<s8_H;j+=1) {
            v:=pi[j]; i:=j;
            iken i>s8_ph && say[pi[i-1]]<say[v] { pi[i]=pi[i-1]; i-=1; }
            pi[i]=v;
        }
    }
    tmp:=yerel_dizi(i16,2048);
    yinele(f:=0;f<=s8_PSQ;f+=1) {
        p:=adres_ekle(ağ,seç(f==s8_PSQ,s8_BIAS,f*s8_AB));
        bellek_kopyala(adres(tmp),p,s8_AB);
        yinele(j:=0;j<s8_ph;j+=1) { i16_yaz(p,j,tmp[pi[j]]); i16_yaz(p,j+s8_ph,tmp[pi[j]+s8_ph]); }
        yinele(j:=s8_ph;j<s8_H;j+=1) {
            i16_yaz(p,j+s8_ph,tmp[pi[j]+s8_ph]);
            i16_yaz(p,j+s8_H,tmp[pi[j]+s8_H]);
        }
    }

    rel_kimlik:=1; yinele(j:=0;j<s8_ph;j+=1) { eğer pi[j]!=j { rel_kimlik=0; } }
    eğer !rel_kimlik && s8_rel_bayt==2 && s8_RK==2*s8_ph {
        yinele(r:=0;r<s8_R;r+=1) {
            p:=adres_ekle(ağ,s8_REL+r*s8_RK*2); bellek_kopyala(adres(tmp),p,s8_RK*2);
            yinele(j:=0;j<s8_ph;j+=1) { i16_yaz(p,j,tmp[pi[j]]); i16_yaz(p,j+s8_ph,tmp[pi[j]+s8_ph]); }
        }
    }
    w:=yerel_dizi(i8,4096);
    yinele(r:=0;r<8*s8_L1;r+=1) {
        p:=adres_ekle(ağ,s8_W1+r*s8_AX); bellek_kopyala(adres(w),p,s8_AX);
        yinele(j:=0;j<s8_H;j+=1) {
            i8_yaz(p,j,w[pi[j]]); i8_yaz(p,j+s8_H,w[pi[j]+s8_H]);
        }
    }
}

yapı S8Tanım {
    R:i64; relset:i64; hata:i64; rel_süz:i64;
    direkt:i64; asılı:i64; gerilim:i64; asılı2:i64;
    klasik:i64; klasik2:i64; rakip_yalnız:i64; A:i64;
    AB:i64; H:i64; BK:i64; PQ:i64;
    TRO:i64; L1:i64; RK:i64; S:i64;
    AX:i64; rel_bayt:i64; PSQ:i64; REL:i64;
    BIAS:i64; PSQT:i64; L2:i64; W1:i64;
    B1:i64; W2:i64; B2:i64; WO:i64;
    BO:i64; WE:i64; BE:i64; BAYT:i64;
    HB:i64; HB2:i64; HB3:i64; HB4:i64; çapa:i64;
}
işlev s8_tanım_sakla(d:S8Tanım) {
    d.R=s8_R; d.relset=s8_relset; d.hata=s8_hata; d.rel_süz=s8_rel_süz;
    d.direkt=s8_direkt; d.asılı=s8_asılı; d.gerilim=s8_gerilim; d.asılı2=s8_asılı2;
    d.klasik=s8_klasik; d.klasik2=s8_klasik2; d.rakip_yalnız=s8_rakip_yalnız; d.A=s8_A;
    d.AB=s8_AB; d.H=s8_H; d.BK=s8_BK; d.PQ=s8_PQ;
    d.TRO=s8_TRO; d.L1=s8_L1; d.RK=s8_RK; d.S=s8_S;
    d.AX=s8_AX; d.rel_bayt=s8_rel_bayt; d.PSQ=s8_PSQ; d.REL=s8_REL;
    d.BIAS=s8_BIAS; d.PSQT=s8_PSQT; d.L2=s8_L2; d.W1=s8_W1;
    d.B1=s8_B1; d.W2=s8_W2; d.B2=s8_B2; d.WO=s8_WO;
    d.BO=s8_BO; d.WE=s8_WE; d.BE=s8_BE; d.BAYT=s8_BAYT;
    d.HB=s8_HB; d.HB2=s8_HB2; d.HB3=s8_HB3; d.HB4=s8_HB4; d.çapa=s8_çapa;
}
işlev s8_tanım_geri_al(d:S8Tanım) {
    s8_R=d.R; s8_relset=d.relset; s8_hata=d.hata; s8_rel_süz=d.rel_süz;
    s8_direkt=d.direkt; s8_asılı=d.asılı; s8_gerilim=d.gerilim; s8_asılı2=d.asılı2;
    s8_klasik=d.klasik; s8_klasik2=d.klasik2; s8_rakip_yalnız=d.rakip_yalnız; s8_A=d.A;
    s8_AB=d.AB; s8_H=d.H; s8_BK=d.BK; s8_PQ=d.PQ;
    s8_TRO=d.TRO; s8_L1=d.L1; s8_RK=d.RK; s8_S=d.S;
    s8_AX=d.AX; s8_rel_bayt=d.rel_bayt; s8_PSQ=d.PSQ; s8_REL=d.REL;
    s8_BIAS=d.BIAS; s8_PSQT=d.PSQT; s8_L2=d.L2; s8_W1=d.W1;
    s8_B1=d.B1; s8_W2=d.W2; s8_B2=d.B2; s8_WO=d.WO;
    s8_BO=d.BO; s8_WE=d.WE; s8_BE=d.BE; s8_BAYT=d.BAYT;
    s8_HB=d.HB; s8_HB2=d.HB2; s8_HB3=d.HB3; s8_HB4=d.HB4; s8_çapa=d.çapa;
}
işlev s8_dosyadan(f:dosya,h:adres):i64 {
    önce:=yerel(S8Tanım); s8_tanım_sakla(önce); başarı:=0;
    ertele { eğer !başarı { s8_tanım_geri_al(önce); } }
    deneme:=s8_başlık_denetle(h); eğer deneme<0 { dön 0; }
    p:=büyük_ayır(s8_BAYT+64); eğer p==0 { hata("ag bellegi ayrilamadi"); dön 0; }
    son:=yerel_dizi(u8,1);
    eğer dosya_oku(p,s8_BAYT,f)!=s8_BAYT || dosya_oku(adres(son),1,f)!=0 || dosya_hata(f)!=0 {
        hizalı_bırak(p); hata("TNN-S8 uzunluk gecersiz"); dön 0;
    }
    başarı=s8_kur(h,p,deneme,0); dön başarı;
}

işlev s8_bellekten(h:adres,sessiz:i64):i64 {
    önce:=yerel(S8Tanım); s8_tanım_sakla(önce); başarı:=0;
    ertele { eğer !başarı { s8_tanım_geri_al(önce); } }
    deneme:=s8_başlık_denetle(h); eğer deneme<0 { dön 0; }
    eğer s8_BAYT>GÖMÜLÜ_BAYT { hata("TNN-S8 gomulu tablodan buyuk"); dön 0; }
    p:=büyük_ayır(s8_BAYT+64); eğer p==0 { hata("ag bellegi ayrilamadi"); dön 0; }
    bellek_kopyala(p,adres_ekle(h,64),s8_BAYT);
    başarı=s8_kur(h,p,deneme,sessiz); dön başarı;
}

işlev s8_kur(h:adres,p:adres,deneme:i64,sessiz:i64):i64 {
    eğer ağ_parmakizi(p,s8_BAYT)!=u64_oku(h,6) { hizalı_bırak(p); hata("TNN-S8 ozet gecersiz"); dön 0; }

    psqt_eksi:=hizalı_ayır(s8_PSQ*32,64);
    eğer psqt_eksi==0 { hizalı_bırak(p); hata("ag PSQT bellegi ayrilamadi"); dön 0; }

    yinele(i:=0;i<s8_PSQ*8;i+=1) { i32_yaz(psqt_eksi,i,i32(-i64(i16_oku(adres_ekle(p,s8_PSQT),i)))); }
    ağı_bırak();
    ağ=p; ağ_türü=2; deneme_ağı=deneme;
    eğer s8_psqt_eksi!=0 { hizalı_bırak(s8_psqt_eksi); }
    s8_psqt_eksi=psqt_eksi;

    s8_toplu_etkin=s8_rel_bayt==2 && s8_RK<=s8_A && (işlemci_özellikleri()&u64(36))!=u64(0);
    s8_ph=0;
    eğer s8_R>0 && s8_RK<s8_A {
        s8_ph=s8_RK/2;
        yinele(f:=0;f<s8_PSQ;f+=1) { s8_sırala(adres_ekle(ağ,f*s8_AB),s8_ph); }
        s8_sırala(adres_ekle(ağ,s8_BIAS),s8_ph);
    }

    s8_rel_hızlı=seç(s8_RK==s8_A || s8_ph>0,1,0);
    s8_kanal_düzenle(u64_oku(h,6));
    kn_blok_etkin=(işlemci_özellikleri()&u64(65))!=u64(0);
    eğer kn_blok_etkin {
        yinele(bk:=0;bk<8;bk+=1) {
            kn_paketle(adres_ekle(adres(s8_w1p),bk*s8_L1*s8_AX),adres_ekle(adres(s8_b1p),bk*s8_L1*4),adres_ekle(ağ,s8_W1+bk*s8_L1*s8_AX),adres_ekle(ağ,s8_B1+bk*s8_L1*4),s8_AX,s8_L1);
            kn_paketle(adres_ekle(adres(s8_w2p),bk*s8_L2*2*s8_L1),adres_ekle(adres(s8_b2p),bk*s8_L2*4),adres_ekle(ağ,s8_W2+bk*s8_L2*2*s8_L1),adres_ekle(ağ,s8_B2+bk*s8_L2*4),2*s8_L1,s8_L2);
        }
    }
    yinele(m:=0;m<256;m+=1) {
        adet:=0; yinele(j:=0;j<8;j+=1) { s8_indis_tablo[m*8+j]=u16(0); }
        yinele(j:=0;j<8;j+=1) { eğer (m&(1<<j))!=0 { s8_indis_tablo[m*8+adet]=u16(j); adet+=1; } }
    }
    s8_grup_etkin=(işlemci_özellikleri()&u64(580))!=u64(0);

    s8_çift_etkin=T_ÖNPAKET_AVX2 && s8_L1==32 && s8_L2==16 && (işlemci_özellikleri()&u64(4))!=u64(0);

    eğer T_AVX_VNNI && (işlemci_özellikleri()&u64(4096))!=u64(0) { s8_çift_etkin=0; }
    eğer T_ÖNPAKET_AVX2 && s8_çift_etkin {
        yinele(bk:=0;bk<8;bk+=1) {
            eğer s8_L2==16 { s8_çift_paketle(adres_ekle(adres(s8_w2ç),bk*s8_L2*2*s8_L1*2),adres_ekle(ağ,s8_W2+bk*s8_L2*2*s8_L1),2*s8_L1,s8_L2); }
        }
    }
    yinele(bk:=0;bk<8;bk+=1) {
        yinele(i:=0;i<s8_AX;i+=1) { yinele(o:=0;o<s8_L1;o+=1) {
            v:=i8_oku(adres_ekle(ağ,s8_W1+bk*s8_L1*s8_AX),o*s8_AX+i);
            i8_yaz(adres(s8_w1s),(bk*s8_AX+i)*s8_L1+o,v);
            i8_yaz(adres(s8_w1g),bk*s8_AX*s8_L1+((i/4)*s8_L1+o)*4+i%4,v);
        } }
    }
    eğer T_ÖNPAKET_AVX2 && s8_çift_etkin {
        yinele(bk:=0;bk<8;bk+=1) {
            s8_karma_paketle(adres_ekle(adres(s8_karma_ptr),bk*s8_AX*2),adres_ekle(adres(s8_w1g),bk*s8_AX*32),adres_ekle(adres(s8_w1ç),bk*s8_AX*64),s8_AX);
        }
    }

    bellek_sıfırla(adres(oyun.öz),DURUM_BOYU);
    s8_tazele(oyun);
    eğer !sessiz { metin_satırı("info string TNN-S8 agi yuklendi"); }
    dön 1;
}
işlev ağ_tazele(k:Konum) { s8_tazele(k); }

işlev konumu_denetle(k:Konum):i64 {
    eğer k.anahtar!=konum_anahtarı(k) { dön 0; }
    deneme:=yerel(Konum); bellek_sıfırla(adres(deneme),boyut(Konum));
    yinele(s:=0;s<64;s+=1) { eğer k.tahta[s]!=u8(0) { taş_koy(deneme,s,i64(k.tahta[s])); } }
    eğer ağ!=0 { ağ_tazele(deneme); }
    eğer bellek_karşılaştır(adres(k.bit_tahtası),adres(deneme.bit_tahtası),104)!=0 ||
        bellek_karşılaştır(adres(k.renkler),adres(deneme.renkler),16)!=0 ||
        bellek_karşılaştır(adres(k.şah),adres(deneme.şah),16)!=0 { dön 0; }

    eğer ağ!=0 && k.ağ_etkin && bellek_karşılaştır(adres(k.öz),adres(deneme.öz),DURUM_BOYU)!=0 { dön 0; }
    dön 1;
}

yapı Önbellek {
    anahtar:u64; pv:i64; boş:i64; derinlik:i32; puan:i32; hamle:i64; sınır:i64; değer:i32; değeri_var:i32; nesil:i64;
}

yapı ÖnbellekKaydı { anahtar:u32; hamle:u16; puan:i16; değer:i16; derinlik:u8; bilgi:u8; nesil:u8; dolgu:u8; boş:u16; }
yapı ÖnbellekKümesi { kilit:i64; kayıt:u8[48]; dolgu:u8[8]; }
genel ortak_bellek:adres=0;
genel bellek_kümesi:i64=0; genel bellek_boyutu:i64=0; genel bellek_nesli:i64=0;
işlev önbelleği_bırak() {
    eğer bellek_kümesi!=0 { hizalı_bırak(ortak_bellek); }
    ortak_bellek=0; bellek_kümesi=0; bellek_boyutu=0;
}
işlev önbelleği_temizle() {
    eğer bellek_kümesi!=0 { bellek_sıfırla(ortak_bellek,bellek_kümesi*boyut(ÖnbellekKümesi)); }
    bellek_nesli=0;
}
işlev önbelleği_kur():i64 {
    eğer bellek_boyutu!=bellek_mb {
        önbelleği_bırak(); n:=bellek_mb*1048576/boyut(ÖnbellekKümesi);
        ortak_bellek=büyük_ayır(n*boyut(ÖnbellekKümesi));
        eğer ortak_bellek==0 { dön 0; }
        bellek_kümesi=n; bellek_boyutu=bellek_mb; önbelleği_temizle();
    }
    bellek_nesli+=1; dön 1;
}
işlev önbellekten_oku(k:Konum,q:Önbellek):i64 {
    q.sınır=0;
    c:=gör(ÖnbellekKümesi,adres_ekle(ortak_bellek,i64(çarp_yüksek_u64(k.anahtar,u64(bellek_kümesi)))*boyut(ÖnbellekKümesi)));
    kilitli:=işçi_sayısı>1;
    eğer kilitli && atomik_kıyas_değiştir(&c.kilit,0,1)!=0 { dön 0; }
    kısa:=u32(k.anahtar&u64(0xffffffff));
    yinele(i:=0;i<3;i+=1) {
        r:=gör(ÖnbellekKaydı,adres_ekle(adres(c.kayıt),i*16)); bilgi:=i64(r.bilgi);
        eğer (bilgi&3)!=0 && r.anahtar==kısa {
            q.anahtar=k.anahtar; q.pv=(bilgi>>2)&1; q.boş=0; q.derinlik=i32(i64(r.derinlik)); q.puan=i32(i64(r.puan));
            q.hamle=i64(r.hamle); q.sınır=bilgi&3; q.değer=i32(i64(r.değer)); q.değeri_var=i32((bilgi>>3)&1); q.nesil=i64(r.nesil);
            r.nesil=u8(bellek_nesli&255); kır;
        }
    }
    eğer kilitli { atomik_yaz(&c.kilit,0); } dön q.sınır!=0;
}
yapı Kök { hamle:i64; puan:i64; bitti:i64; kesin:i64; yol:i64[128]; uzunluk:i64; }

yapı DeğerYuva { anahtar:u64; puan:i32; sıra:i32; tahta:u8[64]; }
sabit DEĞER_YUVA=4096;
yapı Arayıcı {
    konum:Konum; kök:Kök[]; biten:Kök[]; sıra:i64[512]; kimlik:i64; derinlik:i64; alt:i64; üst:i64; biten_derinlik:i64; biten_seçilen:i64;
    biriken_düğüm:i64; seçilen_derinlik:i64; boş_yasak:i64; budadı:i64[8]; özdeğer:i32[128]; özgeçerli:u8[128]; önceki:i64[128]; karşılık:i32[8192];
    geçmiş:i32[8192]; katiller:i64[256]; yol:i64[16384]; uzunluk:i64[128];

    değer_belleği:adres; durumlar:adres; yenileme:adres; durum_geçerli:u8[AZAMİ_KAT]; izler:İz[];

    durum_adres:u64[AZAMİ_KAT];

    kök_iz:i64; boş_alt_kat:i64; mat_arıyor:i64; hariç:i64[136]; taş_izi:i64[136]; önceki_av:i64[136]; kesme:i64[136];
    alış_geçmişi:i32[5824]; sürek:adres; düzeltme:i32[32768]; düzeltme_tp:i32[32768]; düzeltme_dv:i32[1536]; sayaç:i64; kök_düğüm:i64[512];
}

yapı Sürek { v1:i16[692224]; v2:i16[692224]; }

sabit AZAMİ_İŞÇİ=512;
genel kalıcı_geçmiş:i32[AZAMİ_İŞÇİ*8192]; genel kalıcı_karşılık:i32[AZAMİ_İŞÇİ*8192]; genel kalıcı_alış:i32[AZAMİ_İŞÇİ*5824]; genel kalıcı_sürek:adres=0; genel kalıcı_düzeltme:i32[AZAMİ_İŞÇİ*32768]; genel kalıcı_düzeltme_tp:i32[AZAMİ_İŞÇİ*32768]; genel kalıcı_düzeltme_dv:i32[AZAMİ_İŞÇİ*1536];

işlev düzeltme_indisi(k:Konum):i64 {
    h:u64:=k.bit_tahtası[1]*u64(0x9E3779B97F4A7C15)+k.bit_tahtası[7]*u64(0xC2B2AE3D27D4EB4F);
    h=h^(h>>u64(31)); h=h*u64(0xD6E8FEB86659FD93);
    dön k.sıra*16384+i64((h>>u64(50))&u64(16383));
}

işlev taş_indisi(k:Konum,c:i64):i64 {
    b:=c*6; h:u64:=k.bit_tahtası[b+2]*u64(0x9E3779B97F4A7C15)+k.bit_tahtası[b+3]*u64(0xC2B2AE3D27D4EB4F)+k.bit_tahtası[b+4]*u64(0x165667B19E3779F9)+k.bit_tahtası[b+5]*u64(0xD6E8FEB86659FD93)+k.bit_tahtası[b+6]*u64(0x27D4EB2F165667C5);
    h=h^(h>>u64(29)); h=h*u64(0xBF58476D1CE4E5B9); h=h^(h>>u64(32));
    dön c*16384+k.sıra*8192+i64(h&u64(8191));
}

işlev dv_indisi(a:Arayıcı,k:Konum,kat:i64):i64 {
    h:=a.önceki[kat]; eğer h==0 || kat<1 { dön -1; }
    dön k.sıra*768+(a.taş_izi[kat]-1)*64+hedef(h);
}
işlev düzelt(a:Arayıcı,k:Konum,öz:i64,kat:i64):i64 {
    eğer !budama { dön öz; }
    t:=ay[66]*i64(a.düzeltme[düzeltme_indisi(k)])+ay[67]*(i64(a.düzeltme_tp[taş_indisi(k,0)])+i64(a.düzeltme_tp[taş_indisi(k,1)]));
    eğer ay[75]!=0 { j:=dv_indisi(a,k,kat); eğer j>=0 { t+=ay[75]*i64(a.düzeltme_dv[j]); } }
    v:=öz+t/65536; dön seç(v < -24000,-24000,seç(v>24000,24000,v));
}
işlev düzeltme_yaz(a:Arayıcı,k:Konum,fark:i64,derinlik:i64,kat:i64) {
    eğer !budama { dön 0; }
    i:=düzeltme_indisi(k); w:=enaz(derinlik+1,16); fark=seç(fark < -1024,-1024,seç(fark>1024,1024,fark));
    v:=(i64(a.düzeltme[i])*(256-w)+fark*128*w)/256; a.düzeltme[i]=i32(seç(v < -131072,-131072,seç(v>131072,131072,v)));
    yinele(c:=0;c<2;c+=1) {
        j:=taş_indisi(k,c); u:=(i64(a.düzeltme_tp[j])*(256-w)+fark*128*w)/256; a.düzeltme_tp[j]=i32(seç(u < -131072,-131072,seç(u>131072,131072,u)));
    }
    eğer ay[75]!=0 { j:=dv_indisi(a,k,kat); eğer j>=0 { u:=(i64(a.düzeltme_dv[j])*(256-w)+fark*128*w)/256; a.düzeltme_dv[j]=i32(seç(u < -131072,-131072,seç(u>131072,131072,u))); } }
}
genel süre_optimum:i64=-1; genel süre_azami:i64=-1; genel kararlı_hamle:i64=0; genel kararlı_sayı:i64=0;
genel saat_yönetimi:i64=0; genel hamle_gecikmesi:i64=100;

işlev saat_bütçesi(kalan:i64,ek:i64,hamle_kaldı:i64,rakip_kalan:i64) {

    ufuk:=seç(hamle_kaldı>0,hamle_kaldı,seç(ek>0,ay[50],ay[74])); yedek:=0;
    eğer hamle_kaldı==0 && ek==0 { yedek=enaz(kalan/2,ençok(1000,hamle_gecikmesi*12)); }

    pay:=ençok(1,((kalan-yedek)/ufuk-hamle_gecikmesi+ek*ay[51]/100)*ay[62]/100);
    eğer hamle_kaldı!=1 && rakip_kalan>kalan {
        indirim:=enaz(ay[52],100-kalan*100/rakip_kalan); pay=pay*(100-indirim)/100;
    }
    mevcut:=ençok(1,kalan-enaz(kalan,hamle_gecikmesi)-yedek);
    tavan:=seç(hamle_kaldı==1,mevcut,ençok(1,mevcut*ay[54]/100));
    süre_optimum=ençok(1,enaz(pay,tavan)); süre_azami=enaz(tavan,süre_optimum*ay[53]/100);
    eğer kök_sayısı==1 { süre_optimum=1; süre_azami=ençok(1,enaz(süre_azami,10)); }
}
işlev saat_turu_bitti(d:i64,h:i64,önceki:i64,puan:i64,geçen:i64,tur:i64,önceki_tur:i64,pay_binde:i64):i64 {
    eğer h==kararlı_hamle { kararlı_sayı+=1; } yoksa { kararlı_hamle=h; kararlı_sayı=0; }
    çarpan:=100; eğer kararlı_sayı>=4 { çarpan=ay[55]; } yoksa eğer kararlı_sayı>=2 { çarpan=ay[56]; }
    eğer d>=6 && önceki-puan>ay[57] { çarpan=çarpan*ay[58]/100; }

    eğer ay[60]>0 && pay_binde>=0 && d>=6 { çarpan=çarpan*ençok(30,ay[60]-ay[61]*pay_binde/1000)/100; }
    hedef:=ençok(1,enaz(süre_azami,süre_optimum*çarpan/100));
    eğer geçen>=hedef { dön 1; }

    eğer d>=5 && önceki_tur>0 && geçen>=hedef/2 {
        büyüme:=enaz(400,ençok(150,tur*100/önceki_tur)); tahmin:=tur*büyüme/100;
        eğer geçen+tahmin>hedef*ay[59]/100 { dön 1; }
    }
    dön 0;
}
işlev kalıcı_sürek_al(i:i64):adres {
    eğer kalıcı_sürek==0 { kalıcı_sürek=bellek_ayır(AZAMİ_İŞÇİ*8); eğer kalıcı_sürek==0 { dön 0; } bellek_sıfırla(kalıcı_sürek,AZAMİ_İŞÇİ*8); }
    p:=adres_oku(kalıcı_sürek,i);
    eğer p==0 { p=büyük_ayır(boyut(Sürek)); eğer p!=0 { bellek_sıfırla(p,boyut(Sürek)); adres_yaz(kalıcı_sürek,i,p); } }
    dön p;
}
işlev geçmişleri_temizle() {

    n:=ençok(işçi_sayısı,en_çok_işçi);
    bellek_sıfırla(adres(kalıcı_geçmiş),n*8192*4); bellek_sıfırla(adres(kalıcı_karşılık),n*8192*4); bellek_sıfırla(adres(kalıcı_alış),n*5824*4); bellek_sıfırla(adres(kalıcı_düzeltme),n*32768*4); bellek_sıfırla(adres(kalıcı_düzeltme_tp),n*32768*4); bellek_sıfırla(adres(kalıcı_düzeltme_dv),n*1536*4);
    eğer kalıcı_sürek!=0 { yinele(i:=0;i<AZAMİ_İŞÇİ;i+=1) { p:=adres_oku(kalıcı_sürek,i); eğer p!=0 { bellek_sıfırla(p,boyut(Sürek)); } } }
}
genel kök_konum:Konum;
genel kökler:Kök[512];

genel arayıcılar:Arayıcı[]; genel arayıcı_kapasite:i64=0; genel en_çok_işçi:i64=1;
genel iş_kayıtları:u64[AZAMİ_İŞÇİ];
genel arama_kaydı:u64[1];
genel dur:i64=0; genel kullanıcı_durdu:i64=0;

genel dur_yalıtımı:u8[128];
genel düğümler:i64=0;
genel sayaç_yalıtımı:u8[128];
genel arama_açık:i64=0;
genel işçi_sayısı:i64=1;
genel bellek_mb:i64=16;
genel kök_sayısı:i64=0; genel kök_kısıtlı:i64=0;
genel derinlik_sınırı:i64=126; genel mat_sınırı:i64=0;
genel düğüm_sınırı:i64=0;
genel son_zaman:i64=0;
genel başlangıç_zamanı:i64=0; genel arama_başlangıcı:i64=0;
genel çoklu_varyant:i64=1;
genel sonuç_beklesin:i64=0;
genel rakip_sırası:i64=0;
genel düşünme_süresi:i64=-1;

genel son_raporlar:Kök[256]; genel son_rapor_sayısı:i64=0; genel son_rapor_derinliği:i64=0;
genel rapor_kilidi:i64=0; genel rapor_bitsin:i64=0; genel son_rapor_seçilen:i64=0; genel son_rapor_düğümü:i64=0;

tablo değişim_bedeli:i64[7]={0,100,300,320,500,900,20000};

işlev beraberlik(k:Konum):i64 {
    eğer k.elli>=100 { dön 1; }
    tekrar:=0;
    yinele(i:=k.iz_sayısı-1;i>=k.dönüşsüz;i-=2) { eğer k.geçmiş[i]==k.anahtar { tekrar+=1; } }
    eğer tekrar>=3 { dön 1; }
    dön malzeme_beraberliği(k);
}

işlev arama_beraberliği(a:Arayıcı,k:Konum):i64 {
    eğer k.elli>=100 { dön 1; }
    tekrar:=0;
    yinele(i:=k.iz_sayısı-3;i>=k.dönüşsüz;i-=2) {
        eğer k.geçmiş[i]==k.anahtar { eğer i>=a.kök_iz { dön 1; } tekrar+=1; eğer tekrar>=2 { dön 1; } }
    }
    dön malzeme_beraberliği(k);
}
işlev malzeme_beraberliği(k:Konum):i64 {
    eğer (k.bit_tahtası[1]|k.bit_tahtası[7]|k.bit_tahtası[4]|k.bit_tahtası[10]|k.bit_tahtası[5]|k.bit_tahtası[11])!=u64(0) { dön 0; }
    eğer bit_say(i64(dolu(k)))<=3 { dön 1; }
    eğer (k.bit_tahtası[2]|k.bit_tahtası[8])!=u64(0) { dön 0; }
    filler:=k.bit_tahtası[3]|k.bit_tahtası[9]; açık:=0; koyu:=0;
    iken filler!=u64(0) { s:=ilk_bit(i64(filler)); filler&=filler-u64(1); eğer (s/8+s%8)%2==0 { açık=1; } yoksa { koyu=1; } }
    dön !(açık && koyu);
}
işlev düğümleri_aktar(a:Arayıcı) {
    eğer a.biriken_düğüm!=0 { atomik_ekle(&düğümler,a.biriken_düğüm); a.biriken_düğüm=0; }
}
işlev düğüm_al(a:Arayıcı):i64 {
    a.sayaç+=1;
    eğer düğüm_sınırı==0 {

        eğer a.biriken_düğüm==0 && atomik_oku(&dur) { dön 0; }
        a.biriken_düğüm+=1;
        eğer a.biriken_düğüm<64 { dön 1; }
        düğümleri_aktar(a);
        bitiş:=atomik_oku(&son_zaman);
        eğer bitiş>0 { şimdi:=zaman_ns(); eğer şimdi<0 || şimdi>=bitiş { atomik_yaz(&dur,1); dön 0; } }
        dön 1;
    }

    eğer işçi_sayısı==1 {
        eğer atomik_oku(&dur) { dön 0; }
        eski:=düğümler;
        eğer eski>=düğüm_sınırı { atomik_yaz(&dur,1); dön 0; }
        düğümler=eski+1;
        eğer (eski&63)==0 {
            bitiş:=atomik_oku(&son_zaman);
            eğer bitiş>0 { şimdi:=zaman_ns(); eğer şimdi<0 || şimdi>=bitiş { atomik_yaz(&dur,1); dön 0; } }
        }
        dön 1;
    }
    eğer atomik_oku(&dur) { dön 0; }
    eski:=atomik_ekle(&düğümler,1);
    eğer eski>=düğüm_sınırı {
        atomik_ekle(&düğümler,-1); atomik_yaz(&dur,1); dön 0;
    }
    eğer (eski&63)==0 {
        bitiş:=atomik_oku(&son_zaman);
        eğer bitiş>0 { şimdi:=zaman_ns(); eğer şimdi<0 || şimdi>=bitiş { atomik_yaz(&dur,1); dön 0; } }
    }
    dön 1;
}
işlev alınan_taş(k:Konum,h:i64):i64 {
    eğer hamle_türü(h)==ROK { dön 0; }
    eğer hamle_türü(h)==GEÇERKEN { dön 1; }
    t:=i64(k.tahta[hedef(h)]); dön seç(t==0,0,tür(t));
}
işlev mutlak(x:i64):i64 { dön seç(x<0,-x,x); }

yapı DeğişimTahtası { taş:u64[13]; şah:i64[2]; }
işlev değişim_saldıran(d:DeğişimTahtası,s:i64,r:i64,o:u64):u64 {
    a:=r*6;
    dön ((piyon_alanı[(1-r)*64+s]&d.taş[a+1]) | (at_alanı[s]&d.taş[a+2]) |
        (fil_saldırısı(s,o)&(d.taş[a+3]|d.taş[a+5])) |
        (kale_saldırısı(s,o)&(d.taş[a+4]|d.taş[a+5])) | (şah_alanı[s]&d.taş[a+6]))&o;
}
işlev değişim(k:Konum,h:i64):i64 {
    ht:=hamle_türü(h); eğer ht==ROK { dön 0; }
    a:=kaynak(h); b:=hedef(h); r:=k.sıra; t:=i64(k.tahta[a]); av:=alınan_taş(k,h);

    ilk_kazanç:=değişim_bedeli[av]+seç(ht>=4,değişim_bedeli[ht-2]-100,0);
    o0:=(dolu(k)&~bit(a))|bit(b); x:=(1-r)*6;
    eğer ((piyon_alanı[r*64+b]&k.bit_tahtası[x+1]) | (at_alanı[b]&k.bit_tahtası[x+2]) |
        (fil_saldırısı(b,o0)&(k.bit_tahtası[x+3]|k.bit_tahtası[x+5])) |
        (kale_saldırısı(b,o0)&(k.bit_tahtası[x+4]|k.bit_tahtası[x+5])) | (şah_alanı[b]&k.bit_tahtası[x+6]))==u64(0) { dön ilk_kazanç; }
    d:=yerel(DeğişimTahtası); bellek_kopyala(adres(d.taş),adres(k.bit_tahtası),104);
    d.şah[0]=k.şah[0]; d.şah[1]=k.şah[1]; o:=dolu(k)&~bit(a);
    s:=seç(ht==GEÇERKEN,b+seç(r==0,-8,8),b);
    eğer av!=0 { d.taş[(1-r)*6+av]&=~bit(s); o&=~bit(s); }
    d.taş[t]&=~bit(a); yeni:=seç(ht>=4,r*6+ht-2,t); d.taş[yeni]|=bit(b); o|=bit(b);
    eğer tür(t)==6 { d.şah[r]=b; }
    kazanç:=yerel_dizi(i64,32); kazanç[0]=değişim_bedeli[av]+seç(ht>=4,değişim_bedeli[ht-2]-100,0);
    n:=0; duran:=yeni; r=1-r;
    iken n<30 && tür(duran)!=6 {
        saldıran:=değişim_saldıran(d,b,r,o); seçilen:=-1; alınan:=0; terfi:=0;
        yinele(c:=1;c<=6;c+=1) {
            aday:=saldıran&d.taş[r*6+c];
            iken aday!=u64(0) {
                s=ilk_bit(i64(aday)); aday&=aday-u64(1); kaynak_bit:=bit(s); hedef_bit:=bit(b);
                gelen:=r*6+c; çıkan:=seç(c==1 && b/8==seç(r==0,7,0),r*6+5,gelen);
                d.taş[gelen]&=~kaynak_bit; d.taş[duran]&=~hedef_bit; d.taş[çıkan]|=hedef_bit;
                eski_şah:=d.şah[r]; eğer c==6 { d.şah[r]=b; }
                uygun:=değişim_saldıran(d,d.şah[r],1-r,o&~kaynak_bit)==u64(0);
                d.şah[r]=eski_şah; d.taş[çıkan]&=~hedef_bit; d.taş[duran]|=hedef_bit; d.taş[gelen]|=kaynak_bit;
                eğer uygun { seçilen=s; alınan=gelen; terfi=çıkan; kır; }
            }
            eğer seçilen>=0 { kır; }
        }
        eğer seçilen<0 { kır; }
        n+=1; kazanç[n]=değişim_bedeli[tür(duran)]+değişim_bedeli[tür(terfi)]-değişim_bedeli[tür(alınan)]-kazanç[n-1];
        d.taş[alınan]&=~bit(seçilen); d.taş[duran]&=~bit(b); d.taş[terfi]|=bit(b); o&=~bit(seçilen);
        eğer tür(alınan)==6 { d.şah[r]=b; }
        duran=terfi; r=1-r;
    }
    iken n>0 { kazanç[n-1]=enaz(kazanç[n-1],-kazanç[n]); n-=1; }
    dön kazanç[0];
}

işlev değişim_eşik(k:Konum,h:i64,eşik:i64):i64 {
    ht:=hamle_türü(h); eğer ht==ROK { dön seç(eşik<=0,1,0); }
    a:=kaynak(h); b:=hedef(h); biz:=k.sıra; t:=i64(k.tahta[a]); av:=alınan_taş(k,h);
    s:=değişim_bedeli[av]+seç(ht>=4,değişim_bedeli[ht-2]-100,0)-eşik;
    eğer s<0 { dön 0; }
    o0:=(dolu(k)&~bit(a))|bit(b); x:=(1-biz)*6;
    eğer ((piyon_alanı[biz*64+b]&k.bit_tahtası[x+1]) | (at_alanı[b]&k.bit_tahtası[x+2]) |
        (fil_saldırısı(b,o0)&(k.bit_tahtası[x+3]|k.bit_tahtası[x+5])) |
        (kale_saldırısı(b,o0)&(k.bit_tahtası[x+4]|k.bit_tahtası[x+5])) | (şah_alanı[b]&k.bit_tahtası[x+6]))==u64(0) { dön 1; }
    yeni:=seç(ht>=4,biz*6+ht-2,t);

    terfi_payı:=seç(b/8==0 || b/8==7,800,0);
    eğer s-değişim_bedeli[tür(yeni)]-terfi_payı>=0 { dön 1; }

    P:=adres(k.bit_tahtası); hb:=bit(b);
    o:=dolu(k)&~bit(a);
    s2:=seç(ht==GEÇERKEN,b+seç(biz==0,-8,8),b);
    eğer av!=0 { o&=~bit(s2); }
    o|=hb;
    şah0:=k.şah[0]; şah1:=k.şah[1];
    eğer tür(t)==6 { eğer biz==0 { şah0=b; } yoksa { şah1=b; } }
    n:=0; duran:=yeni; r:=1-biz;
    iken n<30 && tür(duran)!=6 {
        x:=r*6; y:=(1-r)*6;
        saldıran:=((piyon_alanı[(1-r)*64+b]&u64_oku(P,x+1)) | (at_alanı[b]&u64_oku(P,x+2)) |
            (fil_saldırısı(b,o)&(u64_oku(P,x+3)|u64_oku(P,x+5))) |
            (kale_saldırısı(b,o)&(u64_oku(P,x+4)|u64_oku(P,x+5))) | (şah_alanı[b]&u64_oku(P,x+6)))&o;
        K:=seç(r==0,şah0,şah1); canlı:=o&~hb; seçilen:=-1; seçilen_c:=0;
        yinele(c:=1;c<=6;c+=1) {
            aday:=saldıran&u64_oku(P,x+c);
            iken aday!=u64(0) {
                sq:=ilk_bit(i64(aday)); aday&=aday-u64(1);
                occ:=o&~bit(sq); KK:=seç(c==6,b,K);
                tehdit:=((piyon_alanı[r*64+KK]&u64_oku(P,y+1)) | (at_alanı[KK]&u64_oku(P,y+2)) |
                    (fil_saldırısı(KK,occ)&(u64_oku(P,y+3)|u64_oku(P,y+5))) |
                    (kale_saldırısı(KK,occ)&(u64_oku(P,y+4)|u64_oku(P,y+5))) | (şah_alanı[KK]&u64_oku(P,y+6)))&canlı;
                eğer tehdit==u64(0) { seçilen=sq; seçilen_c=c; kır; }
            }
            eğer seçilen>=0 { kır; }
        }
        eğer seçilen<0 { kır; }
        alınan:=x+seçilen_c; terfi:=seç(seçilen_c==1 && b/8==seç(r==0,7,0),x+5,alınan);
        n+=1; kazanç:=değişim_bedeli[tür(duran)]+değişim_bedeli[tür(terfi)]-değişim_bedeli[tür(alınan)];
        eğer r==biz { s+=kazanç; } yoksa { s-=kazanç; }
        o&=~bit(seçilen);
        eğer seçilen_c==6 { eğer r==0 { şah0=b; } yoksa { şah1=b; } }
        duran=terfi; r=1-r;

        eğer r==biz {
            eğer s>=0 { dön 1; }
            eğer s+değişim_bedeli[tür(duran)]+terfi_payı<0 { dön 0; }
        } yoksa {
            eğer s<0 { dön 0; }
            eğer s-değişim_bedeli[tür(duran)]-terfi_payı>=0 { dön 1; }
        }
    }
    dön seç(s>=0,1,0);
}

sabit BUDAMA_TÜM=127;
genel budama:i64=1;

genel dinamik_marj:i64=0; genel dm_lmr:i64=0; genel dm_cp:i64=0; genel dm_orta:i64=0; genel dm_eğim:i64=0; genel dm_alt:i64=40; genel dm_üst:i64=112;
işlev buda(b:i64):i64 { dön budama && (BUDAMA_TÜM&b)!=0; }

genel ay:i64[96]={73,54,12,300,250,3,3,200,200,50,64,131,300,500,1024,2079,1024,512,128,3,8,1904,87,105,25,150,100,200,200,12,134,1500,60,50,180,1024,1024,1024,512,14,5,6,0,0,276,0,50,2,0,0,16,75,40,300,25,65,80,40,150,125,180,120,100,0,200,100,512,256,3,2,4,0,0,0,20,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
tablo ln_tablosu:i64[64]={0,0,177,281,355,412,459,498,532,562,589,614,636,657,676,693,710,725,740,754,767,779,791,803,814,824,834,844,853,862,871,879,887,895,903,910,917,924,931,938,944,951,957,963,969,975,980,986,991,996,1001,1007,1012,1016,1021,1026,1030,1035,1039,1044,1048,1052,1057,1061};
işlev geçmiş_yaz(a:Arayıcı,r:i64,h:i64,ödül:i64) {
    j:=r*4096+kaynak(h)*64+hedef(h); v:=i64(a.geçmiş[j]);
    a.geçmiş[j]=i32(v+ödül-v*mutlak(ödül)/16384);
}
işlev alış_yeri(taş:i64,b:i64,av:i64):i64 { dön (taş*64+b)*7+av; }
işlev alış_geçmişi_yaz(a:Arayıcı,taş:i64,b:i64,av:i64,ödül:i64) {
    j:=alış_yeri(taş,b,av); v:=i64(a.alış_geçmişi[j]);
    a.alış_geçmişi[j]=i32(v+ödül-v*mutlak(ödül)/16384);
}

işlev sürek_yeri(a:Arayıcı,kat:i64,o:i64):i64 {
    j:=kat-o+1; eğer j<1 { dön -1; }
    h:=a.önceki[j]; eğer h==0 { dön -1; }
    dön (a.taş_izi[j]*64+hedef(h))*832;
}
işlev sürek_oku(a:Arayıcı,kat:i64,taş:i64,b:i64):i64 {
    s:=gör(Sürek,a.sürek); toplam:=0;
    y:=sürek_yeri(a,kat,1); eğer y>=0 { toplam+=i64(s.v1[y+taş*64+b]); }
    y=sürek_yeri(a,kat,2); eğer y>=0 { toplam+=i64(s.v2[y+taş*64+b]); }
    dön toplam;
}
işlev sürek_yaz(a:Arayıcı,kat:i64,taş:i64,b:i64,ödül:i64) {
    s:=gör(Sürek,a.sürek);
    y:=sürek_yeri(a,kat,1); eğer y>=0 { j:=y+taş*64+b; v:=i64(s.v1[j]); s.v1[j]=i16(enaz(32767,ençok(-32768,v+ödül-v*mutlak(ödül)/16384))); }
    y=sürek_yeri(a,kat,2); eğer y>=0 { j:=y+taş*64+b; v:=i64(s.v2[j]); s.v2[j]=i16(enaz(32767,ençok(-32768,v+ödül-v*mutlak(ödül)/16384))); }
}

işlev şah_verir(k:Konum,h:i64):i64 {
    ht:=hamle_türü(h); eğer ht!=0 { dön 1; }
    a:=kaynak(h); b:=hedef(h); r:=k.sıra; t:=tür(i64(k.tahta[a])); şah:=k.şah[1-r];
    d:=(dolu(k)&~bit(a))|bit(b);
    eğer (saldırı(t,b,d,r)&bit(şah))!=u64(0) { dön 1; }
    eğer ((kale_ışını[şah]|fil_ışını[şah])&bit(a))==u64(0) || (aynı_hat[şah*64+a]&bit(b))!=u64(0) { dön 0; }
    dost:=r*6;
    eğer (kale_ışını[şah]&bit(a))!=u64(0) { dön (kale_saldırısı(şah,d)&(k.bit_tahtası[dost+4]|k.bit_tahtası[dost+5]))!=u64(0); }
    dön (fil_saldırısı(şah,d)&(k.bit_tahtası[dost+3]|k.bit_tahtası[dost+5]))!=u64(0);
}

yapı ŞahSorgusu { hedef:u64[7]; açan:u64; şah:i64; hazır:i64; özel:i64; }
işlev şah_sorgusu_kur(k:Konum,q:ŞahSorgusu) {
    r:=k.sıra; o:=6*r; şah:=k.şah[1-r]; d:=dolu(k);
    q.şah=şah; q.açan=u64(0); q.özel=0;
    q.hedef[1]=piyon_alanı[(1-r)*64+şah]; q.hedef[2]=at_alanı[şah];
    q.hedef[3]=fil_saldırısı(şah,d); q.hedef[4]=kale_saldırısı(şah,d); q.hedef[5]=q.hedef[3]|q.hedef[4]; q.hedef[6]=şah_alanı[şah];

    yinele(t:=1;t<=6;t+=1) { eğer (q.hedef[t]&k.bit_tahtası[o+t])!=u64(0) { q.özel=1; } }
    aday:=(fil_ışını[şah]&(k.bit_tahtası[o+3]|k.bit_tahtası[o+5]))|(kale_ışını[şah]&(k.bit_tahtası[o+4]|k.bit_tahtası[o+5]));
    iken aday!=u64(0) {
        sq:=ilk_bit(i64(aday)); aday&=aday-u64(1); arada:=aradaki_kareler[şah*64+sq]&d;
        eğer (arada&(arada-u64(1)))==u64(0) { q.açan|=arada&k.renkler[r]; }
    }
    q.hazır=1;
}
işlev şah_sorgusu(k:Konum,q:ŞahSorgusu,h:i64):i64 {
    eğer hamle_türü(h)!=0 { dön 1; }
    eğer !q.hazır { şah_sorgusu_kur(k,q); }
    eğer q.özel { dön şah_verir(k,h); }
    a:=kaynak(h); b:=hedef(h); t:=tür(i64(k.tahta[a]));
    dön (q.hedef[t]&bit(b))!=u64(0) || ((q.açan&bit(a))!=u64(0) && (aynı_hat[q.şah*64+a]&bit(b))==u64(0));
}

yapı Tehditler { piyon:u64; hafif:u64; kale:u64; hazır:i64; }
işlev tehditleri_kur(k:Konum,t:Tehditler) {
    o:=1-k.sıra; d:=dolu(k); P:=k.bit_tahtası[o*6+1]; A:=u64(0x0101010101010101); H:=u64(0x8080808080808080);
    pa:u64:=seç(o==0,((P&~A)<<u64(7))|((P&~H)<<u64(9)),((P&~H)>>u64(7))|((P&~A)>>u64(9)));
    hf:=pa; x:=k.bit_tahtası[o*6+2];
    iken x!=u64(0) { s:=ilk_bit(i64(x)); x&=x-u64(1); hf|=at_alanı[s]; }
    x=k.bit_tahtası[o*6+3];
    iken x!=u64(0) { s:=ilk_bit(i64(x)); x&=x-u64(1); hf|=fil_saldırısı(s,d); }
    kl:=hf; x=k.bit_tahtası[o*6+4];
    iken x!=u64(0) { s:=ilk_bit(i64(x)); x&=x-u64(1); kl|=kale_saldırısı(s,d); }
    t.piyon=pa; t.hafif=hf; t.kale=kl; t.hazır=1;
}
işlev sırala(a:Arayıcı,l:Hamleler,öneri:i64,kat:i64,ilk:i64) {
    şs:=yerel(ŞahSorgusu); şs.hazır=0;
    k:=a.konum; th:=yerel(Tehditler); th.hazır=0; sy1:=sürek_yeri(a,kat,1); sy2:=sürek_yeri(a,kat,2); sü:=gör(Sürek,a.sürek);

    sıra:=k.sıra; katil1:=a.katiller[kat*2]; katil2:=a.katiller[kat*2+1]; gb:=sıra*4096;
    önceki:=a.önceki[kat]; karşı:=-1;
    eğer önceki!=0 { karşı=i64(a.karşılık[gb+kaynak(önceki)*64+hedef(önceki)]); }
    v1:adres:=0; v2:adres:=0;
    eğer sy1>=0 { v1=adres_ekle(adres(sü.v1),sy1*2); }
    eğer sy2>=0 { v2=adres_ekle(adres(sü.v2),sy2*2); }
    o:=1-sıra; h5:=k.bit_tahtası[o*6+5]; h45:=h5|k.bit_tahtası[o*6+4]; h2345:=h45|k.bit_tahtası[o*6+2]|k.bit_tahtası[o*6+3];
    d:=dolu(k);
    yinele(i:=ilk;i<l.adet;i+=1) {
        h:=i64(l.hamle[i]); av:=alınan_taş(k,h); ht:=hamle_türü(h); taş:=i64(k.tahta[kaynak(h)]); değer:=0; l.alış[i]=i32(0);

        eğer av!=0 && ht<4 && değişim_bedeli[av]<değişim_bedeli[tür(taş)] { l.alış[i]=i32(seç(değişim_eşik(k,h,0)!=0,0,-1)); }
        eğer h==öneri { değer=100000000; }
        yoksa eğer ht>=4 { değer=2000000+değişim_bedeli[ht-2]*100+değişim_bedeli[av]; }
        yoksa eğer av!=0 { değer=seç(l.alış[i]<i32(0),-1000000,1000000)+değişim_bedeli[av]*32+i64(a.alış_geçmişi[alış_yeri(taş,hedef(h),av)])/16; }
        yoksa eğer h==katil1 { değer=900000; }
        yoksa eğer h==katil2 { değer=800000; }
        yoksa {
            kh:=kaynak(h); hh:=hedef(h);
            değer=i64(a.geçmiş[gb+kh*64+hh]); sj:=taş*64+hh;
            eğer v1!=0 { değer+=i64(i16_oku(v1,sj)); }
            eğer v2!=0 { değer+=i64(i16_oku(v2,sj)); }

            eğer şah_sorgusu(k,şs,h) { değer+=12000; }
            tt:=tür(taş);

            eğer tt<=4 {
                hedefler:=seç(tt==1,h2345,seç(tt<=3,h45,h5));
                eğer hedefler!=u64(0) && (saldırı(tt,hh,(d&~bit(kh))|bit(hh),sıra)&hedefler)!=u64(0) { değer+=10000; }
            }
            eğer tt>=2 && tt<=5 {
                eğer !th.hazır { tehditleri_kur(k,th); }
                küme:=seç(tt==5,th.kale,seç(tt==4,th.hafif,th.piyon)); pay:=seç(tt==5,30000,20000);
                eğer (küme&bit(kh))!=u64(0) { değer+=pay; }
                eğer (küme&bit(hh))!=u64(0) { değer-=pay; }
            }
            eğer h==karşı { değer+=700000; }
        }
        l.değer[i]=değer;
    }
}
işlev sıradakini_seç(l:Hamleler,i:i64):i64 {

    eniyi:=i; endeğer:=i64(l.değer[i]);
    yinele(j:=i+1;j<l.adet;j+=1) { v:=i64(l.değer[j]); eğer v>endeğer { endeğer=v; eniyi=j; } }
    h:=i64(l.hamle[i]); l.hamle[i]=i64(l.hamle[eniyi]); l.hamle[eniyi]=h;
    d:=i64(l.değer[i]); l.değer[i]=i64(l.değer[eniyi]); l.değer[eniyi]=d; alış:=l.alış[i]; l.alış[i]=l.alış[eniyi]; l.alış[eniyi]=alış; dön i64(l.hamle[i]);
}
işlev varyantı_yaz(a:Arayıcı,kat:i64,h:i64) {
    a.yol[kat*128]=h; n:=enaz(a.uzunluk[kat+1],126-kat);
    yinele(i:=0;i<n;i+=1) { a.yol[kat*128+1+i]=a.yol[(kat+1)*128+i]; }
    a.uzunluk[kat]=n+1;
}
işlev önbelleğe_yaz(a:Arayıcı,k:Konum,d:i64,sınır:i64,puan:i64,h:i64,değer:i64,kat:i64,pv:i64) {
    c:=gör(ÖnbellekKümesi,adres_ekle(ortak_bellek,i64(çarp_yüksek_u64(k.anahtar,u64(bellek_kümesi)))*boyut(ÖnbellekKümesi)));
    kilitli:=işçi_sayısı>1;
    eğer kilitli && atomik_kıyas_değiştir(&c.kilit,0,1)!=0 { dön 0; }
    kısa:=u32(k.anahtar&u64(0xffffffff)); seçilen:=0; enaz_değer:=SONSUZ;
    yinele(i:=0;i<3;i+=1) {
        r:=gör(ÖnbellekKaydı,adres_ekle(adres(c.kayıt),i*16));
        eğer (i64(r.bilgi)&3)==0 || r.anahtar==kısa { seçilen=i; kır; }
        önem:=i64(r.derinlik)-((bellek_nesli-i64(r.nesil))&255)*8;
        eğer önem<enaz_değer { enaz_değer=önem; seçilen=i; }
    }
    q:=gör(ÖnbellekKaydı,adres_ekle(adres(c.kayıt),seçilen*16)); aynı:=(i64(q.bilgi)&3)!=0 && q.anahtar==kısa;

    eğer aynı && sınır!=1 && d+3<i64(q.derinlik) {
        eğer h!=0 { q.hamle=u16(h); } q.nesil=u8(bellek_nesli&255); eğer kilitli { atomik_yaz(&c.kilit,0); } dön 0;
    }
    eğer h==0 && aynı { h=i64(q.hamle); }
    eski_pv:=seç(aynı,(i64(q.bilgi)>>2)&1,0);
    q.anahtar=kısa; q.hamle=u16(h); q.derinlik=u8(enaz(255,ençok(d,0)));
    q.puan=i16(seç(puan>TB_KAZANÇ-AZAMİ_KAT,puan+kat,seç(puan < -(TB_KAZANÇ-AZAMİ_KAT),puan-kat,puan)));
    q.değer=i16(seç(değer==SONSUZ,0,değer));
    q.bilgi=u8(sınır|(seç(eski_pv!=0 || pv,1,0)<<2)|(seç(değer!=SONSUZ,1,0)<<3)); q.nesil=u8(bellek_nesli&255);
    eğer kilitli { atomik_yaz(&c.kilit,0); }
}
işlev önbellek_puanı(q:Önbellek,kat:i64):i64 {
    p:=i64(q.puan); dön seç(p>TB_KAZANÇ-AZAMİ_KAT,p-kat,seç(p < -(TB_KAZANÇ-AZAMİ_KAT),p+kat,p));
}
işlev durum_yuvası(a:Arayıcı,kat:i64):adres { dön adres_ekle(a.durumlar,kat*DURUM_BOYU); }
işlev durum(a:Arayıcı,kat:i64):adres { dön adres_oku(adres(a.durum_adres),kat); }

işlev değerlendir(a:Arayıcı,kat:i64):i64 {
    yer:adres:=0; k:=a.konum;
    eğer a.değer_belleği!=0 {
        yer=adres_ekle(a.değer_belleği,i64(k.anahtar&u64(DEĞER_YUVA-1))*boyut(DeğerYuva));
        e:=gör(DeğerYuva,yer);
        eğer e.anahtar==k.anahtar && i64(e.sıra)==k.sıra+1 && bellek_karşılaştır(adres(e.tahta),adres(k.tahta),64)==0 { dön i64(e.puan); }
    }
    q:=kat; iken a.durum_geçerli[q]==u8(0) { q-=1; }
    iken q<kat {

        eğer a.izler[q].adet==0 && !s8_hata { adres_yaz(adres(a.durum_adres),q+1,durum(a,q)); }
        yoksa {
            y:=durum_yuvası(a,q+1); adres_yaz(adres(a.durum_adres),q+1,y);
            ağ_güncelle_arama(y,durum(a,q),a.izler[q],a,seç(q+1==kat,adres(a.konum.bit_tahtası),0));
        }
        a.durum_geçerli[q+1]=u8(1); q+=1;
    }
    puan:=arama_ağ_değeri(a.konum,durum(a,kat));
    eğer yer!=0 {
        e:=gör(DeğerYuva,yer);e.anahtar=k.anahtar;e.sıra=i32(k.sıra+1);e.puan=i32(puan);
        bellek_kopyala(adres(e.tahta),adres(k.tahta),64);
    }
    dön puan;
}
işlev hamle_yap(a:Arayıcı,k:Konum,h:i64,g:İz,kat:i64) {
    a.taş_izi[kat+1]=i64(k.tahta[kaynak(h)]); a.önceki_av[kat+1]=alınan_taş(k,h); a.önceki[kat+1]=h;
    ilerle(k,h,g); a.durum_geçerli[kat+1]=u8(0); öngetir(adres_ekle(ortak_bellek,i64(çarp_yüksek_u64(k.anahtar,u64(bellek_kümesi)))*boyut(ÖnbellekKümesi)));
    eğer a.değer_belleği!=0 { öngetir(adres_ekle(a.değer_belleği,i64(k.anahtar&u64(DEĞER_YUVA-1))*boyut(DeğerYuva))); }
}

işlev sessiz_ara(a:Arayıcı,alfa:i64,beta:i64,kat:i64):i64 {
    a.uzunluk[kat]=0;
    eğer !düğüm_al(a) { dön 0; }
    eğer kat>a.seçilen_derinlik { a.seçilen_derinlik=kat; }
    alfa=ençok(alfa,-MAT+kat); beta=enaz(beta,MAT-kat-1);
    eğer alfa>=beta { dön alfa; }
    k:=a.konum; tehdit:=şah_tehditte(k); pv:=beta-alfa>1;
    eğer kat>=AZAMİ_KAT-2 { dön seç(tehdit,0,değerlendir(a,kat)); }
    beraber:=arama_beraberliği(a,k);
    eğer !tehdit && beraber { dön 0; }
    q:=yerel(Önbellek); eş:=önbellekten_oku(k,q);
    tt_puan:=seç(eş,önbellek_puanı(q,kat),0); tt_pv:=pv || (eş && q.pv!=0);
    eğer !pv && eş && !beraber {
        eğer q.sınır==1 || (q.sınır==2 && tt_puan>=beta) || (q.sınır==3 && tt_puan<=alfa) { dön tt_puan; }
    }
    öz:=SONSUZ; eniyi:=-SONSUZ; ham:=SONSUZ;
    eğer !tehdit {
        öz=seç(eş && q.değeri_var!=0,i64(q.değer),değerlendir(a,kat)); ham=öz; öz=düzelt(a,k,öz,kat); eniyi=öz;
        eğer eş && (q.sınır==1 || (q.sınır==2 && tt_puan>eniyi) || (q.sınır==3 && tt_puan<eniyi)) { eniyi=tt_puan; }
        eğer eniyi>=beta {

            eğer !şahsız_yasal_var(k) { dön 0; }
            eğer !eş { önbelleğe_yaz(a,k,0,2,eniyi,0,ham,kat,tt_pv); } dön eniyi;
        }
        eğer eniyi>alfa { alfa=eniyi; }
    }
    a.özdeğer[kat]=i32(öz); a.özgeçerli[kat]=u8(!tehdit);
    l:=yerel(Hamleler);
    eğer tehdit { yasal_hamleler(k,l); eğer l.adet==0 { dön -MAT+kat; } eğer beraber { dön 0; } }
    yoksa {
        yasal_alışlar(k,l);

        eğer l.adet==0 && !şahsız_yasal_var(k) { dön 0; }
    }
    öneri:=seç(eş && (tehdit || alınan_taş(k,q.hamle)!=0 || hamle_türü(q.hamle)>=4),q.hamle,0);
    sırala(a,l,öneri,kat,0); g:=a.izler[kat]; eniyi_hamle:=0; sayı:=0;
    önceki_hedef:=seç(a.önceki[kat]!=0,hedef(a.önceki[kat]),-1);
    yinele(i:=0;i<l.adet;i+=1) {
        h:=sıradakini_seç(l,i); av:=alınan_taş(k,h); ht:=hamle_türü(h);
        eğer !tehdit && eniyi > -29000 && budama {
            sayı+=1;
            eğer ht<4 && hedef(h)!=önceki_hedef {
                eğer sayı>ay[47] { a.budadı[0]+=1; sürdür; }
                sınır:=öz+değişim_bedeli[av]+ay[34];
                eğer sınır<=alfa { eğer eniyi<sınır { eniyi=sınır; } a.budadı[0]+=1; sürdür; }
            }
            eğer i64(l.alış[i])<0 { a.budadı[0]+=1; sürdür; }
        }
        hamle_yap(a,k,h,g,kat);
        puan:=-sessiz_ara(a,-beta,-alfa,kat+1);
        geri(k,g);
        eğer atomik_oku(&dur) { dön 0; }
        eğer puan>eniyi {
            eniyi=puan;
            eğer puan>alfa { eniyi_hamle=h; varyantı_yaz(a,kat,h); eğer puan>=beta { kır; } alfa=puan; }
        }
    }
    önbelleğe_yaz(a,k,0,seç(eniyi>=beta,2,3),eniyi,eniyi_hamle,ham,kat,tt_pv);
    dön eniyi;
}
işlev ara(a:Arayıcı,derinlik:i64,alfa:i64,beta:i64,kat:i64,kesen:i64):i64 {
    eğer derinlik<=0 { dön sessiz_ara(a,alfa,beta,kat); }
    a.uzunluk[kat]=0; l:=yerel(Hamleler);
    eğer !düğüm_al(a) { dön 0; }
    eğer kat>a.seçilen_derinlik { a.seçilen_derinlik=kat; }

    alfa=ençok(alfa,-MAT+kat); beta=enaz(beta,MAT-kat-1);
    eğer alfa>=beta { dön alfa; }
    k:=a.konum; tehdit:=şah_tehditte(k); pv:=beta-alfa>1; hariç:=a.hariç[kat];
    eğer kat>=AZAMİ_KAT-2 { dön seç(tehdit,0,değerlendir(a,kat)); }
    beraber:=arama_beraberliği(a,k);
    eğer !tehdit && beraber { dön 0; }
    a.kesme[kat+2]=0;
    q:=yerel(Önbellek); eş:=önbellekten_oku(k,q);
    tt_puan:=seç(eş,önbellek_puanı(q,kat),0); öneri:=seç(eş,q.hamle,0); tt_pv:=pv || (eş && q.pv!=0);
    tt_derinlik:=seç(eş,i64(q.derinlik),-1);

    eğer !pv && hariç==0 && !beraber && eş && tt_derinlik>=derinlik-seç(budama && tt_puan<beta,1,0) && k.elli<90 {
        eğer q.sınır==1 || (q.sınır==2 && tt_puan>=beta) || (q.sınır==3 && tt_puan<=alfa) { dön tt_puan; }
    }

    eğer tb_sayısı>0 && hariç==0 && k.rok==0 && k.elli==0 && derinlik>=tb_sonda_derinliği && bit_say(dolu(k))<=tb_en_büyük {
        wdl:=tb_wdl(k);
        eğer wdl!=3 {
            atomik_ekle(&tb_isabet,1);
            tb_puan:=seç(wdl<-1,-TB_KAZANÇ+kat,seç(wdl>1,TB_KAZANÇ-kat,2*wdl));
            tb_sınır:=seç(wdl<-1,3,seç(wdl>1,2,1));
            eğer tb_sınır==1 || (tb_sınır==2 && tb_puan>=beta) || (tb_sınır==3 && tb_puan<=alfa) {
                önbelleğe_yaz(a,k,enaz(126,derinlik+6),tb_sınır,tb_puan,0,SONSUZ,kat,tt_pv); dön tb_puan;
            }
            eğer pv && tb_sınır==2 { alfa=ençok(alfa,tb_puan); }
        }
    }
    öz:=SONSUZ;
    eğer tehdit { öz=SONSUZ; }
    yoksa eğer hariç!=0 { öz=i64(a.özdeğer[kat]); }
    yoksa { öz=seç(eş && q.değeri_var!=0,i64(q.değer),değerlendir(a,kat)); }
    ham:=öz; eğer !tehdit && hariç==0 { öz=düzelt(a,k,öz,kat); }
    güven:=64;
    eğer dinamik_marj && ağ_türü==2 && s8_hata && !tehdit && hariç==0 && !(eş && q.değeri_var!=0) {

        güven=enaz(dm_üst,ençok(dm_alt,64+(i64(i32_oku(durum(a,kat),396))-dm_orta-dm_cp*enaz(1000,mutlak(öz))/100)*dm_eğim/1024));
    }
    a.özdeğer[kat]=i32(öz); a.özgeçerli[kat]=u8(!tehdit);
    tahmin:=öz;
    eğer !tehdit && eş && (q.sınır==1 || (q.sınır==2 && tt_puan>öz) || (q.sınır==3 && tt_puan<öz)) { tahmin=tt_puan; }
    gelişme:=0;
    eğer !tehdit {
        eğer kat>=2 && a.özgeçerli[kat-2]!=u8(0) { gelişme=öz-i64(a.özdeğer[kat-2]); }
        yoksa eğer kat>=4 && a.özgeçerli[kat-4]!=u8(0) { gelişme=öz-i64(a.özdeğer[kat-4]); }
    }
    gelişen:=gelişme>0;

    eğer budama && öneri==0 && derinlik>=ay[70] && (pv || kesen) { derinlik-=1; }
    dost_np:=k.bit_tahtası[k.sıra*6+2]|k.bit_tahtası[k.sıra*6+3]|k.bit_tahtası[k.sıra*6+4]|k.bit_tahtası[k.sıra*6+5];
    tt_alış:=öneri!=0 && (alınan_taş(k,öneri)!=0 || hamle_türü(öneri)>=4);
    eğer !pv && !tehdit && hariç==0 && budama {

        eğer derinlik<=3 && tahmin<alfa-(ay[3]+ay[4]*derinlik*derinlik)*güven/64 && alfa > -29000 {
            puan:=sessiz_ara(a,alfa,beta,kat);
            eğer atomik_oku(&dur) { dön 0; }
            eğer puan<=alfa { a.budadı[6]+=1; dön puan; }
            a.uzunluk[kat]=0;
        }

        eğer !tt_pv && derinlik<=ay[2] && tahmin-(ay[0]*derinlik-seç(gelişen,ay[1],0))*güven/64>=beta && tahmin<29000 && beta > -29000 {
            eğer !şahsız_yasal_var(k) { dön 0; }
            a.budadı[1]+=1; dön (tahmin+beta)/2;
        }

        eğer a.önceki[kat]!=0 && öz>=beta && kat>=a.boş_alt_kat && dost_np!=u64(0) && beta > -29000 && tahmin<29000 {
            eski_ep:=k.geçer; eski_anahtar:=k.anahtar; eski_yol:=k.yol; eski_sınır:=k.dönüşsüz;
            eğer geçer_yasal(k) { k.anahtar^=geçer_anahtarı[k.geçer%8]; }
            k.geçer=-1; k.sıra=1-k.sıra; k.anahtar^=sıra_anahtarı;
            k.dönüşsüz=k.iz_sayısı; k.yol=döndür_sola(eski_yol,11)^k.anahtar^u64(0x4e554c4c);

            azalt:=ay[5]+derinlik/ay[6]+enaz(3,ençok(0,(tahmin-beta)/ay[7]))+seç(gelişen,1,0);
            a.önceki[kat+1]=0; a.taş_izi[kat+1]=0; a.önceki_av[kat+1]=0;
            a.izler[kat].adet=0; a.durum_geçerli[kat+1]=u8(0); öngetir(adres_ekle(ortak_bellek,i64(çarp_yüksek_u64(k.anahtar,u64(bellek_kümesi)))*boyut(ÖnbellekKümesi)));
            puan:=-ara(a,derinlik-azalt,-beta,-beta+1,kat+1,0);
            k.sıra=1-k.sıra; k.geçer=eski_ep; k.anahtar=eski_anahtar; k.yol=eski_yol; k.dönüşsüz=eski_sınır;
            a.uzunluk[kat]=0;
            eğer atomik_oku(&dur) { dön 0; }
            eğer puan>=beta && puan<29000 {
                eğer !şahsız_yasal_var(k) { dön 0; }
                eğer a.boş_alt_kat>0 || derinlik<ay[39] { a.budadı[2]+=1; dön puan; }

                a.boş_alt_kat=kat+3*(derinlik-azalt)/4;
                doğrulama:=ara(a,derinlik-azalt,beta-1,beta,kat,0);
                a.boş_alt_kat=0; a.uzunluk[kat]=0;
                eğer atomik_oku(&dur) { dön 0; }
                eğer doğrulama>=beta { a.budadı[2]+=1; dön puan; }
            }
        }

        pc_beta:=beta+ay[8]-seç(gelişen,ay[9],0);
        eğer derinlik>=ay[40] && beta<29000 && !(eş && tt_derinlik>=derinlik-3 && tt_puan<pc_beta) {
            pl:=l; yasal_alışlar(k,pl); sırala(a,pl,seç(tt_alış,öneri,0),kat,0); pg:=a.izler[kat];
            yinele(i:=0;i<pl.adet;i+=1) {
                h:=sıradakini_seç(pl,i);
                eğer h==hariç || !değişim_eşik(k,h,pc_beta-öz) { sürdür; }
                hamle_yap(a,k,h,pg,kat);
                puan:=-sessiz_ara(a,-pc_beta,-pc_beta+1,kat+1);
                eğer puan>=pc_beta && !atomik_oku(&dur) { puan=-ara(a,derinlik-4,-pc_beta,-pc_beta+1,kat+1,!kesen); }
                geri(k,pg); a.uzunluk[kat]=0;
                eğer atomik_oku(&dur) { dön 0; }
                eğer puan>=pc_beta { önbelleğe_yaz(a,k,derinlik-3,2,puan,h,ham,kat,tt_pv); a.budadı[7]+=1; dön puan; }
            }
        }
    }

    uzat:=0;
    eğer budama && hariç==0 && öneri!=0 && derinlik>=ay[41] && eş && q.sınır!=3 && tt_derinlik>=derinlik-3 && tt_puan<29000 && tt_puan > -29000 && kat<AZAMİ_KAT-8 {
        tekil_beta:=tt_puan-derinlik*ay[10]/64-seç(tt_pv && !pv,derinlik,0);
        a.hariç[kat]=öneri;
        tekil:=ara(a,(derinlik-1)/2,tekil_beta-1,tekil_beta,kat,kesen);
        a.hariç[kat]=0; a.uzunluk[kat]=0;
        eğer atomik_oku(&dur) { dön 0; }

        eğer tekil<tekil_beta { uzat=1+seç(!pv && tekil<tekil_beta-ay[48],1,0); }
        yoksa eğer tekil>=beta && tekil<29000 { a.budadı[3]+=1; dön (tekil+beta)/2; }
        yoksa eğer tt_puan>=beta { uzat=-ay[68]; }
        yoksa eğer kesen { uzat=-ay[69]; }
    }
    önden:=öneri!=0 && öneri!=hariç && tek_hamle_yasal(k,öneri,tehdit);
    eğer önden { l.adet=1; l.hamle[0]=öneri; l.tehdit=tehdit; } yoksa { yasal_hamleler(k,l); }
    eğer l.adet==0 { eğer hariç!=0 { dön alfa; } dön seç(tehdit,-MAT+kat,0); }
    eğer beraber { dön 0; }
    ilk_alfa:=alfa; eniyi:=-SONSUZ; eniyi_hamle:=0; aranan:=0; sayılan:=0; sessizleri_atla:=0;
    denenen:=yerel_dizi(i64,64); denenen_sayı:=0; alışlar:=yerel_dizi(i64,64); alış_sayı:=0; şs:=yerel(ŞahSorgusu); şs.hazır=0;
    sırala(a,l,öneri,kat,0); g:=a.izler[kat];
    ln_d:=ln_tablosu[enaz(63,derinlik)];
    yinele(i:=0;i<l.adet || önden;i+=1) {
        eğer önden && i==1 {

            yasal_hamleler(k,l);
            yinele(j:=0;j<l.adet;j+=1) { eğer i64(l.hamle[j])==öneri { x:=i64(l.hamle[0]); l.hamle[0]=öneri; l.hamle[j]=x; kır; } }
            sırala(a,l,öneri,kat,1); önden=0;
        }
        eğer i>=l.adet { kır; }
        h:=sıradakini_seç(l,i); eğer h==hariç { sürdür; }
        av:=alınan_taş(k,h); ht:=hamle_türü(h); sessiz:=av==0 && ht<4; taş:=i64(k.tahta[kaynak(h)]); b:=hedef(h);
        eğer sessizleri_atla && sessiz { sürdür; }
        geçmiş:=seç(sessiz,i64(a.geçmiş[k.sıra*4096+kaynak(h)*64+b])+sürek_oku(a,kat,taş,b),i64(a.alış_geçmişi[alış_yeri(taş,b,av)]));
        sayılan+=1;

        r:=ln_d*ln_tablosu[enaz(63,sayılan)]/seç(sessiz,ay[11],ay[12]);
        r+=ay[13]; eğer !gelişen { r+=ay[14]; }
        eğer kesen { r+=ay[15]+seç(öneri==0,ay[38],0); }
        eğer tt_pv { r-=ay[16]; }
        eğer pv { r-=ay[17]; }

        r-=(güven-64)*dm_lmr;
        eğer tt_alış && sessiz { r+=ay[35]; }
        eğer ay[80]>0 && sessiz && (h==a.katiller[kat*2] || h==a.katiller[kat*2+1]) { r-=ay[80]; }
        eğer a.kesme[kat+1]>2 { r+=ay[36]; }
        r-=geçmiş*ay[18]/1024;
        eğer sessiz && alfa<29000 && alfa > -29000 {
            fark:=alfa-öz;
            r+=ay[19]*seç(fark < -64, -64, seç(fark > 96, 96, fark));
        }
        eğer !pv && !kesen {
            r+=r*ay[44]/(256*derinlik+268);
        }
        eğer r<0 { r=0; }
        lmr_d:=ençok(0,derinlik-1-r/1024);
        eğer eniyi > -29000 && !tehdit && dost_np!=u64(0) && budama {
            eğer sessiz {
                eğer sayılan>=(ay[20]+derinlik*derinlik)*100/seç(gelişen,100,ay[64]) {

                    sessizleri_atla=1; a.budadı[5]+=1; y:=i+1;
                    yinele(j:=i+1;j<l.adet;j+=1) {
                        hj:=i64(l.hamle[j]);
                        eğer alınan_taş(k,hj)!=0 || hamle_türü(hj)>=4 { l.hamle[y]=hj; l.değer[y]=i64(l.değer[j]); l.alış[y]=l.alış[j]; y+=1; }
                    }
                    l.adet=y; sürdür;
                }
                eğer !şah_sorgusu(k,şs,h) {
                    eğer lmr_d<=5 && geçmiş < -ay[21]*derinlik { a.budadı[5]+=1; sürdür; }
                    eğer lmr_d<=8 && öz+(ay[22]+ay[23]*lmr_d)*güven/64<=alfa { a.budadı[4]+=1; sürdür; }
                    eğer lmr_d<=6 && !değişim_eşik(k,h,-ay[24]*lmr_d*lmr_d) { a.budadı[7]+=1; sürdür; }
                } yoksa eğer derinlik<=8 && !değişim_eşik(k,h,-ay[25]*derinlik) { a.budadı[7]+=1; sürdür; }
            } yoksa {
                alış:=i64(l.alış[i]);

                eğer derinlik<=8 && (alış<0 || -ay[26]*derinlik>0) && !değişim_eşik(k,h,-ay[26]*derinlik) { a.budadı[7]+=1; sürdür; }
                eğer lmr_d<=14 && ht<6 && öz+ay[27]+ay[28]*lmr_d+değişim_bedeli[av]+geçmiş/16<=alfa && !şah_sorgusu(k,şs,h) { a.budadı[0]+=1; sürdür; }
            }
        }
        hamle_yap(a,k,h,g,kat); şah_verdi:=şah_tehditte(k);
        yeni_d:=derinlik-1+seç(h==öneri,uzat,0); puan:=0;
        eğer budama && derinlik>=2 && aranan>=1 {
            eğer şah_verdi { r-=ay[37]; }
            eğer r<0 { r=0; }
            d_azalt:=enaz(yeni_d,ençok(1,yeni_d-r/1024));
            puan=-ara(a,d_azalt,-alfa-1,-alfa,kat+1,1);
            eğer !atomik_oku(&dur) && puan>alfa && d_azalt<yeni_d {
                yeni_d+=seç(puan>eniyi+ay[33],1,0);
                puan=-ara(a,yeni_d,-alfa-1,-alfa,kat+1,!kesen);
            }
        } yoksa eğer !pv || aranan>=1 {
            puan=-ara(a,yeni_d,-alfa-1,-alfa,kat+1,!kesen);
        }
        eğer pv && !atomik_oku(&dur) && (aranan==0 || puan>alfa) { puan=-ara(a,yeni_d,-beta,-alfa,kat+1,0); }
        geri(k,g);
        eğer atomik_oku(&dur) { dön 0; }
        aranan+=1;
        eğer puan>eniyi {
            eniyi=puan;
            eğer puan>alfa {
                eniyi_hamle=h; varyantı_yaz(a,kat,h);
                eğer puan>=beta { a.kesme[kat]+=1; kır; }
                alfa=puan;
            }
        }
        eğer sessiz { eğer denenen_sayı<64 { denenen[denenen_sayı]=h; denenen_sayı+=1; } }
        yoksa eğer alış_sayı<64 { alışlar[alış_sayı]=h; alış_sayı+=1; }
    }
    eğer aranan==0 { eğer hariç!=0 { dön alfa; } dön seç(tehdit,-MAT+kat,0); }
    ödül:=enaz(ay[31],ay[30]*derinlik-ay[32]);
    eğer eniyi>=beta {
        ht:=hamle_türü(eniyi_hamle); av:=alınan_taş(k,eniyi_hamle); taş:=i64(k.tahta[kaynak(eniyi_hamle)]); b:=hedef(eniyi_hamle);
        eğer av==0 && ht<4 {
            eğer a.katiller[kat*2]!=eniyi_hamle { a.katiller[kat*2+1]=a.katiller[kat*2]; a.katiller[kat*2]=eniyi_hamle; }
            geçmiş_yaz(a,k.sıra,eniyi_hamle,ödül); sürek_yaz(a,kat,taş,b,ödül);
            önceki:=a.önceki[kat]; eğer önceki!=0 { a.karşılık[k.sıra*4096+kaynak(önceki)*64+hedef(önceki)]=i32(eniyi_hamle); }
            yinele(j:=0;j<denenen_sayı;j+=1) {
                d:=denenen[j]; eğer d==eniyi_hamle { sürdür; }
                geçmiş_yaz(a,k.sıra,d,-ödül*ay[65]/100); sürek_yaz(a,kat,i64(k.tahta[kaynak(d)]),hedef(d),-ödül*ay[65]/100);
            }
        } yoksa { alış_geçmişi_yaz(a,taş,b,av,ödül); }
        yinele(j:=0;j<alış_sayı;j+=1) {
            d:=alışlar[j]; eğer d==eniyi_hamle { sürdür; }
            alış_geçmişi_yaz(a,i64(k.tahta[kaynak(d)]),hedef(d),alınan_taş(k,d),-ödül);
        }
    } yoksa eğer eniyi<=ilk_alfa && kat>=2 && a.önceki[kat]!=0 && a.önceki_av[kat]==0 && hamle_türü(a.önceki[kat])<4 {

        önceki:=a.önceki[kat]; geçmiş_yaz(a,1-k.sıra,önceki,ödül/2); sürek_yaz(a,kat-1,a.taş_izi[kat],hedef(önceki),ödül/2);
    }
    eğer !tehdit && hariç==0 && mutlak(eniyi)<TB_KAZANÇ-AZAMİ_KAT && !(eniyi_hamle!=0 && alınan_taş(k,eniyi_hamle)!=0) && !(eniyi>=beta && eniyi<=öz) && !(eniyi_hamle==0 && eniyi>=öz) {
        düzeltme_yaz(a,k,eniyi-öz,derinlik,kat);
    }
    eğer hariç==0 { önbelleğe_yaz(a,k,derinlik,seç(eniyi>=beta,2,seç(eniyi<=ilk_alfa,3,1)),eniyi,eniyi_hamle,ham,kat,tt_pv); }
    dön eniyi;
}

işlev kök_hamlesini_ara(a:Arayıcı,i:i64,ilk:i64,n:i64) {
    k:=a.konum; g:=a.izler[0]; sonuç:=a.kök[i]; h:=sonuç.hamle;
    alt:=seç(çoklu_varyant>1,-SONSUZ,a.alt); üst:=seç(çoklu_varyant>1,SONSUZ,a.üst);
    eğer alt>=üst { dön 0; }
    azalt:=0; önce:=a.sayaç;
    eğer budama && !ilk && çoklu_varyant==1 && a.derinlik>=4 && n>=4 && alınan_taş(k,h)==0 && hamle_türü(h)<4 && !şah_verir(k,h) { azalt=1+seç(n>=12,1,0); }
    hamle_yap(a,k,h,g,0); puan:=0; kesin:=0;
    eğer ilk || çoklu_varyant>1 {
        puan=-ara(a,a.derinlik-1,-üst,-alt,1,0); kesin=puan>alt && puan<üst;
    } yoksa {
        puan=-ara(a,a.derinlik-1-azalt,-alt-1,-alt,1,1);
        eğer azalt>0 && !atomik_oku(&dur) && puan>alt { puan=-ara(a,a.derinlik-1,-alt-1,-alt,1,1); }
        eğer !atomik_oku(&dur) && puan>alt {
            puan=-ara(a,a.derinlik-1,-üst,-alt,1,0); kesin=puan>alt && puan<üst;
        }
    }
    geri(k,g); eğer atomik_oku(&dur) { dön 0; }
    a.kök_düğüm[i]=a.sayaç-önce;
    sonuç.puan=puan; sonuç.kesin=kesin; sonuç.uzunluk=a.uzunluk[1]+1; sonuç.yol[0]=h;
    yinele(j:=0;j<a.uzunluk[1];j+=1) { sonuç.yol[j+1]=a.yol[128+j]; }
    sonuç.bitti=1;
    eğer çoklu_varyant==1 {
        a.alt=ençok(a.alt,puan);
    }
}

işlev önbellek_doluluğu():i64 {
    dolu_adet:=0; örnek:=0;
    yinele(i:=0;i<enaz(250,bellek_kümesi);i+=1) {
        c:=gör(ÖnbellekKümesi,adres_ekle(ortak_bellek,i*boyut(ÖnbellekKümesi)));
        eğer atomik_kıyas_değiştir(&c.kilit,0,1)!=0 { sürdür; }
        yinele(j:=0;j<3;j+=1) {
            r:=gör(ÖnbellekKaydı,adres_ekle(adres(c.kayıt),j*16));
            eğer (i64(r.bilgi)&3)!=0 && i64(r.nesil)==(bellek_nesli&255) { dolu_adet+=1; } örnek+=1;
        }
        atomik_yaz(&c.kilit,0);
    }
    dön seç(örnek==0,0,dolu_adet*1000/örnek);
}

genel ham_puan:i64=0;
genel wdl_göster:i64=0;
işlev wdl_x():f64 {
    m:=0;
    yinele(t:=1;t<=5;t+=1) {
        m+=seç(t==1,1,seç(t<=3,3,seç(t==4,5,9)))*bit_say(i64(kök_konum.bit_tahtası[t]|kök_konum.bit_tahtası[t+6]));
    }
    dön f64(enaz(78,ençok(17,m)))/58.0;
}
işlev wdl_a(x:f64):f64 { dön ((-125.62335254*x+368.07765431)*x-374.06181943)*x+350.94390370; }
işlev wdl_b(x:f64):f64 { dön ((87.78300599*x-190.07569162)*x+154.92913790)*x+17.67709960; }
işlev yuvarla(v:f64):i64 { dön seç(v<0.0,0-i64(aşağı_yuvarla(0.5-v)),i64(aşağı_yuvarla(v+0.5))); }
işlev gösterilen_cp(puan:i64):i64 {
    eğer ham_puan!=0 || mutlak(puan)>=TB_KAZANÇ-AZAMİ_KAT { dön puan; }
    dön yuvarla(100.0*f64(puan)/wdl_a(wdl_x()));
}
işlev wdl_yaz(puan:i64) {
    w:=0; l:=0;
    eğer puan>=TB_KAZANÇ-AZAMİ_KAT { w=1000; }
    yoksa eğer puan<=AZAMİ_KAT-TB_KAZANÇ { l=1000; }
    yoksa {
        x:=wdl_x(); a:=wdl_a(x); b:=wdl_b(x);
        w=yuvarla(1000.0/(1.0+üstel((a-f64(puan))/b)));
        l=yuvarla(1000.0/(1.0+üstel((a+f64(puan))/b)));
    }
    yaz(" wdl "); rakam(w); harf_yaz(32); rakam(1000-w-l); harf_yaz(32); rakam(l);
}
işlev arama_bilgisi(derinlik:i64,puan:i64,yol:adres,n:i64,varyant:i64) {

    eğer tb_kök_puanı!=SONSUZ && mutlak(puan)<TB_KAZANÇ-AZAMİ_KAT { puan=tb_kök_puanı; }
    kilit_al(&çıktı_kilidi); yaz("info depth "); rakam(derinlik);
    seçilen:=son_rapor_seçilen;
    yaz(" seldepth "); rakam(seçilen); yaz(" multipv "); rakam(varyant); yaz(" score ");
    eğer puan>29000 || puan < -29000 { yaz("mate "); rakam(seç(puan>0,(MAT-puan+1)/2,-(MAT+puan+1)/2)); }
    yoksa { yaz("cp "); rakam(gösterilen_cp(puan)); }
    eğer wdl_göster!=0 { wdl_yaz(puan); }
    düğüm:=atomik_oku(&düğümler); us:=ençok(1,(zaman_ns()-arama_başlangıcı)/1000); ms:=ençok(1,us/1000);
    eğer düğüm_sınırı>0 { düğüm=enaz(düğüm,düğüm_sınırı); }
    son_rapor_düğümü=düğüm;
    yaz(" nodes "); rakam(düğüm); yaz(" time "); rakam(ms); yaz(" nps "); rakam(düğüm*1000000/us); yaz(" hashfull "); rakam(önbellek_doluluğu()); yaz(" tbhits "); rakam(atomik_oku(&tb_isabet)); yaz(" pv");
    b:=dizi(8);
    yinele(i:=0;i<n;i+=1) { harf_yaz(32); hamle_metni(sayı_oku(yol,i),kök_konum,b); yaz(b); }
    satır_sonu(); kilit_bırak(&çıktı_kilidi);
}
işlev eniyi_yaz(h:i64) {
    kilit_al(&çıktı_kilidi); yaz("bestmove "); b:=dizi(8);
    eğer h==0 { yaz("0000"); } yoksa { hamle_metni(h,kök_konum,b); yaz(b); }

    eğer h!=0 && son_rapor_sayısı>0 && son_raporlar[0].uzunluk>=2 && son_raporlar[0].yol[0]==h {
        yaz(" ponder "); hamle_metni(son_raporlar[0].yol[1],kök_konum,b); yaz(b);
    }
    satır_sonu(); kilit_bırak(&çıktı_kilidi);
}
işlev rapor_işçisi(veri:adres):i64 {
    sonraki:=zaman_ns()+500000000;
    iken !atomik_oku(&rapor_bitsin) {
        eğer zaman_ns()>=sonraki {
            kilit_al(&rapor_kilidi);
            yinele(i:=0;i<son_rapor_sayısı;i+=1) {
                r:=son_raporlar[i]; arama_bilgisi(son_rapor_derinliği,r.puan,adres(r.yol),r.uzunluk,i+1);
            }
            kilit_bırak(&rapor_kilidi);
            sonraki=zaman_ns()+500000000;
        }
        uyu_ns(1000000);
    }
    dön 0;
}
işlev sonucu_beklet() {
    iken atomik_oku(&sonuç_beklesin) && !atomik_oku(&kullanıcı_durdu) { uyu_ns(1000000); }
}

işlev sonuç_işçisini_seç():i64 {
    matçı:=-1; derin:=0;
    yinele(i:=0;i<işçi_sayısı;i+=1) {
        a:=arayıcılar[i]; eğer a.biten_derinlik==0 { sürdür; }
        r:=a.biten[0]; eğer !r.bitti || !r.kesin { sürdür; }
        derin=ençok(derin,a.biten_derinlik);
        eğer r.puan>29000 && (matçı<0 || r.puan>arayıcılar[matçı].biten[0].puan ||
            (r.puan==arayıcılar[matçı].biten[0].puan && a.biten_derinlik>arayıcılar[matçı].biten_derinlik)) { matçı=i; }
    }

    eğer matçı>=0 { dön matçı; }
    seçilen:=-1; enoy:=-1; enpuan:=-SONSUZ;
    yinele(i:=0;i<işçi_sayısı;i+=1) {
        a:=arayıcılar[i];
        eğer a.biten_derinlik==derin && derin>0 && a.biten[0].bitti && a.biten[0].kesin { enpuan=ençok(enpuan,a.biten[0].puan); }
    }
    yinele(i:=0;i<işçi_sayısı;i+=1) {
        a:=arayıcılar[i]; eğer a.biten_derinlik!=derin || derin==0 { sürdür; }
        r:=a.biten[0]; eğer !r.bitti || !r.kesin { sürdür; }

        eğer r.puan < -29000 && (enpuan>=-29000 || r.puan<enpuan) { sürdür; }

        ana:=arayıcılar[0];
        eğer ana.biten_derinlik==derin && r.puan<ana.biten[0].puan { sürdür; }
        oy:=0;
        yinele(j:=0;j<işçi_sayısı;j+=1) {
            v:=arayıcılar[j];
            eğer v.biten_derinlik==derin && v.biten[0].bitti && v.biten[0].kesin && v.biten[0].hamle==r.hamle { oy+=1; }
        }
        eğer seçilen<0 || oy>enoy || (oy==enoy && r.puan>arayıcılar[seçilen].biten[0].puan) { seçilen=i; enoy=oy; }
    }
    dön seçilen;
}
işlev sonuçları_yayımla(son:i64) {
    kim:=sonuç_işçisini_seç(); eğer kim<0 { dön 0; }
    a:=arayıcılar[kim]; aynı:=son_rapor_derinliği==a.biten_derinlik && son_rapor_sayısı==enaz(çoklu_varyant,kök_sayısı);
    eğer aynı {
        yinele(i:=0;i<son_rapor_sayısı;i+=1) {
            r:=a.biten[i]; t:=son_raporlar[i];
            eğer r.puan!=t.puan || r.uzunluk!=t.uzunluk { aynı=0; kır; }
            yinele(j:=0;j<r.uzunluk;j+=1) { eğer r.yol[j]!=t.yol[j] { aynı=0; kır; } }
        }
    }
    eğer aynı && (!son || son_rapor_düğümü==atomik_oku(&düğümler)) { dön 0; }
    son_rapor_derinliği=a.biten_derinlik; son_rapor_seçilen=a.biten_seçilen;
    son_rapor_sayısı=enaz(çoklu_varyant,kök_sayısı);
    yinele(i:=0;i<son_rapor_sayısı;i+=1) {
        r:=a.biten[i]; bellek_kopyala(adres(son_raporlar[i]),adres(r),boyut(Kök));
        arama_bilgisi(son_rapor_derinliği,r.puan,adres(r.yol),r.uzunluk,i+1);
    }
}
işlev bağımsız_işçi(veri:adres):i64 {
    a:=gör(Arayıcı,veri); önceki_puan:=0; önceki_tur:=0;

    yinele(i:=0;i<kök_sayısı;i+=1) { a.sıra[i]=(i+a.kimlik*ay[42])%kök_sayısı; }
    ön:=yerel(Önbellek);
    eğer önbellekten_oku(a.konum,ön) {
        yinele(i:=0;i<kök_sayısı;i+=1) { eğer a.kök[a.sıra[i]].hamle==ön.hamle { x:=a.sıra[0]; a.sıra[0]=a.sıra[i]; a.sıra[i]=x; kır; } }
    }
    yinele(d:=1;d<=derinlik_sınırı;d+=1) {
        eğer atomik_oku(&dur) { kır; }
        tur_başı:=zaman_ns();
        a.derinlik=d; pay:=seç(d>=4 && çoklu_varyant==1,ay[29],SONSUZ); a.kesme[1]=0; a.kesme[2]=0; a.mat_arıyor=d>=16 && mutlak(önceki_puan)>=2000;

        alt:=ençok(-SONSUZ,önceki_puan-pay); üst:=enaz(SONSUZ,önceki_puan+pay); kazanan:=-1; taşma:=0;
        iken !atomik_oku(&dur) {
            a.alt=alt; a.üst=üst; a.derinlik=ençok(1,d-taşma);
            yinele(i:=0;i<kök_sayısı;i+=1) { a.kök[i].bitti=0; a.kök[i].kesin=0; }
            yinele(i:=0;i<kök_sayısı;i+=1) {
                eğer atomik_oku(&dur) || (çoklu_varyant==1 && a.alt>=üst) { kır; }
                kök_hamlesini_ara(a,a.sıra[i],i==0,i);
            }
            eğer atomik_oku(&dur) { kır; }
            yüksek:=a.alt>=üst; tamam:=1; kazanan=-1;
            yinele(i:=0;i<kök_sayısı;i+=1) {
                r:=a.kök[i]; eğer !r.bitti { tamam=0; }
                eğer r.bitti && r.kesin && (kazanan<0 || r.puan>a.kök[kazanan].puan) { kazanan=i; }
            }
            eğer çoklu_varyant==1 && (yüksek || kazanan<0) {
                eğer !yüksek && !tamam { kır; }
                pay=enaz(SONSUZ,pay*2);
                eğer yüksek { üst=seç(a.alt>29000,SONSUZ,enaz(SONSUZ,üst+pay)); taşma=enaz(3,taşma+1); }
                yoksa { alt=seç(a.alt < -29000,-SONSUZ,ençok(-SONSUZ,alt-pay)); taşma=0; }
                sürdür;
            }
            eğer !tamam { kazanan=-1; } kır;
        }
        düğümleri_aktar(a);
        eğer atomik_oku(&dur) || kazanan<0 { kır; }
        önceki_puan_eski:=önceki_puan; önceki_puan=a.kök[kazanan].puan;

        yumuşak_dur:=0;
        eğer a.kimlik==0 && saat_yönetimi && !atomik_oku(&rakip_sırası) {
            şimdi:=zaman_ns(); baş:=atomik_oku(&başlangıç_zamanı);
            tur:=ençok(0,(şimdi-ençok(tur_başı,baş))/1000000);
            geçen:=ençok(0,(şimdi-baş)/1000000);
            top_d:=0; yinele(i:=0;i<kök_sayısı;i+=1) { top_d+=a.kök_düğüm[i]; }
            yumuşak_dur=saat_turu_bitti(d,a.kök[kazanan].hamle,önceki_puan_eski,önceki_puan,geçen,tur,önceki_tur,seç(top_d>0,a.kök_düğüm[kazanan]*1000/ençok(1,top_d),-1));
            önceki_tur=tur;
        }

        eğer !kök_kısıtlı { önbelleğe_yaz(a,a.konum,d,1,önceki_puan,a.kök[kazanan].hamle,SONSUZ,0,1); }
        sıra:=yerel_dizi(i64,512); yinele(i:=0;i<kök_sayısı;i+=1) { sıra[i]=i; }
        kilit_al(&rapor_kilidi);
        yinele(i:=0;i<enaz(çoklu_varyant,kök_sayısı);i+=1) {
            enüst:=i;
            yinele(j:=i+1;j<kök_sayısı;j+=1) {
                aday:=a.kök[sıra[j]]; şimdiki:=a.kök[sıra[enüst]];
                eğer aday.kesin && (!şimdiki.kesin || aday.puan>şimdiki.puan) { enüst=j; }
            }
            x:=sıra[i]; sıra[i]=sıra[enüst]; sıra[enüst]=x;
            bellek_kopyala(adres(a.biten[i]),adres(a.kök[sıra[i]]),boyut(Kök));
        }
        a.biten_derinlik=d; a.biten_seçilen=a.seçilen_derinlik;
        sonuçları_yayımla(0); kilit_bırak(&rapor_kilidi);
        eğer yumuşak_dur { atomik_yaz(&dur,1); kır; }
        yinele(i:=0;i<kök_sayısı;i+=1) { eğer a.sıra[i]==kazanan { x:=a.sıra[0]; a.sıra[0]=kazanan; a.sıra[i]=x; kır; } }

        eğer a.kimlik==0 {
            yinele(i:=2;i<kök_sayısı;i+=1) {
                x:=a.sıra[i]; j:=i-1;
                iken j>=1 && a.kök_düğüm[a.sıra[j]]<a.kök_düğüm[x] { a.sıra[j+1]=a.sıra[j]; j-=1; }
                a.sıra[j+1]=x;
            }
        }

        eğer mat_sınırı>0 && önceki_puan>29000 && MAT-önceki_puan<=2*mat_sınırı { atomik_yaz(&dur,1); kır; }
    }
    düğümleri_aktar(a); dön 0;
}
işlev arama_hesapla():i64 {
    eniyi:=seç(kök_sayısı==0,0,kökler[0].hamle);
    eğer arayıcı_kapasite<işçi_sayısı {
        eğer adres(arayıcılar)!=0 { sil(arayıcılar); }
        arayıcılar=yeni_dizi(Arayıcı,işçi_sayısı); eğer adres(arayıcılar)==0 { arayıcı_kapasite=0; hata("isci bellegi ayrilamadi"); dön eniyi; }
        arayıcı_kapasite=işçi_sayısı;
    }
    eğer işçi_sayısı>en_çok_işçi { en_çok_işçi=işçi_sayısı; }

    yinele(i:=0;i<işçi_sayısı;i+=1) { bellek_sıfırla(adres(arayıcılar[i]),boyut(Arayıcı)); }
    bitiş:=atomik_oku(&son_zaman);
    eğer bitiş>0 && zaman_ns()>=bitiş { sonucu_beklet(); dön eniyi; }
    eğer kök_sayısı==0 || beraberlik(kök_konum) {
        kilit_al(&rapor_kilidi);
        son_rapor_sayısı=1; son_raporlar[0].puan=seç(kök_sayısı==0 && şah_tehditte(kök_konum),-MAT,0);
        son_raporlar[0].uzunluk=seç(eniyi==0,0,1); son_raporlar[0].yol[0]=eniyi;
        arama_bilgisi(0,son_raporlar[0].puan,adres(son_raporlar[0].yol),son_raporlar[0].uzunluk,1);
        kilit_bırak(&rapor_kilidi); sonucu_beklet(); dön eniyi;
    }
    eğer !önbelleği_kur() { hata("ortak TT ayrilamadi"); dön eniyi; }
    kurulan:=0; başarısız:=0;
    yinele(i:=0;i<işçi_sayısı;i+=1) {
        a:=arayıcılar[i]; a.kimlik=i;
        a.konum=yeni(Konum); a.kök=yeni_dizi(Kök,kök_sayısı); a.biten=yeni_dizi(Kök,enaz(çoklu_varyant,kök_sayısı));
        a.değer_belleği=0;

        eğer ağ_türü==2 && !s8_hata {
            a.değer_belleği=hizalı_ayır(DEĞER_YUVA*boyut(DeğerYuva),64);
            eğer a.değer_belleği!=0 { bellek_sıfırla(a.değer_belleği,DEĞER_YUVA*boyut(DeğerYuva)); }
        }
        a.yenileme=0;
        eğer ağ_türü==2 && s8_toplu_etkin { a.yenileme=hizalı_ayır(128*boyut(S8Yenileme),64); eğer a.yenileme!=0 { bellek_sıfırla(a.yenileme,128*boyut(S8Yenileme)); } }
        a.durumlar=büyük_ayır(DURUM_BOYU*AZAMİ_KAT); a.izler=yeni_dizi(İz,AZAMİ_KAT); a.sürek=kalıcı_sürek_al(i);
        eğer adres(a.konum)==0 || adres(a.kök)==0 || adres(a.biten)==0 || a.durumlar==0 || adres(a.izler)==0 || a.sürek==0 || (ağ_türü==2 && s8_toplu_etkin && a.yenileme==0) {
            sil(a.konum); sil(a.kök); sil(a.biten); hizalı_bırak(a.durumlar); hizalı_bırak(a.yenileme); hizalı_bırak(a.değer_belleği); sil(a.izler); başarısız=1; kır;
        }
        bellek_kopyala(adres(a.konum),adres(kök_konum),boyut(Konum));

        a.konum.ağ_etkin=0; bellek_kopyala(a.durumlar,adres(kök_konum.öz),DURUM_BOYU); a.durum_geçerli[0]=u8(1);
        yinele(j:=0;j<AZAMİ_KAT;j+=1) { adres_yaz(adres(a.durum_adres),j,durum_yuvası(a,j)); }
        a.kök_iz=kök_konum.iz_sayısı;
        bellek_kopyala(adres(a.geçmiş),&kalıcı_geçmiş[i*8192],8192*4); bellek_kopyala(adres(a.karşılık),&kalıcı_karşılık[i*8192],8192*4); bellek_kopyala(adres(a.alış_geçmişi),&kalıcı_alış[i*5824],5824*4); bellek_kopyala(adres(a.düzeltme),&kalıcı_düzeltme[i*32768],32768*4); bellek_kopyala(adres(a.düzeltme_tp),&kalıcı_düzeltme_tp[i*32768],32768*4); bellek_kopyala(adres(a.düzeltme_dv),&kalıcı_düzeltme_dv[i*1536],1536*4);
        bellek_kopyala(adres(a.kök),adres(kökler),boyut(Kök)*kök_sayısı);
        bellek_sıfırla(adres(a.biten),boyut(Kök)*enaz(çoklu_varyant,kök_sayısı)); kurulan+=1;
    }
    eğer başarısız { hata("arama bellegi ayrilamadi"); }
    yoksa {
        çalışan:=0;
        yinele(i:=1;i<işçi_sayısı;i+=1) {
            eğer iş_başlat_boy(&iş_kayıtları[i],işlev_adresi(bağımsız_işçi),adres(arayıcılar[i]),8388608)!=0 { kır; }
            çalışan+=1;
        }
        bağımsız_işçi(adres(arayıcılar[0]));

        atomik_yaz(&dur,1);
        yinele(i:=1;i<=çalışan;i+=1) { iş_bekle(&iş_kayıtları[i]); }
        kilit_al(&rapor_kilidi); sonuçları_yayımla(1);
        eğer son_rapor_sayısı>0 { eniyi=son_raporlar[0].hamle; } kilit_bırak(&rapor_kilidi);
    }
    yinele(i:=0;i<kurulan;i+=1) {
        a:=arayıcılar[i];
        bellek_kopyala(&kalıcı_geçmiş[i*8192],adres(a.geçmiş),8192*4); bellek_kopyala(&kalıcı_karşılık[i*8192],adres(a.karşılık),8192*4); bellek_kopyala(&kalıcı_alış[i*5824],adres(a.alış_geçmişi),5824*4); bellek_kopyala(&kalıcı_düzeltme[i*32768],adres(a.düzeltme),32768*4); bellek_kopyala(&kalıcı_düzeltme_tp[i*32768],adres(a.düzeltme_tp),32768*4); bellek_kopyala(&kalıcı_düzeltme_dv[i*1536],adres(a.düzeltme_dv),1536*4);
        sil(a.konum); sil(a.kök); sil(a.biten); hizalı_bırak(a.durumlar); hizalı_bırak(a.yenileme); hizalı_bırak(a.değer_belleği); sil(a.izler);
    }
    sonucu_beklet(); dön eniyi;
}

işlev arama_yürüt(veri:adres):i64 {
    son_rapor_sayısı=0; son_rapor_derinliği=0; son_rapor_seçilen=0; son_rapor_düğümü=0; atomik_yaz(&rapor_bitsin,0);
    kayıt:=yerel_dizi(u64,1);
    kuruldu:=iş_başlat_boy(adres(kayıt),işlev_adresi(rapor_işçisi),0,1048576)==0;
    eniyi:=arama_hesapla();
    atomik_yaz(&rapor_bitsin,1); eğer kuruldu { iş_bekle(adres(kayıt)); }

    eniyi_yaz(eniyi); dön 0;
}
işlev aramayı_durdur() {
    eğer arama_açık { atomik_yaz(&kullanıcı_durdu,1); atomik_yaz(&dur,1); iş_bekle(adres(arama_kaydı)); arama_açık=0; }
}
işlev aramayı_başlat(s:adres,n:i64) {
    go_başı:=zaman_ns();
    aramayı_durdur();
    başlangıç_zamanı=go_başı; arama_başlangıcı=go_başı;
    eğer başlangıç_zamanı<0 { hata("monoton saat okunamadi"); eniyi_yaz(0); dön 0; }
    eğer ağ==0 || (deneme_ağı && !deneme_izni) { hata("gecerli ag gerekli; HCE degerlendirmesi yok"); eniyi_yaz(0); dön 0; }
    derinlik_sınırı=126; mat_sınırı=0; düğüm_sınırı=0; son_zaman=0;
    süre:=-1; kalan:=-1; rakip_kalan:=-1; ek:=0; hamle_kaldı:=0; sonsuz:=0; seçilen:=0; rakip_sırası=0;
    l:=yerel(Hamleler); yasal_hamleler(oyun,l); kök_sayısı=l.adet;
    yinele(i:=0;i<l.adet;i+=1) { kökler[i].hamle=i64(l.hamle[i]); }
    i:=1; geçerli:=1;
    iken i<n {
        m:=adres_oku(s,i); i+=1;
        eğer metin_eşit(m,"infinite") { sonsuz=1; }
        yoksa eğer metin_eşit(m,"ponder") { rakip_sırası=1; }
        yoksa eğer metin_eşit(m,"searchmoves") {
            seçilen=1; kök_sayısı=0;
            iken i<n {
                h:=hamle_oku(oyun,adres_oku(s,i)); eğer h==0 { kır; } i+=1;
                var:=0; yinele(j:=0;j<kök_sayısı;j+=1) { eğer kökler[j].hamle==h { var=1; } }
                eğer !var { kökler[kök_sayısı].hamle=h; kök_sayısı+=1; }
            }
        } yoksa {
            eğer i==n { geçerli=0; kır; }
            v:=tamsayı(adres_oku(s,i)); i+=1; eğer v<0 { geçerli=0; kır; }
            eğer metin_eşit(m,"depth") { eğer v<1 || v>126 { geçerli=0; kır; } derinlik_sınırı=v; }
            yoksa eğer metin_eşit(m,"nodes") { eğer v<1 { geçerli=0; kır; } düğüm_sınırı=v; }
            yoksa eğer metin_eşit(m,"movetime") { süre=v; }
            yoksa eğer metin_eşit(m,"wtime") { eğer oyun.sıra==0 { kalan=v; } yoksa { rakip_kalan=v; } }
            yoksa eğer metin_eşit(m,"btime") { eğer oyun.sıra==1 { kalan=v; } yoksa { rakip_kalan=v; } }
            yoksa eğer metin_eşit(m,"winc") { eğer oyun.sıra==0 { ek=v; } }
            yoksa eğer metin_eşit(m,"binc") { eğer oyun.sıra==1 { ek=v; } }
            yoksa eğer metin_eşit(m,"movestogo") { eğer v<1 { geçerli=0; kır; } hamle_kaldı=v; }
            yoksa eğer metin_eşit(m,"mate") { eğer v<1 || v>63 { geçerli=0; kır; } mat_sınırı=v; }
            yoksa { geçerli=0; kır; }
        }
    }
    eğer !geçerli || (seçilen && kök_sayısı==0) { hata("gecersiz veya desteklenmeyen go siniri"); eniyi_yaz(0); dön 0; }
    eğer kitap_açık && !sonsuz && !rakip_sırası && !seçilen && oyun.tam<=kitap_derinlik {
        kh:=kitap_hamlesi(oyun);
        eğer kh!=0 { kilit_al(&çıktı_kilidi); metin_satırı("info string kitap hamlesi"); dosya_boşalt(çıktı); kilit_bırak(&çıktı_kilidi); eniyi_yaz(kh); dön 0; }
    }
    atomik_yaz(&tb_isabet,0); tb_kök_puanı=SONSUZ;
    eğer !seçilen && tb_kök_kısıtla() { seçilen=1; }
    kök_kısıtlı=seçilen;
    süre_optimum=-1; süre_azami=-1; kararlı_hamle=0; kararlı_sayı=0; saat_yönetimi=0;
    eğer süre>=0 { süre_optimum=süre; süre_azami=süre; }
    yoksa eğer !sonsuz && kalan>=0 {
        saat_yönetimi=1; saat_bütçesi(kalan,ek,hamle_kaldı,rakip_kalan); süre=süre_azami;
    }
    düşünme_süresi=süre; atomik_yaz(&sonuç_beklesin,sonsuz||rakip_sırası);
    eğer süre>=0 && !rakip_sırası { son_zaman=başlangıç_zamanı+ençok(1,süre)*1000000; }
    bellek_kopyala(adres(kök_konum),adres(oyun),boyut(Konum)); atomik_yaz(&kullanıcı_durdu,0); atomik_yaz(&dur,0); atomik_yaz(&düğümler,0);
    eğer iş_başlat_boy(adres(arama_kaydı),işlev_adresi(arama_yürüt),0,8388608)!=0 { hata("arama iscisi baslatilamadi"); eniyi_yaz(0); dön 0; }
    arama_açık=1;
}

sabit TB_TAŞ=7;
tablo tb_üçgen:i64[64]={6,0,1,2,2,1,0,6,0,7,3,4,4,3,7,0,1,3,8,5,5,8,3,1,2,4,5,9,9,5,4,2,2,4,5,9,9,5,4,2,1,3,8,5,5,8,3,1,0,7,3,4,4,3,7,0,6,0,1,2,2,1,0,6};
tablo tb_alt:i64[64]={28,0,1,2,3,4,5,6,0,29,7,8,9,10,11,12,1,7,30,13,14,15,16,17,2,8,13,31,18,19,20,21,3,9,14,18,32,22,23,24,4,10,15,19,22,33,25,26,5,11,16,20,23,25,34,27,6,12,17,21,24,26,27,35};
tablo tb_köşegen:i64[64]={0,0,0,0,0,0,0,8,0,1,0,0,0,0,9,0,0,0,2,0,0,10,0,0,0,0,0,3,11,0,0,0,0,0,0,12,4,0,0,0,0,0,13,0,0,5,0,0,0,14,0,0,0,0,6,0,15,0,0,0,0,0,0,7};
tablo tb_kanat:i64[64]={0,0,0,0,0,0,0,0,0,6,12,18,18,12,6,0,1,7,13,19,19,13,7,1,2,8,14,20,20,14,8,2,3,9,15,21,21,15,9,3,4,10,16,22,22,16,10,4,5,11,17,23,23,17,11,5,0,0,0,0,0,0,0,0};
tablo tb_burgu:i64[64]={0,0,0,0,0,0,0,0,47,35,23,11,10,22,34,46,45,33,21,9,8,20,32,44,43,31,19,7,6,18,30,42,41,29,17,5,4,16,28,40,39,27,15,3,2,14,26,38,37,25,13,1,0,12,24,36,0,0,0,0,0,0,0,0};
tablo tb_terskanat:i64[24]={8,16,24,32,40,48,9,17,25,33,41,49,10,18,26,34,42,50,11,19,27,35,43,51};
tablo tb_dosya:i64[8]={0,1,2,3,3,2,1,0};
tablo tb_kk:i64[640]={
 -1,-1,-1,0,1,2,3,4,-1,-1,-1,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,
 58,-1,-1,-1,59,60,61,62,63,-1,-1,-1,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,
 116,117,-1,-1,-1,118,119,120,121,122,-1,-1,-1,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,
 174,-1,-1,-1,175,176,177,178,179,-1,-1,-1,180,181,182,183,184,-1,-1,-1,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,
 229,230,-1,-1,-1,231,232,233,234,235,-1,-1,-1,236,237,238,239,240,-1,-1,-1,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,
 284,285,286,287,288,289,290,291,292,293,-1,-1,-1,294,295,296,297,298,-1,-1,-1,299,300,301,302,303,-1,-1,-1,304,305,306,307,308,309,310,311,312,313,314,315,316,317,318,319,320,321,322,323,324,325,326,327,328,329,330,331,332,333,334,335,336,337,338,
 -1,-1,339,340,341,342,343,344,-1,-1,345,346,347,348,349,350,-1,-1,441,351,352,353,354,355,-1,-1,-1,442,356,357,358,359,-1,-1,-1,-1,443,360,361,362,-1,-1,-1,-1,-1,444,363,364,-1,-1,-1,-1,-1,-1,445,365,-1,-1,-1,-1,-1,-1,-1,446,
 -1,-1,-1,366,367,368,369,370,-1,-1,-1,371,372,373,374,375,-1,-1,-1,376,377,378,379,380,-1,-1,-1,447,381,382,383,384,-1,-1,-1,-1,448,385,386,387,-1,-1,-1,-1,-1,449,388,389,-1,-1,-1,-1,-1,-1,450,390,-1,-1,-1,-1,-1,-1,-1,451,
 452,391,392,393,394,395,396,397,-1,-1,-1,-1,398,399,400,401,-1,-1,-1,-1,402,403,404,405,-1,-1,-1,-1,406,407,408,409,-1,-1,-1,-1,453,410,411,412,-1,-1,-1,-1,-1,454,413,414,-1,-1,-1,-1,-1,-1,455,415,-1,-1,-1,-1,-1,-1,-1,456,
 457,416,417,418,419,420,421,422,-1,458,423,424,425,426,427,428,-1,-1,-1,-1,-1,429,430,431,-1,-1,-1,-1,-1,432,433,434,-1,-1,-1,-1,-1,435,436,437,-1,-1,-1,-1,-1,459,438,439,-1,-1,-1,-1,-1,-1,460,440,-1,-1,-1,-1,-1,-1,-1,461};
tablo tb_wdl_harita:i64[5]={1,3,0,2,0};
tablo tb_pa_bayrak:i64[5]={8,0,0,0,4};
genel tb_binom:i64[512];
genel tb_piyonidx:i64[120];
genel tb_pçarpan:i64[20];
genel tb_hazır:i64=0;

yapı Tablo {
    anahtar:u64; ayna:u64; num:i64; piyonlu:i64; piyon0:i64; piyon1:i64; kodlama:i64; simetrik:i64; dtz:i64;
    yol:adres; veri:adres; boyut:i64; eşlenmiş:i64; hazır:i64; dosyalar:i64; bölünmüş:i64;
    parça:u8[56]; norm:u8[56]; çarpan:i64[56]; boy:i64[8]; büyüklük:i64[24]; cyer:adres; c_taban:u64[512];
    bayrak:i64[4]; harita:adres; harita_idx:i64[16];
}
genel tb_tablolar:Tablo[]; genel tb_sayısı:i64=0;
genel tb_kilit:i64=0; genel tb_en_büyük:i64=0;
genel tb_yol:adres=0; genel tb_sonda_derinliği:i64=1; genel tb_elli_kuralı:i64=1;
genel tb_isabet:i64=0; genel tb_kök_puanı:i64=SONSUZ;
sabit TB_KAZANÇ=25000;

işlev tb_binom_al(x:i64,y:i64):i64 { eğer x<0 || y<0 || y>7 || x>63 || y>x { dön 0; } dön tb_binom[x*8+y]; }
işlev tb_sabitleri_kur() {
    eğer tb_hazır { dön 0; }
    yinele(x:=0;x<64;x+=1) { yinele(y:=0;y<8;y+=1) {
        v:=1; eğer y>x { v=0; } yoksa { yinele(i:=0;i<y;i+=1) { v=v*(x-i)/(i+1); } }
        tb_binom[x*8+y]=v;
    } }
    yinele(i:=0;i<5;i+=1) {
        j:=0;
        yinele(f:=0;f<4;f+=1) {
            s:=0;
            iken j<6*(f+1) { tb_piyonidx[i*24+j]=s; s+=seç(i==0,1,tb_binom_al(tb_burgu[tb_terskanat[j]],i)); j+=1; }
            tb_pçarpan[i*4+f]=s;
        }
    }
    tb_hazır=1; dön 0;
}
işlev tb_altçarpan(k:i64,n:i64):i64 { f:=n; l:=1; yinele(i:=1;i<k;i+=1) { f*=n-i; l*=i+1; } dön f/l; }
işlev tb_köşedışı(s:i64):i64 { dön s/8-s%8; }
işlev tb_köşegen_çevir(s:i64):i64 { dön ((s>>3)|(s<<3))&63; }
işlev tb_u16(p:adres):i64 { dön bayt_oku(p,0)|(bayt_oku(p,1)<<8); }
işlev tb_u32(p:adres):i64 { dön bayt_oku(p,0)|(bayt_oku(p,1)<<8)|(bayt_oku(p,2)<<16)|(bayt_oku(p,3)<<24); }
işlev tb_u32be(p:adres):u64 { dön (u64(bayt_oku(p,0))<<u64(24))|(u64(bayt_oku(p,1))<<u64(16))|(u64(bayt_oku(p,2))<<u64(8))|u64(bayt_oku(p,3)); }
işlev tb_u64be(p:adres):u64 { dön (tb_u32be(p)<<u64(32))|tb_u32be(adres_ekle(p,4)); }

işlev tb_anahtar_ekle(anahtar:u64,renk:i64,tür:i64,adet:i64):u64 { dön anahtar+(u64(adet)<<u64(4*(renk*6+tür-1))); }
işlev tb_konum_anahtarı(k:Konum):u64 {
    a:u64:=u64(0);
    yinele(r:=0;r<2;r+=1) { yinele(t:=1;t<=6;t+=1) { a=tb_anahtar_ekle(a,r,t,bit_say(k.bit_tahtası[r*6+t])); } }
    dön a;
}
işlev tb_anahtar_ayna(a:u64):u64 { dön ((a&u64(0xffffff))<<u64(24))|(a>>u64(24)); }
işlev tb_parça_anahtarı(t:Tablo,yuva:i64,ayna:i64):u64 {
    a:u64:=u64(0);
    yinele(i:=0;i<t.num;i+=1) { pc:=i64(t.parça[yuva*7+i]); r:=(pc>>3)^ayna; a=tb_anahtar_ekle(a,r,pc&7,1); }
    dön a;
}

işlev ça(t:Tablo,j:i64,i:i64):adres { dön adres_oku(t.cyer,j*16+i); }
işlev çs(t:Tablo,j:i64,i:i64):i64 { dön sayı_oku(t.cyer,j*16+i); }
işlev ça_yaz(t:Tablo,j:i64,i:i64,v:adres) { adres_yaz(t.cyer,j*16+i,v); }
işlev çs_yaz(t:Tablo,j:i64,i:i64,v:i64) { sayı_yaz(t.cyer,j*16+i,v); }
işlev tb_çiftleri_kur(t:Tablo,j:i64,p:adres,tb_boyut:i64,byuva:i64,wdl:i64):adres {
    b0:=bayt_oku(p,0);
    eğer (b0&0x80)!=0 {
        çs_yaz(t,j,7,0); çs_yaz(t,j,8,seç(wdl,bayt_oku(p,1),0));
        t.büyüklük[byuva]=0; t.büyüklük[byuva+1]=0; t.büyüklük[byuva+2]=0;
        dön adres_ekle(p,2);
    }
    çs_yaz(t,j,6,bayt_oku(p,1)); çs_yaz(t,j,7,bayt_oku(p,2));
    gerçek_blok:=tb_u32(adres_ekle(p,4)); blok_sayısı:=gerçek_blok+bayt_oku(p,3);
    en_çok:=bayt_oku(p,8); en_az:=bayt_oku(p,9); h:=en_çok-en_az+1;
    sim_sayısı:=tb_u16(adres_ekle(p,10+2*h));
    uz:=adres_ekle(p,10); ça_yaz(t,j,3,uz); çs_yaz(t,j,9,h); çs_yaz(t,j,8,en_az);
    sl:=bellek_ayır(2*(h*8+sim_sayısı+8)); bellek_sıfırla(sl,2*(h*8+sim_sayısı+8)); ça_yaz(t,j,4,sl);
    ça_yaz(t,j,5,adres_ekle(p,12+2*h));
    sonraki:=adres_ekle(p,12+2*h+3*sim_sayısı+(sim_sayısı&1));
    idxbit:=bayt_oku(p,2); indeks_sayısı:=(tb_boyut+(1<<idxbit)-1)>>idxbit;
    t.büyüklük[byuva]=6*indeks_sayısı; t.büyüklük[byuva+1]=2*blok_sayısı; t.büyüklük[byuva+2]=(1<<bayt_oku(p,1))*gerçek_blok;
    işaret:=bellek_ayır(sim_sayısı+8); bellek_sıfırla(işaret,sim_sayısı+8);
    yinele(i:=0;i<sim_sayısı;i+=1) { eğer bayt_oku(işaret,i)==0 { tb_simuzunluk(t,j,i,işaret); } }
    bellek_bırak(işaret);
    t.c_taban[j*64+h-1]=u64(0);
    yinele(i:=h-2;i>=0;i-=1) {
        v:=i64(t.c_taban[j*64+i+1])+tb_u16(adres_ekle(uz,i*2))-tb_u16(adres_ekle(uz,i*2+2));
        t.c_taban[j*64+i]=u64(v/2);
    }
    yinele(i:=0;i<h;i+=1) { t.c_taban[j*64+i]=t.c_taban[j*64+i]<<u64(64-(en_az+i)); }
    ça_yaz(t,j,3,adres_ekle(uz,-2*en_az));
    dön sonraki;
}
işlev tb_simuzunluk(t:Tablo,j:i64,s:i64,işaret:adres) {
    sl:=ça(t,j,4); w:=adres_ekle(ça(t,j,5),3*s);
    s2:=(bayt_oku(w,2)<<4)|(bayt_oku(w,1)>>4);
    eğer s2==0xfff { u16_yaz(sl,s,u16(0)); }
    yoksa {
        s1:=((bayt_oku(w,1)&0xf)<<8)|bayt_oku(w,0);
        eğer bayt_oku(işaret,s1)==0 { tb_simuzunluk(t,j,s1,işaret); }
        eğer bayt_oku(işaret,s2)==0 { tb_simuzunluk(t,j,s2,işaret); }
        u16_yaz(sl,s,u16(i64(u16_oku(sl,s1))+i64(u16_oku(sl,s2))+1));
    }
    bayt_yaz(işaret,s,1);
}
işlev tb_norm_taş(t:Tablo,yuva:i64) {
    b:=yuva*7;
    yinele(i:=0;i<t.num;i+=1) { t.norm[b+i]=u8(0); }
    t.norm[b]=u8(seç(t.kodlama==0,3,2));
    i:=i64(t.norm[b]);
    iken i<t.num {
        j:=i;
        iken j<t.num && t.parça[b+j]==t.parça[b+i] { t.norm[b+i]=u8(i64(t.norm[b+i])+1); j+=1; }
        i+=i64(t.norm[b+i]);
    }
}
işlev tb_çarpan_taş(t:Tablo,yuva:i64,sıra:i64):i64 {
    b:=yuva*7; n:=64-i64(t.norm[b]); f:=1; i:=i64(t.norm[b]); k:=0;
    iken i<t.num || k==sıra {
        eğer k==sıra { t.çarpan[b]=f; f*=seç(t.kodlama==0,31332,462); }
        yoksa { t.çarpan[b+i]=f; f*=tb_altçarpan(i64(t.norm[b+i]),n); n-=i64(t.norm[b+i]); i+=i64(t.norm[b+i]); }
        k+=1;
    }
    dön f;
}
işlev tb_norm_piyon(t:Tablo,yuva:i64) {
    b:=yuva*7;
    yinele(i:=0;i<t.num;i+=1) { t.norm[b+i]=u8(0); }
    t.norm[b]=u8(t.piyon0);
    eğer t.piyon1!=0 { t.norm[b+t.piyon0]=u8(t.piyon1); }
    i:=t.piyon0+t.piyon1;
    iken i<t.num {
        j:=i;
        iken j<t.num && t.parça[b+j]==t.parça[b+i] { t.norm[b+i]=u8(i64(t.norm[b+i])+1); j+=1; }
        i+=i64(t.norm[b+i]);
    }
}
işlev tb_çarpan_piyon(t:Tablo,yuva:i64,sıra:i64,sıra2:i64,f:i64):i64 {
    b:=yuva*7; i:=i64(t.norm[b]);
    eğer sıra2<0xf { i+=i64(t.norm[b+i]); }
    n:=64-i; fac:=1; k:=0;
    iken i<t.num || k==sıra || k==sıra2 {
        eğer k==sıra { t.çarpan[b]=fac; fac*=tb_pçarpan[(i64(t.norm[b])-1)*4+f]; }
        yoksa eğer k==sıra2 { t.çarpan[b+i64(t.norm[b])]=fac; fac*=tb_altçarpan(i64(t.norm[b+i64(t.norm[b])]),48-i64(t.norm[b])); }
        yoksa { t.çarpan[b+i]=fac; fac*=tb_altçarpan(i64(t.norm[b+i]),n); n-=i64(t.norm[b+i]); i+=i64(t.norm[b+i]); }
        k+=1;
    }
    dön fac;
}
işlev tb_piyon_dosyası(t:Tablo,pos:adres):i64 {
    yinele(i:=1;i<t.piyon0;i+=1) {
        eğer tb_kanat[sayı_oku(pos,0)]>tb_kanat[sayı_oku(pos,i)] { x:=sayı_oku(pos,0); sayı_yaz(pos,0,sayı_oku(pos,i)); sayı_yaz(pos,i,x); }
    }
    dön tb_dosya[sayı_oku(pos,0)&7];
}

işlev tb_grupları_kodla(t:Tablo,yuva:i64,pos:adres,i:i64,idx:i64):i64 {
    b:=yuva*7; n:=t.num;
    iken i<n {
        tt:=i64(t.norm[b+i]);
        yinele(j:=i;j<i+tt;j+=1) { yinele(k:=j+1;k<i+tt;k+=1) {
            eğer sayı_oku(pos,j)>sayı_oku(pos,k) { x:=sayı_oku(pos,j); sayı_yaz(pos,j,sayı_oku(pos,k)); sayı_yaz(pos,k,x); }
        } }
        s:=0;
        yinele(m:=i;m<i+tt;m+=1) {
            p:=sayı_oku(pos,m); j:=0;
            yinele(l:=0;l<i;l+=1) { eğer p>sayı_oku(pos,l) { j+=1; } }
            s+=tb_binom_al(p-j,m-i+1);
        }
        idx+=s*t.çarpan[b+i]; i+=tt;
    }
    dön idx;
}
işlev tb_taş_kodla(t:Tablo,yuva:i64,pos:adres):i64 {
    n:=t.num; b:=yuva*7;
    eğer (sayı_oku(pos,0)&4)!=0 { yinele(i:=0;i<n;i+=1) { sayı_yaz(pos,i,sayı_oku(pos,i)^7); } }
    eğer (sayı_oku(pos,0)&0x20)!=0 { yinele(i:=0;i<n;i+=1) { sayı_yaz(pos,i,sayı_oku(pos,i)^0x38); } }
    i:=0; iken i<n && tb_köşedışı(sayı_oku(pos,i))==0 { i+=1; }
    eğer i<seç(t.kodlama==0,3,2) && i<n && tb_köşedışı(sayı_oku(pos,i))>0 { yinele(j:=0;j<n;j+=1) { sayı_yaz(pos,j,tb_köşegen_çevir(sayı_oku(pos,j))); } }
    idx:=0;
    eğer t.kodlama==0 {
        p0:=sayı_oku(pos,0); p1:=sayı_oku(pos,1); p2:=sayı_oku(pos,2);
        i1:=seç(p1>p0,1,0); j:=seç(p2>p0,1,0)+seç(p2>p1,1,0);
        eğer tb_köşedışı(p0)!=0 { idx=tb_üçgen[p0]*63*62+(p1-i1)*62+(p2-j); }
        yoksa eğer tb_köşedışı(p1)!=0 { idx=6*63*62+tb_köşegen[p0]*28*62+tb_alt[p1]*62+p2-j; }
        yoksa eğer tb_köşedışı(p2)!=0 { idx=6*63*62+4*28*62+tb_köşegen[p0]*7*28+(tb_köşegen[p1]-i1)*28+tb_alt[p2]; }
        yoksa { idx=6*63*62+4*28*62+4*7*28+tb_köşegen[p0]*7*6+(tb_köşegen[p1]-i1)*6+(tb_köşegen[p2]-j); }
        i=3;
    } yoksa {
        idx=tb_kk[tb_üçgen[sayı_oku(pos,0)]*64+sayı_oku(pos,1)]; i=2;
    }
    idx*=t.çarpan[b];
    dön tb_grupları_kodla(t,yuva,pos,i,idx);
}
işlev tb_piyon_kodla(t:Tablo,yuva:i64,pos:adres):i64 {
    n:=t.num; b:=yuva*7;
    eğer (sayı_oku(pos,0)&4)!=0 { yinele(i:=0;i<n;i+=1) { sayı_yaz(pos,i,sayı_oku(pos,i)^7); } }
    yinele(i:=1;i<t.piyon0;i+=1) { yinele(j:=i+1;j<t.piyon0;j+=1) {
        eğer tb_burgu[sayı_oku(pos,i)]<tb_burgu[sayı_oku(pos,j)] { x:=sayı_oku(pos,i); sayı_yaz(pos,i,sayı_oku(pos,j)); sayı_yaz(pos,j,x); }
    } }
    tt:=t.piyon0-1; idx:=tb_piyonidx[tt*24+tb_kanat[sayı_oku(pos,0)]];
    yinele(i:=tt;i>0;i-=1) { idx+=tb_binom_al(tb_burgu[sayı_oku(pos,i)],tt-i+1); }
    idx*=t.çarpan[b];
    i:=t.piyon0; son:=i+t.piyon1;
    eğer son>i {
        yinele(j:=i;j<son;j+=1) { yinele(k:=j+1;k<son;k+=1) {
            eğer sayı_oku(pos,j)>sayı_oku(pos,k) { x:=sayı_oku(pos,j); sayı_yaz(pos,j,sayı_oku(pos,k)); sayı_yaz(pos,k,x); }
        } }
        s:=0;
        yinele(m:=i;m<son;m+=1) {
            p:=sayı_oku(pos,m); j:=0;
            yinele(k:=0;k<i;k+=1) { eğer p>sayı_oku(pos,k) { j+=1; } }
            s+=tb_binom_al(p-j-8,m-i+1);
        }
        idx+=s*t.çarpan[b+i]; i=son;
    }
    dön tb_grupları_kodla(t,yuva,pos,i,idx);
}
işlev tb_çöz(t:Tablo,j:i64,idx:i64):i64 {
    idxbit:=çs(t,j,7); m:=çs(t,j,8);
    eğer idxbit==0 { dön m; }
    indeks:=ça(t,j,0); boyutlar:=ça(t,j,1); uzaklık:=ça(t,j,3); sl:=ça(t,j,4); simpat:=ça(t,j,5);
    ana:=idx>>idxbit; lit:=(idx&((1<<idxbit)-1))-(1<<(idxbit-1));
    blok:=tb_u32(adres_ekle(indeks,6*ana));
    lit+=tb_u16(adres_ekle(indeks,6*ana+4));
    eğer lit<0 { iken lit<0 { blok-=1; lit+=tb_u16(adres_ekle(boyutlar,2*blok))+1; } }
    yoksa { iken lit>tb_u16(adres_ekle(boyutlar,2*blok)) { lit-=tb_u16(adres_ekle(boyutlar,2*blok))+1; blok+=1; } }
    p:=adres_ekle(ça(t,j,2),blok<<çs(t,j,6));
    kod:u64:=tb_u64be(p); p=adres_ekle(p,8); bitsay:=0; sim:=0;
    iken 1 {
        l:=m;
        iken kod<t.c_taban[j*64+l-m] { l+=1; }
        sim=tb_u16(adres_ekle(uzaklık,l*2));
        sim+=i64((kod-t.c_taban[j*64+l-m])>>u64(64-l));
        eğer lit<i64(u16_oku(sl,sim))+1 { kır; }
        lit-=i64(u16_oku(sl,sim))+1;
        kod=kod<<u64(l); bitsay+=l;
        eğer bitsay>=32 { bitsay-=32; kod=kod|(tb_u32be(p)<<u64(bitsay)); p=adres_ekle(p,4); }
    }
    iken i64(u16_oku(sl,sim))!=0 {
        w:=adres_ekle(simpat,3*sim);
        s1:=((bayt_oku(w,1)&0xf)<<8)|bayt_oku(w,0);
        eğer lit<i64(u16_oku(sl,s1))+1 { sim=s1; }
        yoksa { lit-=i64(u16_oku(sl,s1))+1; sim=(bayt_oku(w,2)<<4)|(bayt_oku(w,1)>>4); }
    }
    w:=adres_ekle(simpat,3*sim);
    eğer t.dtz { dön ((bayt_oku(w,1)&0xf)<<8)|bayt_oku(w,0); }
    dön bayt_oku(w,0);
}
işlev tb_dosya_oku(yol:adres,boyut:adres):adres {
    utf:=dizi(131080); f:=dosya_aç_utf8(yol,"rb",utf,131080); eğer f==0 { dön 0; }
    dosya_konumla(f,0,2); n:=dosya_konumu(f); dosya_konumla(f,0,0);
    eğer n<=64 || n%64!=16 { dosya_kapat(f); dön 0; }

    p:=dosya_eşle(f,n);
    eğer p==0 {
        p=bellek_ayır(n); eğer p==0 { dosya_kapat(f); dön 0; }
        eğer dosya_oku(p,n,f)!=n { bellek_bırak(p); dosya_kapat(f); dön 0; }
        sayı_yaz(boyut,0,-n);
    } yoksa { sayı_yaz(boyut,0,n); }
    dosya_kapat(f); dön p;
}

işlev tb_tablo_hazırla(t:Tablo):i64 {
    eğer t.hazır { dön 1; }
    boy:=yerel_dizi(i64,1); p:=tb_dosya_oku(t.yol,adres(boy));
    eğer p==0 { t.hazır=-1; dön 0; }
    t.veri=p; t.eşlenmiş=seç(boy[0]>0,1,0); t.boyut=mutlak(boy[0]);
    sihir:=tb_u32(p);
    eğer (t.dtz==0 && sihir!=0x5d23e871) || (t.dtz!=0 && sihir!=0xa50c66d7) { t.hazır=-1; dön 0; }
    t.bölünmüş=bayt_oku(p,4)&1; t.dosyalar=seç((bayt_oku(p,4)&2)!=0,4,1);
    d:=adres_ekle(p,5); q:adres:=0;
    eğer t.piyonlu==0 {

        yinele(i:=0;i<t.num;i+=1) { v:=bayt_oku(d,i+1); t.parça[i]=u8(v&0xf); t.parça[7+i]=u8(v>>4); }
        sıra0:=bayt_oku(d,0)&0xf; sıra1:=bayt_oku(d,0)>>4;
        tb_norm_taş(t,0); t.boy[0]=tb_çarpan_taş(t,0,sıra0);
        eğer t.dtz==0 { tb_norm_taş(t,1); t.boy[1]=tb_çarpan_taş(t,1,sıra1); }
        d=adres_ekle(d,t.num+1); eğer (t.num+1+5)%2==1 { d=adres_ekle(d,1); }
        q=tb_çiftleri_kur(t,0,d,t.boy[0],0,seç(t.dtz==0,1,0)); t.bayrak[0]=bayt_oku(d,0); d=q;
        eğer t.dtz==0 && t.bölünmüş { q=tb_çiftleri_kur(t,1,d,t.boy[1],3,1); d=q; }
        eğer t.dtz!=0 {
            t.harita=d;
            eğer (t.bayrak[0]&2)!=0 {
                eğer (t.bayrak[0]&16)==0 { yinele(i:=0;i<4;i+=1) { t.harita_idx[i]=(i64(adres_bitleri(d))-i64(adres_bitleri(t.harita)))+1; d=adres_ekle(d,1+bayt_oku(d,0)); } }
                yoksa { yinele(i:=0;i<4;i+=1) { t.harita_idx[i]=((i64(adres_bitleri(d))-i64(adres_bitleri(t.harita)))+2)/2; d=adres_ekle(d,2+2*tb_u16(d)); } }
            }
            eğer (i64(adres_bitleri(d))-i64(adres_bitleri(p)))%2==1 { d=adres_ekle(d,1); }
        }
        ça_yaz(t,0,0,d); d=adres_ekle(d,t.büyüklük[0]);
        eğer t.dtz==0 && t.bölünmüş { ça_yaz(t,1,0,d); d=adres_ekle(d,t.büyüklük[3]); }
        ça_yaz(t,0,1,d); d=adres_ekle(d,t.büyüklük[1]);
        eğer t.dtz==0 && t.bölünmüş { ça_yaz(t,1,1,d); d=adres_ekle(d,t.büyüklük[4]); }
        d=adres_ekle(p,((i64(adres_bitleri(d))-i64(adres_bitleri(p)))+63)&~63); ça_yaz(t,0,2,d); d=adres_ekle(d,t.büyüklük[2]);
        eğer t.dtz==0 && t.bölünmüş { d=adres_ekle(p,((i64(adres_bitleri(d))-i64(adres_bitleri(p)))+63)&~63); ça_yaz(t,1,2,d); }
        t.anahtar=tb_parça_anahtarı(t,0,0); t.ayna=tb_parça_anahtarı(t,0,1);
    } yoksa {
        s:=1+seç(t.piyon1>0,1,0);
        yinele(f:=0;f<4;f+=1) {
            sıra0:=bayt_oku(d,0)&0xf; sıra20:=seç(t.piyon1!=0,bayt_oku(d,1)&0xf,0xf);
            sıra1:=bayt_oku(d,0)>>4; sıra21:=seç(t.piyon1!=0,bayt_oku(d,1)>>4,0xf);
            yinele(i:=0;i<t.num;i+=1) { v:=bayt_oku(d,i+s); t.parça[(f*2)*7+i]=u8(v&0xf); t.parça[(f*2+1)*7+i]=u8(v>>4); }
            tb_norm_piyon(t,f*2); t.boy[f*2]=tb_çarpan_piyon(t,f*2,sıra0,sıra20,f);
            eğer t.dtz==0 { tb_norm_piyon(t,f*2+1); t.boy[f*2+1]=tb_çarpan_piyon(t,f*2+1,sıra1,sıra21,f); }
            d=adres_ekle(d,t.num+s);
        }
        eğer (i64(adres_bitleri(d))-i64(adres_bitleri(p)))%2==1 { d=adres_ekle(d,1); }
        yinele(f:=0;f<t.dosyalar;f+=1) {
            q=tb_çiftleri_kur(t,f*2,d,t.boy[f*2],6*f,seç(t.dtz==0,1,0)); t.bayrak[f]=bayt_oku(d,0); d=q;
            eğer t.dtz==0 && t.bölünmüş { q=tb_çiftleri_kur(t,f*2+1,d,t.boy[f*2+1],6*f+3,1); d=q; }
        }
        eğer t.dtz!=0 {
            t.harita=d;
            yinele(f:=0;f<t.dosyalar;f+=1) {
                eğer (t.bayrak[f]&2)!=0 {
                    eğer (t.bayrak[f]&16)==0 { yinele(i:=0;i<4;i+=1) { t.harita_idx[f*4+i]=(i64(adres_bitleri(d))-i64(adres_bitleri(t.harita)))+1; d=adres_ekle(d,1+bayt_oku(d,0)); } }
                    yoksa {
                        eğer (i64(adres_bitleri(d))-i64(adres_bitleri(p)))%2==1 { d=adres_ekle(d,1); }
                        yinele(i:=0;i<4;i+=1) { t.harita_idx[f*4+i]=((i64(adres_bitleri(d))-i64(adres_bitleri(t.harita)))+2)/2; d=adres_ekle(d,2+2*tb_u16(d)); }
                    }
                }
            }
            eğer (i64(adres_bitleri(d))-i64(adres_bitleri(p)))%2==1 { d=adres_ekle(d,1); }
        }
        yinele(f:=0;f<t.dosyalar;f+=1) {
            ça_yaz(t,f*2,0,d); d=adres_ekle(d,t.büyüklük[6*f]);
            eğer t.dtz==0 && t.bölünmüş { ça_yaz(t,f*2+1,0,d); d=adres_ekle(d,t.büyüklük[6*f+3]); }
        }
        yinele(f:=0;f<t.dosyalar;f+=1) {
            ça_yaz(t,f*2,1,d); d=adres_ekle(d,t.büyüklük[6*f+1]);
            eğer t.dtz==0 && t.bölünmüş { ça_yaz(t,f*2+1,1,d); d=adres_ekle(d,t.büyüklük[6*f+4]); }
        }
        yinele(f:=0;f<t.dosyalar;f+=1) {
            d=adres_ekle(p,((i64(adres_bitleri(d))-i64(adres_bitleri(p)))+63)&~63); ça_yaz(t,f*2,2,d); d=adres_ekle(d,t.büyüklük[6*f+2]);
            eğer t.dtz==0 && t.bölünmüş { d=adres_ekle(p,((i64(adres_bitleri(d))-i64(adres_bitleri(p)))+63)&~63); ça_yaz(t,f*2+1,2,d); d=adres_ekle(d,t.büyüklük[6*f+5]); }
        }
    }
    t.hazır=1; dön 1;
}
işlev tb_tablo_bul(anahtar:u64,dtz:i64):i64 {
    yinele(i:=0;i<tb_sayısı;i+=1) {
        t:=tb_tablolar[i];
        eğer t.dtz==dtz && (t.anahtar==anahtar || t.ayna==anahtar) { dön i; }
    }
    dön -1;
}

işlev tb_taşları_diz(k:Konum,t:Tablo,yuva:i64,başla:i64,cayna:i64,ayna:i64,pos:adres):i64 {
    i:=başla;
    iken i<t.num {
        pc:=i64(t.parça[yuva*7+i]); tür_:=pc&7; renk_:=((pc^cayna)>>3)&1;
        bb:u64:=k.bit_tahtası[renk_*6+tür_];
        iken bb!=u64(0) { s:=ilk_bit(bb); bb=bb&(bb-u64(1)); sayı_yaz(pos,i,s^ayna); i+=1; }
    }
    dön i;
}
işlev tb_taraf_seç(k:Konum,t:Tablo,anahtar:u64,cayna:adres,ayna:adres):i64 {
    eğer !t.simetrik {
        eğer anahtar!=t.anahtar { sayı_yaz(cayna,0,8); sayı_yaz(ayna,0,0x38); dön seç(k.sıra==0,1,0); }
        sayı_yaz(cayna,0,0); sayı_yaz(ayna,0,0); dön seç(k.sıra!=0,1,0);
    }
    sayı_yaz(cayna,0,seç(k.sıra==0,0,8)); sayı_yaz(ayna,0,seç(k.sıra==0,0,0x38)); dön 0;
}

işlev tb_wdl_tablo(k:Konum):i64 {
    eğer bit_say(dolu(k))==2 { dön 0; }
    anahtar:=tb_konum_anahtarı(k); ti:=tb_tablo_bul(anahtar,0); eğer ti<0 { dön 3; }
    t:=tb_tablolar[ti];
    eğer !t.hazır { kilit_al(&tb_kilit); tb_tablo_hazırla(t); kilit_bırak(&tb_kilit); }
    eğer t.hazır<0 { dön 3; }
    cayna:=yerel_dizi(i64,1); ayna:=yerel_dizi(i64,1); pos:=yerel_dizi(i64,8);
    taraf:=tb_taraf_seç(k,t,anahtar,adres(cayna),adres(ayna));
    eğer t.piyonlu==0 {
        tb_taşları_diz(k,t,taraf,0,cayna[0],0,adres(pos));
        idx:=tb_taş_kodla(t,taraf,adres(pos));
        dön tb_çöz(t,taraf,idx)-2;
    }
    pc:=i64(t.parça[0])^cayna[0]; bb:u64:=k.bit_tahtası[((pc>>3)&1)*6+(pc&7)]; i:=0;
    iken bb!=u64(0) { s:=ilk_bit(bb); bb=bb&(bb-u64(1)); pos[i]=s^ayna[0]; i+=1; }
    f:=tb_piyon_dosyası(t,adres(pos)); yuva:=f*2+taraf;
    tb_taşları_diz(k,t,yuva,i,cayna[0],ayna[0],adres(pos));
    idx:=tb_piyon_kodla(t,yuva,adres(pos));
    dön tb_çöz(t,yuva,idx)-2;
}

işlev tb_dtz_tablo(k:Konum,wdl:i64,başarı:adres):i64 {
    anahtar:=tb_konum_anahtarı(k); ti:=tb_tablo_bul(anahtar,1); eğer ti<0 { sayı_yaz(başarı,0,-2); dön 0; }
    t:=tb_tablolar[ti];
    eğer !t.hazır { kilit_al(&tb_kilit); tb_tablo_hazırla(t); kilit_bırak(&tb_kilit); }
    eğer t.hazır<0 { sayı_yaz(başarı,0,-2); dön 0; }
    cayna:=yerel_dizi(i64,1); ayna:=yerel_dizi(i64,1); pos:=yerel_dizi(i64,8);
    taraf:=tb_taraf_seç(k,t,anahtar,adres(cayna),adres(ayna)); sonuç:=0; f:=0;
    eğer t.piyonlu==0 {
        eğer (t.bayrak[0]&1)!=taraf && !t.simetrik { sayı_yaz(başarı,0,-1); dön 0; }
        tb_taşları_diz(k,t,0,0,cayna[0],0,adres(pos));
        idx:=tb_taş_kodla(t,0,adres(pos)); sonuç=tb_çöz(t,0,idx);
    } yoksa {
        pc:=i64(t.parça[0])^cayna[0]; bb:u64:=k.bit_tahtası[((pc>>3)&1)*6+(pc&7)]; i:=0;
        iken bb!=u64(0) { s:=ilk_bit(bb); bb=bb&(bb-u64(1)); pos[i]=s^ayna[0]; i+=1; }
        f=tb_piyon_dosyası(t,adres(pos));
        eğer (t.bayrak[f]&1)!=taraf { sayı_yaz(başarı,0,-1); dön 0; }
        tb_taşları_diz(k,t,f*2,i,cayna[0],ayna[0],adres(pos));
        idx:=tb_piyon_kodla(t,f*2,adres(pos)); sonuç=tb_çöz(t,f*2,idx);
    }
    bayrak:=t.bayrak[f];
    eğer (bayrak&2)!=0 {
        hi:=t.harita_idx[f*4+tb_wdl_harita[wdl+2]];
        eğer (bayrak&16)==0 { sonuç=bayt_oku(t.harita,hi+sonuç); }
        yoksa { sonuç=tb_u16(adres_ekle(t.harita,2*(hi+sonuç))); }
    }
    eğer (bayrak&tb_pa_bayrak[wdl+2])==0 || (wdl&1)!=0 { sonuç*=2; }
    sayı_yaz(başarı,0,1); dön sonuç;
}

işlev tb_wdl_ab(k:Konum,alfa:i64,beta:i64,başarı:adres):i64 {
    l:=yerel(Hamleler); yasal_alışlar(k,l); g:=yerel(İz); alt:=yerel_dizi(i64,1);
    yinele(i:=0;i<l.adet;i+=1) {
        h:=i64(l.hamle[i]); eğer hamle_türü(h)==GEÇERKEN || alınan_taş(k,h)==0 { sürdür; }
        ilerle(k,h,g); v:=-tb_wdl_ab(k,-beta,-alfa,adres(alt)); geri(k,g);
        eğer v==-3 || v==3 { dön 3; }
        eğer v>alfa { eğer v>=beta { sayı_yaz(başarı,0,2); dön v; } alfa=v; }
    }
    v:=tb_wdl_tablo(k); eğer v==3 { dön 3; }
    eğer alfa>=v { sayı_yaz(başarı,0,1+seç(alfa>0,1,0)); dön alfa; }
    sayı_yaz(başarı,0,1); dön v;
}
işlev tb_geçerken_var(k:Konum):i64 {
    l:=yerel(Hamleler); yasal_hamleler(k,l);
    yinele(i:=0;i<l.adet;i+=1) { eğer hamle_türü(i64(l.hamle[i]))==GEÇERKEN { dön 1; } }
    dön 0;
}

işlev tb_wdl(k:Konum):i64 {
    eğer k.rok!=0 { dön 3; }
    eğer bit_say(dolu(k))>tb_en_büyük+1 { dön 3; }
    eğer bit_say(dolu(k))==2 { dön 0; }
    başarı:=yerel_dizi(i64,1); v:=tb_wdl_ab(k,-2,2,adres(başarı)); eğer v==3 { dön 3; }
    eğer k.geçer<0 { dön v; }
    l:=yerel(Hamleler); yasal_hamleler(k,l); g:=yerel(İz); v1:=-3; başka:=0;
    yinele(i:=0;i<l.adet;i+=1) {
        h:=i64(l.hamle[i]);
        eğer hamle_türü(h)!=GEÇERKEN { başka=1; sürdür; }
        ilerle(k,h,g); v0:=-tb_wdl_ab(k,-2,2,adres(başarı)); geri(k,g);
        eğer v0==-3 || v0==3 { dön 3; }
        eğer v0>v1 { v1=v0; }
    }
    eğer v1>-3 {
        eğer v1>=v { v=v1; }
        yoksa eğer v==0 && !başka { v=v1; }
    }
    dön v;
}
işlev tb_sıfırlama_öncesi(wdl:i64):i64 { dön seç(wdl>0,1,seç(wdl<0,-1,0))*seç(mutlak(wdl)==2,1,101); }
işlev tb_mat_mı(k:Konum):i64 { l:=yerel(Hamleler); yasal_hamleler(k,l); dön l.adet==0 && şah_tehditte(k); }

işlev tb_dtz_geçerkensiz(k:Konum):i64 {
    başarı:=yerel_dizi(i64,1); wdl:=tb_wdl_ab(k,-2,2,adres(başarı));
    eğer wdl==3 { dön 0x7fff; }
    eğer wdl==0 { dön 0; }
    dost_piyonsuz:=(k.renkler[k.sıra]&~k.bit_tahtası[k.sıra*6+1])==u64(0);
    eğer başarı[0]==2 || dost_piyonsuz { dön tb_sıfırlama_öncesi(wdl); }
    l:=yerel(Hamleler); g:=yerel(İz);
    eğer wdl>0 {
        yasal_hamleler(k,l);
        yinele(i:=0;i<l.adet;i+=1) {
            h:=i64(l.hamle[i]);
            eğer tür(i64(k.tahta[kaynak(h)]))!=1 || alınan_taş(k,h)!=0 || hamle_türü(h)==GEÇERKEN { sürdür; }
            ilerle(k,h,g); v:=-tb_wdl(k); geri(k,g);
            eğer v==-3 || v==3 { dön 0x7fff; }
            eğer v==wdl { dön seç(v==2,1,101); }
        }
    }
    ok:=yerel_dizi(i64,1); dtz:=tb_dtz_tablo(k,wdl,adres(ok));
    eğer ok[0]==-2 { dön 0x7fff; }
    eğer ok[0]>=0 { dön tb_sıfırlama_öncesi(wdl)+seç(wdl>0,dtz,-dtz); }
    yasal_hamleler(k,l);
    eğer wdl>0 {
        eniyi:=0xffff;
        yinele(i:=0;i<l.adet;i+=1) {
            h:=i64(l.hamle[i]);
            eğer tür(i64(k.tahta[kaynak(h)]))==1 || alınan_taş(k,h)!=0 || hamle_türü(h)==GEÇERKEN { sürdür; }
            ilerle(k,h,g); v:=-tb_dtz(k); mat:=v==1 && tb_mat_mı(k); geri(k,g);
            eğer v==-0x7fff || v==0x7fff { dön 0x7fff; }
            eğer mat { eniyi=1; } yoksa eğer v>0 && v+1<eniyi { eniyi=v+1; }
        }
        dön eniyi;
    }
    eniyi:=-1;
    yinele(i:=0;i<l.adet;i+=1) {
        h:=i64(l.hamle[i]); ilerle(k,h,g); v:=0;
        eğer k.elli==0 {
            eğer wdl==-2 { v=-1; }
            yoksa { w:=tb_wdl_ab(k,1,2,adres(başarı)); eğer w==3 { geri(k,g); dön 0x7fff; } v=seç(w==2,0,-101); }
        } yoksa { d:=tb_dtz(k); eğer d==0x7fff || d==-0x7fff { geri(k,g); dön 0x7fff; } v=-d-1; }
        geri(k,g);
        eğer v<eniyi { eniyi=v; }
    }
    dön eniyi;
}
işlev tb_dtz(k:Konum):i64 {
    eğer k.rok!=0 || bit_say(dolu(k))>tb_en_büyük { dön 0x7fff; }
    v:=tb_dtz_geçerkensiz(k); eğer v==0x7fff || k.geçer<0 { dön v; }
    l:=yerel(Hamleler); yasal_hamleler(k,l); g:=yerel(İz); başarı:=yerel_dizi(i64,1); v1:=-3; başka:=0;
    yinele(i:=0;i<l.adet;i+=1) {
        h:=i64(l.hamle[i]);
        eğer hamle_türü(h)!=GEÇERKEN { başka=1; sürdür; }
        ilerle(k,h,g); v0:=-tb_wdl_ab(k,-2,2,adres(başarı)); geri(k,g);
        eğer v0==-3 || v0==3 { dön 0x7fff; }
        eğer v0>v1 { v1=v0; }
    }
    eğer v1>-3 {
        v1=seç(v1>0,1,seç(v1<0,-1,0))*seç(mutlak(v1)==2,1,101);
        eğer v<-100 { eğer v1>=0 { v=v1; } }
        yoksa eğer v<0 { eğer v1>=0 || v1<-100 { v=v1; } }
        yoksa eğer v>100 { eğer v1>0 { v=v1; } }
        yoksa eğer v>0 { eğer v1==1 { v=v1; } }
        yoksa eğer v1>=0 { v=v1; }
        yoksa eğer !başka { v=v1; }
    }
    dön v;
}

işlev tb_kaydet(ad:adres,dtz:i64):i64 {
    eğer tb_sayısı>=3300 { dön 0; }
    yol:=bellek_ayır(4096); u:=metin_uzunluğu(tb_yol); bellek_kopyala(yol,tb_yol,u);
    bayt_yaz(yol,u,47); u+=1; n:=metin_uzunluğu(ad); bellek_kopyala(adres_ekle(yol,u),ad,n); u+=n;
    bellek_kopyala(adres_ekle(yol,u),seç(dtz,".rtbz",".rtbw"),6);
    utf:=dizi(131080); f:=dosya_aç_utf8(yol,"rb",utf,131080);
    eğer f==0 { bellek_bırak(yol); dön 0; }
    dosya_kapat(f);
    t:=tb_tablolar[tb_sayısı]; bellek_sıfırla(adres(t),boyut(Tablo)); t.yol=yol; t.dtz=dtz; t.cyer=bellek_ayır(8*16*8); bellek_sıfırla(t.cyer,8*16*8);

    a:u64:=u64(0); renk_:=0; beyaz_p:=0; siyah_p:=0; tekler:=0; ayrı:=yerel_dizi(i64,14); yinele(i:=0;i<14;i+=1) { ayrı[i]=0; }
    yinele(i:=0;i<n;i+=1) {
        c:=bayt_oku(ad,i);
        eğer c==118 { renk_=1; sürdür; }
        tür_:=seç(c==75,6,seç(c==81,5,seç(c==82,4,seç(c==66,3,seç(c==78,2,1)))));
        a=tb_anahtar_ekle(a,renk_,tür_,1); ayrı[renk_*7+tür_]+=1;
        eğer tür_==1 { eğer renk_==0 { beyaz_p+=1; } yoksa { siyah_p+=1; } }
    }
    t.num=n-1; t.anahtar=a; t.ayna=tb_anahtar_ayna(a); t.simetrik=t.anahtar==t.ayna;
    t.piyonlu=beyaz_p+siyah_p>0;
    eğer t.piyonlu { t.piyon0=beyaz_p; t.piyon1=siyah_p; eğer t.piyon1>0 && (t.piyon0==0 || t.piyon1<t.piyon0) { x:=t.piyon0; t.piyon0=t.piyon1; t.piyon1=x; } }
    yoksa { yinele(i:=0;i<14;i+=1) { eğer ayrı[i]==1 { tekler+=1; } } t.kodlama=seç(tekler>=3,0,2); }
    tb_sayısı+=1; eğer t.num>tb_en_büyük { tb_en_büyük=t.num; } dön 1;
}
işlev tb_adı_yaz(b:adres,w:adres,wn:i64,bl:adres,bn:i64) {
    n:=0; bayt_yaz(b,n,75); n+=1;
    yinele(i:=0;i<wn;i+=1) { bayt_yaz(b,n,bayt_oku(w,i)); n+=1; }
    bayt_yaz(b,n,118); n+=1; bayt_yaz(b,n,75); n+=1;
    yinele(i:=0;i<bn;i+=1) { bayt_yaz(b,n,bayt_oku(bl,i)); n+=1; }
    bayt_yaz(b,n,0);
}

işlev tb_yükle(yol:adres):i64 {
    tb_sabitleri_kur(); tb_sayısı=0; tb_en_büyük=0;
    eğer adres(tb_tablolar)==0 { tb_tablolar=yeni_dizi(Tablo,3300); eğer adres(tb_tablolar)==0 { dön 0; } }
    eğer tb_yol!=0 { bellek_bırak(tb_yol); } n:=metin_uzunluğu(yol); tb_yol=bellek_ayır(n+1); bellek_kopyala(tb_yol,yol,n+1);
    harfler:="QRBNP"; w:=dizi(8); bl:=dizi(8); ad:=dizi(16);

    yinele(wn:=0;wn<=5;wn+=1) { yinele(bn:=0;bn<=wn;bn+=1) {
        eğer 2+wn+bn>7 { sürdür; }
        wk:=yerel_dizi(i64,8); yinele(i:=0;i<wn;i+=1) { wk[i]=0; }
        iken 1 {
            bk:=yerel_dizi(i64,8); yinele(i:=0;i<bn;i+=1) { bk[i]=0; }
            iken 1 {
                yinele(i:=0;i<wn;i+=1) { bayt_yaz(w,i,bayt_oku(harfler,wk[i])); }
                yinele(i:=0;i<bn;i+=1) { bayt_yaz(bl,i,bayt_oku(harfler,bk[i])); }
                tb_adı_yaz(ad,w,wn,bl,bn);
                eğer tb_kaydet(ad,0) { tb_kaydet(ad,1); }

                j:=bn-1; iken j>=0 && bk[j]==4 { j-=1; } eğer j<0 { kır; }
                bk[j]+=1; yinele(i:=j+1;i<bn;i+=1) { bk[i]=bk[j]; }
            }
            j:=wn-1; iken j>=0 && wk[j]==4 { j-=1; } eğer j<0 { kır; }
            wk[j]+=1; yinele(i:=j+1;i<wn;i+=1) { wk[i]=wk[j]; }
        }
    } }
    dön tb_sayısı;
}
işlev tb_boşalt() {
    yinele(i:=0;i<tb_sayısı;i+=1) {
        t:=tb_tablolar[i];
        eğer t.veri!=0 { eğer t.eşlenmiş { dosya_eşlemeyi_bırak(t.veri,t.boyut); } yoksa { bellek_bırak(t.veri); } t.veri=0; }
        eğer t.cyer!=0 { yinele(j:=0;j<8;j+=1) { eğer ça(t,j,4)!=0 { bellek_bırak(ça(t,j,4)); } } bellek_bırak(t.cyer); t.cyer=0; }
        eğer t.yol!=0 { bellek_bırak(t.yol); t.yol=0; }
        t.hazır=0;
    }
    tb_sayısı=0; tb_en_büyük=0;
}

işlev tb_kök_kısıtla():i64 {
    eğer tb_sayısı==0 || oyun.rok!=0 || kök_sayısı<=1 || bit_say(dolu(oyun))>tb_en_büyük { dön 0; }
    g:=yerel(İz); sıra:=yerel_dizi(i64,512); en_yüksek:=-2000000;
    yinele(i:=0;i<kök_sayısı;i+=1) {
        h:=kökler[i].hamle; ilerle(oyun,h,g); sıfırlayan:=oyun.elli==0; v:=0;
        eğer sıfırlayan { w:=-tb_wdl(oyun); eğer w==-3 || w==3 { geri(oyun,g); dön 0; } v=tb_sıfırlama_öncesi(w); }
        yoksa { d:=tb_dtz(oyun); eğer d==0x7fff || d==-0x7fff { geri(oyun,g); dön 0; } v=-d; eğer v>0 { v+=1; } yoksa eğer v<0 { v-=1; } }
        geri(oyun,g);
        r:=0;
        eğer v>0 { r=seç(v+oyun.elli<=99,1000-v,0); }
        yoksa eğer v<0 { r=seç(-v+oyun.elli<100,-1000-v,0); }
        sıra[i]=r; eğer r>en_yüksek { en_yüksek=r; }
    }
    yeni:=0;
    yinele(i:=0;i<kök_sayısı;i+=1) { eğer sıra[i]==en_yüksek { kökler[yeni].hamle=kökler[i].hamle; yeni+=1; } }
    elenen:=kök_sayısı-yeni; kök_sayısı=yeni; tb_kök_puanı=seç(en_yüksek>0,TB_KAZANÇ,seç(en_yüksek<0,-TB_KAZANÇ,0));
    kilit_al(&çıktı_kilidi); yaz("info string tablebase kok: "); rakam(yeni); yaz(" hamle, sira "); rakam(en_yüksek); satır_sonu(); dosya_boşalt(çıktı); kilit_bırak(&çıktı_kilidi);
    dön elenen>0;
}
işlev tb_sonda_yaz(k:Konum) {
    kilit_al(&çıktı_kilidi);
    eğer tb_sayısı==0 { metin_satırı("info string tablebase yuklu degil"); }
    yoksa {
        w:=tb_wdl(k); yaz("info string tb wdl ");
        eğer w==3 { yaz("yok"); } yoksa { rakam(w); d:=tb_dtz(k); yaz(" dtz "); eğer d==0x7fff { yaz("yok"); } yoksa { rakam(d); } }
        satır_sonu();
    }
    dosya_boşalt(çıktı); kilit_bırak(&çıktı_kilidi);
}

tablo kitap_rastgele:u64[781]={
u64(0x9d39247e33776d41),u64(0x2af7398005aaa5c7),u64(0x44db015024623547),u64(0x9c15f73e62a76ae2),
u64(0x75834465489c0c89),u64(0x3290ac3a203001bf),u64(0x0fbbad1f61042279),u64(0xe83a908ff2fb60ca),
u64(0x0d7e765d58755c10),u64(0x1a083822ceafe02d),u64(0x9605d5f0e25ec3b0),u64(0xd021ff5cd13a2ed5),
u64(0x40bdf15d4a672e32),u64(0x011355146fd56395),u64(0x5db4832046f3d9e5),u64(0x239f8b2d7ff719cc),
u64(0x05d1a1ae85b49aa1),u64(0x679f848f6e8fc971),u64(0x7449bbff801fed0b),u64(0x7d11cdb1c3b7adf0),
u64(0x82c7709e781eb7cc),u64(0xf3218f1c9510786c),u64(0x331478f3af51bbe6),u64(0x4bb38de5e7219443),
u64(0xaa649c6ebcfd50fc),u64(0x8dbd98a352afd40b),u64(0x87d2074b81d79217),u64(0x19f3c751d3e92ae1),
u64(0xb4ab30f062b19abf),u64(0x7b0500ac42047ac4),u64(0xc9452ca81a09d85d),u64(0x24aa6c514da27500),
u64(0x4c9f34427501b447),u64(0x14a68fd73c910841),u64(0xa71b9b83461cbd93),u64(0x03488b95b0f1850f),
u64(0x637b2b34ff93c040),u64(0x09d1bc9a3dd90a94),u64(0x3575668334a1dd3b),u64(0x735e2b97a4c45a23),
u64(0x18727070f1bd400b),u64(0x1fcbacd259bf02e7),u64(0xd310a7c2ce9b6555),u64(0xbf983fe0fe5d8244),
u64(0x9f74d14f7454a824),u64(0x51ebdc4ab9ba3035),u64(0x5c82c505db9ab0fa),u64(0xfcf7fe8a3430b241),
u64(0x3253a729b9ba3dde),u64(0x8c74c368081b3075),u64(0xb9bc6c87167c33e7),u64(0x7ef48f2b83024e20),
u64(0x11d505d4c351bd7f),u64(0x6568fca92c76a243),u64(0x4de0b0f40f32a7b8),u64(0x96d693460cc37e5d),
u64(0x42e240cb63689f2f),u64(0x6d2bdcdae2919661),u64(0x42880b0236e4d951),u64(0x5f0f4a5898171bb6),
u64(0x39f890f579f92f88),u64(0x93c5b5f47356388b),u64(0x63dc359d8d231b78),u64(0xec16ca8aea98ad76),
u64(0x5355f900c2a82dc7),u64(0x07fb9f855a997142),u64(0x5093417aa8a7ed5e),u64(0x7bcbc38da25a7f3c),
u64(0x19fc8a768cf4b6d4),u64(0x637a7780decfc0d9),u64(0x8249a47aee0e41f7),u64(0x79ad695501e7d1e8),
u64(0x14acbaf4777d5776),u64(0xf145b6beccdea195),u64(0xdabf2ac8201752fc),u64(0x24c3c94df9c8d3f6),
u64(0xbb6e2924f03912ea),u64(0x0ce26c0b95c980d9),u64(0xa49cd132bfbf7cc4),u64(0xe99d662af4243939),
u64(0x27e6ad7891165c3f),u64(0x8535f040b9744ff1),u64(0x54b3f4fa5f40d873),u64(0x72b12c32127fed2b),
u64(0xee954d3c7b411f47),u64(0x9a85ac909a24eaa1),u64(0x70ac4cd9f04f21f5),u64(0xf9b89d3e99a075c2),
u64(0x87b3e2b2b5c907b1),u64(0xa366e5b8c54f48b8),u64(0xae4a9346cc3f7cf2),u64(0x1920c04d47267bbd),
u64(0x87bf02c6b49e2ae9),u64(0x092237ac237f3859),u64(0xff07f64ef8ed14d0),u64(0x8de8dca9f03cc54e),
u64(0x9c1633264db49c89),u64(0xb3f22c3d0b0b38ed),u64(0x390e5fb44d01144b),u64(0x5bfea5b4712768e9),
u64(0x1e1032911fa78984),u64(0x9a74acb964e78cb3),u64(0x4f80f7a035dafb04),u64(0x6304d09a0b3738c4),
u64(0x2171e64683023a08),u64(0x5b9b63eb9ceff80c),u64(0x506aacf489889342),u64(0x1881afc9a3a701d6),
u64(0x6503080440750644),u64(0xdfd395339cdbf4a7),u64(0xef927dbcf00c20f2),u64(0x7b32f7d1e03680ec),
u64(0xb9fd7620e7316243),u64(0x05a7e8a57db91b77),u64(0xb5889c6e15630a75),u64(0x4a750a09ce9573f7),
u64(0xcf464cec899a2f8a),u64(0xf538639ce705b824),u64(0x3c79a0ff5580ef7f),u64(0xede6c87f8477609d),
u64(0x799e81f05bc93f31),u64(0x86536b8cf3428a8c),u64(0x97d7374c60087b73),u64(0xa246637cff328532),
u64(0x043fcae60cc0eba0),u64(0x920e449535dd359e),u64(0x70eb093b15b290cc),u64(0x73a1921916591cbd),
u64(0x56436c9fe1a1aa8d),u64(0xefac4b70633b8f81),u64(0xbb215798d45df7af),u64(0x45f20042f24f1768),
u64(0x930f80f4e8eb7462),u64(0xff6712ffcfd75ea1),u64(0xae623fd67468aa70),u64(0xdd2c5bc84bc8d8fc),
u64(0x7eed120d54cf2dd9),u64(0x22fe545401165f1c),u64(0xc91800e98fb99929),u64(0x808bd68e6ac10365),
u64(0xdec468145b7605f6),u64(0x1bede3a3aef53302),u64(0x43539603d6c55602),u64(0xaa969b5c691ccb7a),
u64(0xa87832d392efee56),u64(0x65942c7b3c7e11ae),u64(0xded2d633cad004f6),u64(0x21f08570f420e565),
u64(0xb415938d7da94e3c),u64(0x91b859e59ecb6350),u64(0x10cff333e0ed804a),u64(0x28aed140be0bb7dd),
u64(0xc5cc1d89724fa456),u64(0x5648f680f11a2741),u64(0x2d255069f0b7dab3),u64(0x9bc5a38ef729abd4),
u64(0xef2f054308f6a2bc),u64(0xaf2042f5cc5c2858),u64(0x480412bab7f5be2a),u64(0xaef3af4a563dfe43),
u64(0x19afe59ae451497f),u64(0x52593803dff1e840),u64(0xf4f076e65f2ce6f0),u64(0x11379625747d5af3),
u64(0xbce5d2248682c115),u64(0x9da4243de836994f),u64(0x066f70b33fe09017),u64(0x4dc4de189b671a1c),
u64(0x51039ab7712457c3),u64(0xc07a3f80c31fb4b4),u64(0xb46ee9c5e64a6e7c),u64(0xb3819a42abe61c87),
u64(0x21a007933a522a20),u64(0x2df16f761598aa4f),u64(0x763c4a1371b368fd),u64(0xf793c46702e086a0),
u64(0xd7288e012aeb8d31),u64(0xde336a2a4bc1c44b),u64(0x0bf692b38d079f23),u64(0x2c604a7a177326b3),
u64(0x4850e73e03eb6064),u64(0xcfc447f1e53c8e1b),u64(0xb05ca3f564268d99),u64(0x9ae182c8bc9474e8),
u64(0xa4fc4bd4fc5558ca),u64(0xe755178d58fc4e76),u64(0x69b97db1a4c03dfe),u64(0xf9b5b7c4acc67c96),
u64(0xfc6a82d64b8655fb),u64(0x9c684cb6c4d24417),u64(0x8ec97d2917456ed0),u64(0x6703df9d2924e97e),
u64(0xc547f57e42a7444e),u64(0x78e37644e7cad29e),u64(0xfe9a44e9362f05fa),u64(0x08bd35cc38336615),
u64(0x9315e5eb3a129ace),u64(0x94061b871e04df75),u64(0xdf1d9f9d784ba010),u64(0x3bba57b68871b59d),
u64(0xd2b7adeeded1f73f),u64(0xf7a255d83bc373f8),u64(0xd7f4f2448c0ceb81),u64(0xd95be88cd210ffa7),
u64(0x336f52f8ff4728e7),u64(0xa74049dac312ac71),u64(0xa2f61bb6e437fdb5),u64(0x4f2a5cb07f6a35b3),
u64(0x87d380bda5bf7859),u64(0x16b9f7e06c453a21),u64(0x7ba2484c8a0fd54e),u64(0xf3a678cad9a2e38c),
u64(0x39b0bf7dde437ba2),u64(0xfcaf55c1bf8a4424),u64(0x18fcf680573fa594),u64(0x4c0563b89f495ac3),
u64(0x40e087931a00930d),u64(0x8cffa9412eb642c1),u64(0x68ca39053261169f),u64(0x7a1ee967d27579e2),
u64(0x9d1d60e5076f5b6f),u64(0x3810e399b6f65ba2),u64(0x32095b6d4ab5f9b1),u64(0x35cab62109dd038a),
u64(0xa90b24499fcfafb1),u64(0x77a225a07cc2c6bd),u64(0x513e5e634c70e331),u64(0x4361c0ca3f692f12),
u64(0xd941aca44b20a45b),u64(0x528f7c8602c5807b),u64(0x52ab92beb9613989),u64(0x9d1dfa2efc557f73),
u64(0x722ff175f572c348),u64(0x1d1260a51107fe97),u64(0x7a249a57ec0c9ba2),u64(0x04208fe9e8f7f2d6),
u64(0x5a110c6058b920a0),u64(0x0cd9a497658a5698),u64(0x56fd23c8f9715a4c),u64(0x284c847b9d887aae),
u64(0x04feabfbbdb619cb),u64(0x742e1e651c60ba83),u64(0x9a9632e65904ad3c),u64(0x881b82a13b51b9e2),
u64(0x506e6744cd974924),u64(0xb0183db56ffc6a79),u64(0x0ed9b915c66ed37e),u64(0x5e11e86d5873d484),
u64(0xf678647e3519ac6e),u64(0x1b85d488d0f20cc5),u64(0xdab9fe6525d89021),u64(0x0d151d86adb73615),
u64(0xa865a54edcc0f019),u64(0x93c42566aef98ffb),u64(0x99e7afeabe000731),u64(0x48cbff086ddf285a),
u64(0x7f9b6af1ebf78baf),u64(0x58627e1a149bba21),u64(0x2cd16e2abd791e33),u64(0xd363eff5f0977996),
u64(0x0ce2a38c344a6eed),u64(0x1a804aadb9cfa741),u64(0x907f30421d78c5de),u64(0x501f65edb3034d07),
u64(0x37624ae5a48fa6e9),u64(0x957baf61700cff4e),u64(0x3a6c27934e31188a),u64(0xd49503536abca345),
u64(0x088e049589c432e0),u64(0xf943aee7febf21b8),u64(0x6c3b8e3e336139d3),u64(0x364f6ffa464ee52e),
u64(0xd60f6dcedc314222),u64(0x56963b0dca418fc0),u64(0x16f50edf91e513af),u64(0xef1955914b609f93),
u64(0x565601c0364e3228),u64(0xecb53939887e8175),u64(0xbac7a9a18531294b),u64(0xb344c470397bba52),
u64(0x65d34954daf3cebd),u64(0xb4b81b3fa97511e2),u64(0xb422061193d6f6a7),u64(0x071582401c38434d),
u64(0x7a13f18bbedc4ff5),u64(0xbc4097b116c524d2),u64(0x59b97885e2f2ea28),u64(0x99170a5dc3115544),
u64(0x6f423357e7c6a9f9),u64(0x325928ee6e6f8794),u64(0xd0e4366228b03343),u64(0x565c31f7de89ea27),
u64(0x30f5611484119414),u64(0xd873db391292ed4f),u64(0x7bd94e1d8e17debc),u64(0xc7d9f16864a76e94),
u64(0x947ae053ee56e63c),u64(0xc8c93882f9475f5f),u64(0x3a9bf55ba91f81ca),u64(0xd9a11fbb3d9808e4),
u64(0x0fd22063edc29fca),u64(0xb3f256d8aca0b0b9),u64(0xb03031a8b4516e84),u64(0x35dd37d5871448af),
u64(0xe9f6082b05542e4e),u64(0xebfafa33d7254b59),u64(0x9255abb50d532280),u64(0xb9ab4ce57f2d34f3),
u64(0x693501d628297551),u64(0xc62c58f97dd949bf),u64(0xcd454f8f19c5126a),u64(0xbbe83f4ecc2bdecb),
u64(0xdc842b7e2819e230),u64(0xba89142e007503b8),u64(0xa3bc941d0a5061cb),u64(0xe9f6760e32cd8021),
u64(0x09c7e552bc76492f),u64(0x852f54934da55cc9),u64(0x8107fccf064fcf56),u64(0x098954d51fff6580),
u64(0x23b70edb1955c4bf),u64(0xc330de426430f69d),u64(0x4715ed43e8a45c0a),u64(0xa8d7e4dab780a08d),
u64(0x0572b974f03ce0bb),u64(0xb57d2e985e1419c7),u64(0xe8d9ecbe2cf3d73f),u64(0x2fe4b17170e59750),
u64(0x11317ba87905e790),u64(0x7fbf21ec8a1f45ec),u64(0x1725cabfcb045b00),u64(0x964e915cd5e2b207),
u64(0x3e2b8bcbf016d66d),u64(0xbe7444e39328a0ac),u64(0xf85b2b4fbcde44b7),u64(0x49353fea39ba63b1),
u64(0x1dd01aafcd53486a),u64(0x1fca8a92fd719f85),u64(0xfc7c95d827357afa),u64(0x18a6a990c8b35ebd),
u64(0xcccb7005c6b9c28d),u64(0x3bdbb92c43b17f26),u64(0xaa70b5b4f89695a2),u64(0xe94c39a54a98307f),
u64(0xb7a0b174cff6f36e),u64(0xd4dba84729af48ad),u64(0x2e18bc1ad9704a68),u64(0x2de0966daf2f8b1c),
u64(0xb9c11d5b1e43a07e),u64(0x64972d68dee33360),u64(0x94628d38d0c20584),u64(0xdbc0d2b6ab90a559),
u64(0xd2733c4335c6a72f),u64(0x7e75d99d94a70f4d),u64(0x6ced1983376fa72b),u64(0x97fcaacbf030bc24),
u64(0x7b77497b32503b12),u64(0x8547eddfb81ccb94),u64(0x79999cdff70902cb),u64(0xcffe1939438e9b24),
u64(0x829626e3892d95d7),u64(0x92fae24291f2b3f1),u64(0x63e22c147b9c3403),u64(0xc678b6d860284a1c),
u64(0x5873888850659ae7),u64(0x0981dcd296a8736d),u64(0x9f65789a6509a440),u64(0x9ff38fed72e9052f),
u64(0xe479ee5b9930578c),u64(0xe7f28ecd2d49eecd),u64(0x56c074a581ea17fe),u64(0x5544f7d774b14aef),
u64(0x7b3f0195fc6f290f),u64(0x12153635b2c0cf57),u64(0x7f5126dbba5e0ca7),u64(0x7a76956c3eafb413),
u64(0x3d5774a11d31ab39),u64(0x8a1b083821f40cb4),u64(0x7b4a38e32537df62),u64(0x950113646d1d6e03),
u64(0x4da8979a0041e8a9),u64(0x3bc36e078f7515d7),u64(0x5d0a12f27ad310d1),u64(0x7f9d1a2e1ebe1327),
u64(0xda3a361b1c5157b1),u64(0xdcdd7d20903d0c25),u64(0x36833336d068f707),u64(0xce68341f79893389),
u64(0xab9090168dd05f34),u64(0x43954b3252dc25e5),u64(0xb438c2b67f98e5e9),u64(0x10dcd78e3851a492),
u64(0xdbc27ab5447822bf),u64(0x9b3cdb65f82ca382),u64(0xb67b7896167b4c84),u64(0xbfced1b0048eac50),
u64(0xa9119b60369ffebd),u64(0x1fff7ac80904bf45),u64(0xac12fb171817eee7),u64(0xaf08da9177dda93d),
u64(0x1b0cab936e65c744),u64(0xb559eb1d04e5e932),u64(0xc37b45b3f8d6f2ba),u64(0xc3a9dc228caac9e9),
u64(0xf3b8b6675a6507ff),u64(0x9fc477de4ed681da),u64(0x67378d8eccef96cb),u64(0x6dd856d94d259236),
u64(0xa319ce15b0b4db31),u64(0x073973751f12dd5e),u64(0x8a8e849eb32781a5),u64(0xe1925c71285279f5),
u64(0x74c04bf1790c0efe),u64(0x4dda48153c94938a),u64(0x9d266d6a1cc0542c),u64(0x7440fb816508c4fe),
u64(0x13328503df48229f),u64(0xd6bf7baee43cac40),u64(0x4838d65f6ef6748f),u64(0x1e152328f3318dea),
u64(0x8f8419a348f296bf),u64(0x72c8834a5957b511),u64(0xd7a023a73260b45c),u64(0x94ebc8abcfb56dae),
u64(0x9fc10d0f989993e0),u64(0xde68a2355b93cae6),u64(0xa44cfe79ae538bbe),u64(0x9d1d84fcce371425),
u64(0x51d2b1ab2ddfb636),u64(0x2fd7e4b9e72cd38c),u64(0x65ca5b96b7552210),u64(0xdd69a0d8ab3b546d),
u64(0x604d51b25fbf70e2),u64(0x73aa8a564fb7ac9e),u64(0x1a8c1e992b941148),u64(0xaac40a2703d9bea0),
u64(0x764dbeae7fa4f3a6),u64(0x1e99b96e70a9be8b),u64(0x2c5e9deb57ef4743),u64(0x3a938fee32d29981),
u64(0x26e6db8ffdf5adfe),u64(0x469356c504ec9f9d),u64(0xc8763c5b08d1908c),u64(0x3f6c6af859d80055),
u64(0x7f7cc39420a3a545),u64(0x9bfb227ebdf4c5ce),u64(0x89039d79d6fc5c5c),u64(0x8fe88b57305e2ab6),
u64(0xa09e8c8c35ab96de),u64(0xfa7e393983325753),u64(0xd6b6d0ecc617c699),u64(0xdfea21ea9e7557e3),
u64(0xb67c1fa481680af8),u64(0xca1e3785a9e724e5),u64(0x1cfc8bed0d681639),u64(0xd18d8549d140caea),
u64(0x4ed0fe7e9dc91335),u64(0xe4dbf0634473f5d2),u64(0x1761f93a44d5aefe),u64(0x53898e4c3910da55),
u64(0x734de8181f6ec39a),u64(0x2680b122baa28d97),u64(0x298af231c85bafab),u64(0x7983eed3740847d5),
u64(0x66c1a2a1a60cd889),u64(0x9e17e49642a3e4c1),u64(0xedb454e7badc0805),u64(0x50b704cab602c329),
u64(0x4cc317fb9cddd023),u64(0x66b4835d9eafea22),u64(0x219b97e26ffc81bd),u64(0x261e4e4c0a333a9d),
u64(0x1fe2cca76517db90),u64(0xd7504dfa8816edbb),u64(0xb9571fa04dc089c8),u64(0x1ddc0325259b27de),
u64(0xcf3f4688801eb9aa),u64(0xf4f5d05c10cab243),u64(0x38b6525c21a42b0e),u64(0x36f60e2ba4fa6800),
u64(0xeb3593803173e0ce),u64(0x9c4cd6257c5a3603),u64(0xaf0c317d32adaa8a),u64(0x258e5a80c7204c4b),
u64(0x8b889d624d44885d),u64(0xf4d14597e660f855),u64(0xd4347f66ec8941c3),u64(0xe699ed85b0dfb40d),
u64(0x2472f6207c2d0484),u64(0xc2a1e7b5b459aeb5),u64(0xab4f6451cc1d45ec),u64(0x63767572ae3d6174),
u64(0xa59e0bd101731a28),u64(0x116d0016cb948f09),u64(0x2cf9c8ca052f6e9f),u64(0x0b090a7560a968e3),
u64(0xabeeddb2dde06ff1),u64(0x58efc10b06a2068d),u64(0xc6e57a78fbd986e0),u64(0x2eab8ca63ce802d7),
u64(0x14a195640116f336),u64(0x7c0828dd624ec390),u64(0xd74bbe77e6116ac7),u64(0x804456af10f5fb53),
u64(0xebe9ea2adf4321c7),u64(0x03219a39ee587a30),u64(0x49787fef17af9924),u64(0xa1e9300cd8520548),
u64(0x5b45e522e4b1b4ef),u64(0xb49c3b3995091a36),u64(0xd4490ad526f14431),u64(0x12a8f216af9418c2),
u64(0x001f837cc7350524),u64(0x1877b51e57a764d5),u64(0xa2853b80f17f58ee),u64(0x993e1de72d36d310),
u64(0xb3598080ce64a656),u64(0x252f59cf0d9f04bb),u64(0xd23c8e176d113600),u64(0x1bda0492e7e4586e),
u64(0x21e0bd5026c619bf),u64(0x3b097adaf088f94e),u64(0x8d14dedb30be846e),u64(0xf95cffa23af5f6f4),
u64(0x3871700761b3f743),u64(0xca672b91e9e4fa16),u64(0x64c8e531bff53b55),u64(0x241260ed4ad1e87d),
u64(0x106c09b972d2e822),u64(0x7fba195410e5ca30),u64(0x7884d9bc6cb569d8),u64(0x0647dfedcd894a29),
u64(0x63573ff03e224774),u64(0x4fc8e9560f91b123),u64(0x1db956e450275779),u64(0xb8d91274b9e9d4fb),
u64(0xa2ebee47e2fbfce1),u64(0xd9f1f30ccd97fb09),u64(0xefed53d75fd64e6b),u64(0x2e6d02c36017f67f),
u64(0xa9aa4d20db084e9b),u64(0xb64be8d8b25396c1),u64(0x70cb6af7c2d5bcf0),u64(0x98f076a4f7a2322e),
u64(0xbf84470805e69b5f),u64(0x94c3251f06f90cf3),u64(0x3e003e616a6591e9),u64(0xb925a6cd0421aff3),
u64(0x61bdd1307c66e300),u64(0xbf8d5108e27e0d48),u64(0x240ab57a8b888b20),u64(0xfc87614baf287e07),
u64(0xef02cdd06ffdb432),u64(0xa1082c0466df6c0a),u64(0x8215e577001332c8),u64(0xd39bb9c3a48db6cf),
u64(0x2738259634305c14),u64(0x61cf4f94c97df93d),u64(0x1b6baca2ae4e125b),u64(0x758f450c88572e0b),
u64(0x959f587d507a8359),u64(0xb063e962e045f54d),u64(0x60e8ed72c0dff5d1),u64(0x7b64978555326f9f),
u64(0xfd080d236da814ba),u64(0x8c90fd9b083f4558),u64(0x106f72fe81e2c590),u64(0x7976033a39f7d952),
u64(0xa4ec0132764ca04b),u64(0x733ea705fae4fa77),u64(0xb4d8f77bc3e56167),u64(0x9e21f4f903b33fd9),
u64(0x9d765e419fb69f6d),u64(0xd30c088ba61ea5ef),u64(0x5d94337fbfaf7f5b),u64(0x1a4e4822eb4d7a59),
u64(0x6ffe73e81b637fb3),u64(0xddf957bc36d8b9ca),u64(0x64d0e29eea8838b3),u64(0x08dd9bdfd96b9f63),
u64(0x087e79e5a57d1d13),u64(0xe328e230e3e2b3fb),u64(0x1c2559e30f0946be),u64(0x720bf5f26f4d2eaa),
u64(0xb0774d261cc609db),u64(0x443f64ec5a371195),u64(0x4112cf68649a260e),u64(0xd813f2fab7f5c5ca),
u64(0x660d3257380841ee),u64(0x59ac2c7873f910a3),u64(0xe846963877671a17),u64(0x93b633abfa3469f8),
u64(0xc0c0f5a60ef4cdcf),u64(0xcaf21ecd4377b28c),u64(0x57277707199b8175),u64(0x506c11b9d90e8b1d),
u64(0xd83cc2687a19255f),u64(0x4a29c6465a314cd1),u64(0xed2df21216235097),u64(0xb5635c95ff7296e2),
u64(0x22af003ab672e811),u64(0x52e762596bf68235),u64(0x9aeba33ac6ecc6b0),u64(0x944f6de09134dfb6),
u64(0x6c47bec883a7de39),u64(0x6ad047c430a12104),u64(0xa5b1cfdba0ab4067),u64(0x7c45d833aff07862),
u64(0x5092ef950a16da0b),u64(0x9338e69c052b8e7b),u64(0x455a4b4cfe30e3f5),u64(0x6b02e63195ad0cf8),
u64(0x6b17b224bad6bf27),u64(0xd1e0ccd25bb9c169),u64(0xde0c89a556b9ae70),u64(0x50065e535a213cf6),
u64(0x9c1169fa2777b874),u64(0x78edefd694af1eed),u64(0x6dc93d9526a50e68),u64(0xee97f453f06791ed),
u64(0x32ab0edb696703d3),u64(0x3a6853c7e70757a7),u64(0x31865ced6120f37d),u64(0x67fef95d92607890),
u64(0x1f2b1d1f15f6dc9c),u64(0xb69e38a8965c6b65),u64(0xaa9119ff184cccf4),u64(0xf43c732873f24c13),
u64(0xfb4a3d794a9a80d2),u64(0x3550c2321fd6109c),u64(0x371f77e76bb8417e),u64(0x6bfa9aae5ec05779),
u64(0xcd04f3ff001a4778),u64(0xe3273522064480ca),u64(0x9f91508bffcfc14a),u64(0x049a7f41061a9e60),
u64(0xfcb6be43a9f2fe9b),u64(0x08de8a1c7797da9b),u64(0x8f9887e6078735a1),u64(0xb5b4071dbfc73a66),
u64(0x230e343dfba08d33),u64(0x43ed7f5a0fae657d),u64(0x3a88a0fbbcb05c63),u64(0x21874b8b4d2dbc4f),
u64(0x1bdea12e35f6a8c9),u64(0x53c065c6c8e63528),u64(0xe34a1d250e7a8d6b),u64(0xd6b04d3b7651dd7e),
u64(0x5e90277e7cb39e2d),u64(0x2c046f22062dc67d),u64(0xb10bb459132d0a26),u64(0x3fa9ddfb67e2f199),
u64(0x0e09b88e1914f7af),u64(0x10e8b35af3eeab37),u64(0x9eedeca8e272b933),u64(0xd4c718bc4ae8ae5f),
u64(0x81536d601170fc20),u64(0x91b534f885818a06),u64(0xec8177f83f900978),u64(0x190e714fada5156e),
u64(0xb592bf39b0364963),u64(0x89c350c893ae7dc1),u64(0xac042e70f8b383f2),u64(0xb49b52e587a1ee60),
u64(0xfb152fe3ff26da89),u64(0x3e666e6f69ae2c15),u64(0x3b544ebe544c19f9),u64(0xe805a1e290cf2456),
u64(0x24b33c9d7ed25117),u64(0xe74733427b72f0c1),u64(0x0a804d18b7097475),u64(0x57e3306d881edb4f),
u64(0x4ae7d6a36eb5dbcb),u64(0x2d8d5432157064c8),u64(0xd1e649de1e7f268b),u64(0x8a328a1cedfe552c),
u64(0x07a3aec79624c7da),u64(0x84547ddc3e203c94),u64(0x990a98fd5071d263),u64(0x1a4ff12616eefc89),
u64(0xf6f7fd1431714200),u64(0x30c05b1ba332f41c),u64(0x8d2636b81555a786),u64(0x46c9feb55d120902),
u64(0xccec0a73b49c9921),u64(0x4e9d2827355fc492),u64(0x19ebb029435dcb0f),u64(0x4659d2b743848a2c),
u64(0x963ef2c96b33be31),u64(0x74f85198b05a2e7d),u64(0x5a0f544dd2b1fb18),u64(0x03727073c2e134b1),
u64(0xc7f6aa2de59aea61),u64(0x352787baa0d7c22f),u64(0x9853eab63b5e0b35),u64(0xabbdcdd7ed5c0860),
u64(0xcf05daf5ac8d77b0),u64(0x49cad48cebf4a71e),u64(0x7a4c10ec2158c4a6),u64(0xd9e92aa246bf719e),
u64(0x13ae978d09fe5557),u64(0x730499af921549ff),u64(0x4e4b705b92903ba4),u64(0xff577222c14f0a3a),
u64(0x55b6344cf97aafae),u64(0xb862225b055b6960),u64(0xcac09afbddd2cdb4),u64(0xdaf8e9829fe96b5f),
u64(0xb5fdfc5d3132c498),u64(0x310cb380db6f7503),u64(0xe87fbb46217a360e),u64(0x2102ae466ebb1148),
u64(0xf8549e1a3aa5e00d),u64(0x07a69afdcc42261a),u64(0xc4c118bfe78feaae),u64(0xf9f4892ed96bd438),
u64(0x1af3dbe25d8f45da),u64(0xf5b4b0b0d2deeeb4),u64(0x962aceefa82e1c84),u64(0x046e3ecaaf453ce9),
u64(0xf05d129681949a4c),u64(0x964781ce734b3c84),u64(0x9c2ed44081ce5fbd),u64(0x522e23f3925e319e),
u64(0x177e00f9fc32f791),u64(0x2bc60a63a6f3b3f2),u64(0x222bbfae61725606),u64(0x486289ddcc3d6780),
u64(0x7dc7785b8efdfc80),u64(0x8af38731c02ba980),u64(0x1fab64ea29a2ddf7),u64(0xe4d9429322cd065a),
u64(0x9da058c67844f20c),u64(0x24c0e332b70019b0),u64(0x233003b5a6cfe6ad),u64(0xd586bd01c5c217f6),
u64(0x5e5637885f29bc2b),u64(0x7eba726d8c94094b),u64(0x0a56a5f0bfe39272),u64(0xd79476a84ee20d06),
u64(0x9e4c1269baa4bf37),u64(0x17efee45b0dee640),u64(0x1d95b0a5fcf90bc6),u64(0x93cbe0b699c2585d),
u64(0x65fa4f227a2b6d79),u64(0xd5f9e858292504d5),u64(0xc2b5a03f71471a6f),u64(0x59300222b4561e00),
u64(0xce2f8642ca0712dc),u64(0x7ca9723fbb2e8988),u64(0x2785338347f2ba08),u64(0xc61bb3a141e50e8c),
u64(0x150f361dab9dec26),u64(0x9f6a419d382595f4),u64(0x64a53dc924fe7ac9),u64(0x142de49fff7a7c3d),
u64(0x0c335248857fa9e7),u64(0x0a9c32d5eae45305),u64(0xe6c42178c4bbb92e),u64(0x71f1ce2490d20b07),
u64(0xf1bcc3d275afe51a),u64(0xe728e8c83c334074),u64(0x96fbf83a12884624),u64(0x81a1549fd6573da5),
u64(0x5fa7867caf35e149),u64(0x56986e2ef3ed091b),u64(0x917f1dd5f8886c61),u64(0xd20d8c88c8ffe65f),
u64(0x31d71dce64b2c310),u64(0xf165b587df898190),u64(0xa57e6339dd2cf3a0),u64(0x1ef6e6dbb1961ec9),
u64(0x70cc73d90bc26e24),u64(0xe21a6b35df0c3ad7),u64(0x003a93d8b2806962),u64(0x1c99ded33cb890a1),
u64(0xcf3145de0add4289),u64(0xd0e4427a5514fb72),u64(0x77c621cc9fb3a483),u64(0x67a34dac4356550b),
u64(0xf8d626aaaf278509)};
genel kitap:adres=0; genel kitap_adet:i64=0; genel kitap_derinlik:i64=20; genel kitap_açık:i64=0; genel kitap_tohum:u64=u64(88172645463325252);
işlev kitap_anahtarı(k:Konum):u64 {
    h:u64:=u64(0);
    yinele(s:=0;s<64;s+=1) {
        t:=i64(k.tahta[s]); eğer t==0 { sürdür; }
        tür_:=tür(t); renk_:=renk(t);
        h=h^kitap_rastgele[64*(2*(tür_-1)+(1-renk_))+s];
    }
    yinele(i:=0;i<4;i+=1) { eğer (k.rok&(1<<i))!=0 { h=h^kitap_rastgele[768+i]; } }
    eğer k.geçer>=0 {
        r:=k.sıra; kaynak_sırası:=seç(r==0,k.geçer-8,k.geçer+8); dosya:=k.geçer%8; var:=0;
        eğer dosya>0 && k.tahta[kaynak_sırası-1]==u8(r*6+1) { var=1; }
        eğer dosya<7 && k.tahta[kaynak_sırası+1]==u8(r*6+1) { var=1; }
        eğer var { h=h^kitap_rastgele[772+dosya]; }
    }
    eğer k.sıra==0 { h=h^kitap_rastgele[780]; }
    dön h;
}
işlev kitap_u64(p:adres):u64 { dön tb_u64be(p); }
işlev onaltılık(v:u64) { b:=dizi(20); yinele(i:=0;i<16;i+=1) { d:=i64((v>>u64(60-4*i))&u64(15)); bayt_yaz(b,i,seç(d<10,48+d,87+d)); } bayt_yaz(b,16,0); yaz(b); }
işlev kitap_yükle(yol:adres):i64 {
    eğer kitap!=0 { bellek_bırak(kitap); kitap=0; kitap_adet=0; }
    boy:=yerel_dizi(i64,1); utf:=dizi(131080); f:=dosya_aç_utf8(yol,"rb",utf,131080); eğer f==0 { dön 0; }
    dosya_konumla(f,0,2); n:=dosya_konumu(f); dosya_konumla(f,0,0);
    eğer n<16 || n%16!=0 { dosya_kapat(f); dön 0; }
    p:=bellek_ayır(n); eğer p==0 { dosya_kapat(f); dön 0; }
    eğer dosya_oku(p,n,f)!=n { bellek_bırak(p); dosya_kapat(f); dön 0; }
    dosya_kapat(f); kitap=p; kitap_adet=n/16; dön kitap_adet;
}

işlev kitap_hamlesi(k:Konum):i64 {
    eğer kitap==0 || kitap_adet==0 { dön 0; }
    anahtar:=kitap_anahtarı(k); alt:=0; üst:=kitap_adet;
    iken alt<üst { orta:=(alt+üst)/2; eğer kitap_u64(adres_ekle(kitap,orta*16))<anahtar { alt=orta+1; } yoksa { üst=orta; } }
    l:=yerel(Hamleler); yasal_hamleler(k,l);
    toplam:=0; seçilen:=0; i:=alt;
    kitap_tohum=kitap_tohum^u64(zaman_ns());
    iken i<kitap_adet && kitap_u64(adres_ekle(kitap,i*16))==anahtar {
        e:=adres_ekle(kitap,i*16); m:=tb_u16(adres_ekle(e,8)); m=((m&0xff)<<8)|(m>>8); ağırlık:=tb_u16(adres_ekle(e,10)); ağırlık=((ağırlık&0xff)<<8)|(ağırlık>>8);
        i+=1;
        hedef_:=(m&7)+8*((m>>3)&7); kaynak_:=((m>>6)&7)+8*((m>>9)&7); terfi:=(m>>12)&7;
        h:=0;
        yinele(j:=0;j<l.adet;j+=1) {
            c:=i64(l.hamle[j]); eğer kaynak(c)!=kaynak_ { sürdür; }
            ht:=hamle_türü(c);
            eğer ht==ROK { eğer hedef(c)==hedef_ { h=c; kır; } sürdür; }
            eğer hedef(c)!=hedef_ { sürdür; }
            eğer terfi!=0 { eğer ht>=4 && ht-3==terfi { h=c; kır; } sürdür; }
            eğer ht<4 { h=c; kır; }
        }
        eğer h==0 || ağırlık==0 { sürdür; }
        toplam+=ağırlık;

        kitap_tohum=kitap_tohum^(kitap_tohum<<u64(13)); kitap_tohum=kitap_tohum^(kitap_tohum>>u64(7)); kitap_tohum=kitap_tohum^(kitap_tohum<<u64(17));
        eğer i64(kitap_tohum%u64(toplam))<ağırlık { seçilen=h; }
    }
    dön seçilen;
}

işlev ana():i64 {
    çıktı=standart_çıktı_aç(); eğer çıktı==0 { dön 1; }
    ertele { dosya_kapat(çıktı); }
    anahtarları_kur(); başlangıç(oyun);
    eğer argüman_sayısı()>=2 { ab:=dizi(16); eğer argüman_oku(1,ab,16)>=0 && metin_eşit(ab,"ayar") { ayar_ilanı=1; } }
    eğer GÖMÜLÜ_AĞ!=0 { gömülüyü_yükle(); }
    girdi:=bellek_ayır(65536); sözcük:=bellek_ayır(32768); geçici:=yeni(Konum);
    eğer girdi==0 || sözcük==0 || adres(geçici)==0 { dön 1; }
    ertele { bellek_bırak(girdi); bellek_bırak(sözcük); sil(geçici); }
    iken 1 {
        okunan:=uci_satır_oku(girdi,65536); eğer okunan==0 { kır; } eğer okunan<0 { hata("satir cok uzun"); sürdür; }
        n:=sözcüklere_böl(girdi,sözcük,4096); eğer n<=0 { sürdür; } komut:=adres_oku(sözcük,0);
        eğer metin_eşit(komut,"quit") { kır; }
        yoksa eğer metin_eşit(komut,"uci") {
            kilit_al(&çıktı_kilidi);
            metin_satırı("id name Tony 0.5"); metin_satırı("id author Cetin Turan");
            metin_satırı("option name UCI_Chess960 type check default false");
            metin_satırı("option name Threads type spin default 1 min 1 max 512");
            metin_satırı("option name Hash type spin default 16 min 1 max 16384");
            metin_satırı("option name Clear Hash type button");
            metin_satırı("option name MultiPV type spin default 1 min 1 max 256");
            metin_satırı("option name Ponder type check default false");
            metin_satırı("option name UCI_ShowWDL type check default false");
            metin_satırı("option name HamPuan type check default false");
            metin_satırı("option name Move Overhead type spin default 100 min 0 max 5000");
            metin_satırı(seç(GÖMÜLÜ_AĞ,"option name EvalFile type string default <embedded>","option name EvalFile type string default <empty>"));
            metin_satırı("option name AllowTestNet type check default false");
            metin_satırı("option name Budama type check default true");
            metin_satırı("option name DinamikMarj type check default false");
            metin_satırı("option name IliskiDA type check default true");
            metin_satırı("option name SeyrekBas type check default false");
            metin_satırı("option name DmOrta type spin default 0 min -1000000 max 1000000");
            metin_satırı("option name DmEgim type spin default 0 min -100000 max 100000");
            metin_satırı("option name DmCp type spin default 0 min 0 max 100000");
            metin_satırı("option name DmLmr type spin default 0 min 0 max 256");
            metin_satırı("option name DmAlt type spin default 40 min 1 max 64");
            metin_satırı("option name DmUst type spin default 112 min 64 max 512");
            metin_satırı("option name SyzygyPath type string default <empty>");
            metin_satırı("option name SyzygyProbeDepth type spin default 1 min 1 max 100");
            metin_satırı("option name Book type string default <empty>");
            metin_satırı("option name OwnBook type check default false");
            metin_satırı("option name BookDepth type spin default 20 min 1 max 200");
            eğer ayar_ilanı { metin_satırı("option name SharedNet type string default <empty>"); }
            yinele(i:=0;i<96 && ayar_ilanı;i+=1) { yaz("option name P"); rakam(i); yaz(" type spin default "); rakam(ay[i]); yaz(" min -1000000 max 1000000"); harf_yaz(10); }
            metin_satırı("uciok"); dosya_boşalt(çıktı); kilit_bırak(&çıktı_kilidi);
        } yoksa eğer metin_eşit(komut,"isready") { kilit_al(&çıktı_kilidi); metin_satırı("readyok"); dosya_boşalt(çıktı); kilit_bırak(&çıktı_kilidi); }
        yoksa eğer metin_eşit(komut,"ucinewgame") { aramayı_durdur(); önbelleği_temizle(); geçmişleri_temizle(); başlangıç(oyun); }
        yoksa eğer metin_eşit(komut,"stop") { aramayı_durdur(); }
        yoksa eğer metin_eşit(komut,"wait") { eğer arama_açık { iş_bekle(adres(arama_kaydı)); arama_açık=0; } }
        yoksa eğer metin_eşit(komut,"ponderhit") {
            eğer arama_açık && rakip_sırası {
                atomik_yaz(&başlangıç_zamanı,zaman_ns());
                eğer düşünme_süresi>=0 { atomik_yaz(&son_zaman,başlangıç_zamanı+ençok(1,düşünme_süresi)*1000000); }
                atomik_yaz(&rakip_sırası,0);
                atomik_yaz(&sonuç_beklesin,0);
            }
        }
        yoksa eğer metin_eşit(komut,"go") { aramayı_başlat(sözcük,n); }
        yoksa eğer metin_eşit(komut,"agyaz") && n==2 && ağ!=0 && ağ_türü==2 {
            f:=dosya_aç(adres_oku(sözcük,1),"wb"); eğer f!=0 { dosya_yaz(ağ,s8_BAYT,f); dosya_kapat(f); }
        }
        yoksa eğer metin_eşit(komut,"setoption") {
            aramayı_durdur();
            eğer n==4 && metin_eşit(adres_oku(sözcük,1),"name") && metin_eşit(adres_oku(sözcük,2),"Clear") && metin_eşit(adres_oku(sözcük,3),"Hash") { önbelleği_temizle(); sürdür; }
            eğer n==6 && metin_eşit(adres_oku(sözcük,1),"name") && metin_eşit(adres_oku(sözcük,2),"Move") && metin_eşit(adres_oku(sözcük,3),"Overhead") && metin_eşit(adres_oku(sözcük,4),"value") {
                v:=adres_oku(sözcük,5); sayı:=tamsayı(v);
                eğer sayı>=0 && sayı<=5000 && bayt_oku(v,0)!=45 { hamle_gecikmesi=sayı; } yoksa { hata("gecersiz Move Overhead"); }
                sürdür;
            }
            eğer n<5 || !metin_eşit(adres_oku(sözcük,1),"name") || !metin_eşit(adres_oku(sözcük,3),"value") { hata("setoption name ... value ... bekleniyor"); sürdür; }
            ad:=adres_oku(sözcük,2); v:=adres_oku(sözcük,4); sayı:=tamsayı(v);
            eğer metin_eşit(ad,"OwnBook") && n==5 { kitap_açık=metin_eşit(v,"true"); }
            yoksa eğer metin_eşit(ad,"BookDepth") && n==5 && sayı>=1 && sayı<=200 { kitap_derinlik=sayı; }
            yoksa eğer metin_eşit(ad,"Book") {
                yol:=dizi(65536); uzunluk:=0;
                yinele(i:=4;i<n;i+=1) {
                    parça:=adres_oku(sözcük,i); u:=metin_uzunluğu(parça);
                    eğer i>4 { bayt_yaz(yol,uzunluk,32); uzunluk+=1; }
                    bellek_kopyala(adres_ekle(yol,uzunluk),parça,u); uzunluk+=u;
                }
                bayt_yaz(yol,uzunluk,0);
                eğer metin_eşit(yol,"<empty>") || uzunluk==0 { eğer kitap!=0 { bellek_bırak(kitap); kitap=0; kitap_adet=0; } kitap_açık=0; }
                yoksa {
                    adet:=kitap_yükle(yol); kitap_açık=adet>0;
                    kilit_al(&çıktı_kilidi); yaz("info string kitap: "); rakam(adet); yaz(" kayit"); satır_sonu(); dosya_boşalt(çıktı); kilit_bırak(&çıktı_kilidi);
                }
            }
            yoksa eğer metin_eşit(ad,"UCI_Chess960") || metin_eşit(ad,"AllowTestNet") || metin_eşit(ad,"Ponder") || metin_eşit(ad,"Budama") || metin_eşit(ad,"DinamikMarj") || metin_eşit(ad,"IliskiDA") || metin_eşit(ad,"SeyrekBas") || metin_eşit(ad,"UCI_ShowWDL") || metin_eşit(ad,"HamPuan") {
                eğer n!=5 || (!metin_eşit(v,"true") && !metin_eşit(v,"false")) { hata("check degeri true/false olmali"); sürdür; }
                eğer metin_eşit(ad,"UCI_Chess960") { eğer satranç960!=metin_eşit(v,"true") { önbelleği_temizle(); } satranç960=metin_eşit(v,"true"); }
                yoksa eğer metin_eşit(ad,"AllowTestNet") { deneme_izni=metin_eşit(v,"true"); }
                yoksa eğer metin_eşit(ad,"Budama") { eğer budama!=metin_eşit(v,"true") { önbelleği_temizle(); } budama=metin_eşit(v,"true"); }
                yoksa eğer metin_eşit(ad,"DinamikMarj") { dinamik_marj=metin_eşit(v,"true"); }
                yoksa eğer metin_eşit(ad,"SeyrekBas") { s8_seyrek=metin_eşit(v,"true"); }
                yoksa eğer metin_eşit(ad,"UCI_ShowWDL") { wdl_göster=metin_eşit(v,"true"); }
                yoksa eğer metin_eşit(ad,"HamPuan") { ham_puan=metin_eşit(v,"true"); }
                yoksa eğer metin_eşit(ad,"IliskiDA") { tr_da=metin_eşit(v,"true"); eğer ağ!=0 && ağ_türü==2 { s8_tazele(oyun); } }
            } yoksa eğer metin_eşit(ad,"Threads") && n==5 && sayı>=1 && sayı<=AZAMİ_İŞÇİ { aramayı_durdur(); işçi_sayısı=sayı; }
            yoksa eğer n==5 && bayt_oku(ad,0)==80 && bayt_oku(ad,1)>=48 && bayt_oku(ad,1)<=57 && tamsayı(adres_ekle(ad,1))>=0 && tamsayı(adres_ekle(ad,1))<96 {
                ay[tamsayı(adres_ekle(ad,1))]=seç(bayt_oku(v,0)==45,-tamsayı(adres_ekle(v,1)),sayı);
            }
            yoksa eğer metin_eşit(ad,"SharedNet") && n==5 {
                eğer ağ!=0 && ağ_türü==2 && ağ_eşli==0 {
                    f:=dosya_aç(v,"rb");
                    eğer f!=0 {
                        dosya_konumla(f,0,2); boy:=dosya_konumu(f);
                        eğer boy==s8_BAYT {
                            m:=dosya_eşle(f,s8_BAYT);
                            eğer m!=0 && bellek_karşılaştır(m,ağ,s8_BAYT)==0 { hizalı_bırak(ağ); ağ=m; ağ_eşli=s8_BAYT; }
                            yoksa eğer m!=0 { dosya_eşlemeyi_bırak(m,s8_BAYT); }
                        }
                        dosya_kapat(f);
                    }
                }
                kilit_al(&çıktı_kilidi); yaz(seç(ağ_eşli>0,"info string SharedNet eslendi","info string SharedNet kullanilmadi")); satır_sonu(); dosya_boşalt(çıktı); kilit_bırak(&çıktı_kilidi);
            }
            yoksa eğer metin_eşit(ad,"DmOrta") && n==5 { dm_orta=seç(bayt_oku(v,0)==45,-tamsayı(adres_ekle(v,1)),sayı); }
            yoksa eğer metin_eşit(ad,"DmCp") && n==5 && sayı>=0 { dm_cp=sayı; }
            yoksa eğer metin_eşit(ad,"DmLmr") && n==5 && sayı>=0 && sayı<=256 { dm_lmr=sayı; }
            yoksa eğer metin_eşit(ad,"DmEgim") && n==5 { dm_eğim=seç(bayt_oku(v,0)==45,-tamsayı(adres_ekle(v,1)),sayı); }
            yoksa eğer metin_eşit(ad,"DmAlt") && n==5 && sayı>=1 && sayı<=64 { dm_alt=sayı; }
            yoksa eğer metin_eşit(ad,"DmUst") && n==5 && sayı>=64 && sayı<=512 { dm_üst=sayı; }
            yoksa eğer metin_eşit(ad,"Hash") && n==5 && sayı>=1 && sayı<=16384 { eğer bellek_mb!=sayı { önbelleği_bırak(); } bellek_mb=sayı; }
            yoksa eğer metin_eşit(ad,"MultiPV") && n==5 && sayı>=1 && sayı<=256 { çoklu_varyant=sayı; }
            yoksa eğer metin_eşit(ad,"SyzygyProbeDepth") && n==5 && sayı>=1 && sayı<=100 { tb_sonda_derinliği=sayı; }
            yoksa eğer metin_eşit(ad,"SyzygyPath") {
                yol:=dizi(65536); uzunluk:=0;
                yinele(i:=4;i<n;i+=1) {
                    parça:=adres_oku(sözcük,i); u:=metin_uzunluğu(parça);
                    eğer i>4 { bayt_yaz(yol,uzunluk,32); uzunluk+=1; }
                    bellek_kopyala(adres_ekle(yol,uzunluk),parça,u); uzunluk+=u;
                }
                bayt_yaz(yol,uzunluk,0); tb_boşalt();
                eğer !metin_eşit(yol,"<empty>") && uzunluk>0 {
                    adet:=tb_yükle(yol);
                    kilit_al(&çıktı_kilidi); yaz("info string tablebase: "); rakam(adet); yaz(" tablo, en cok "); rakam(tb_en_büyük); yaz(" tas"); satır_sonu(); dosya_boşalt(çıktı); kilit_bırak(&çıktı_kilidi);
                }
            }
            yoksa eğer metin_eşit(ad,"EvalFile") {
                yol:=dizi(65536); uzunluk:=0;
                yinele(i:=4;i<n;i+=1) {
                    parça:=adres_oku(sözcük,i); u:=metin_uzunluğu(parça);
                    eğer i>4 { bayt_yaz(yol,uzunluk,32); uzunluk+=1; }
                    bellek_kopyala(adres_ekle(yol,uzunluk),parça,u); uzunluk+=u;
                }
                bayt_yaz(yol,uzunluk,0); eğer ağ_yükle(yol) { önbelleği_temizle(); }
            } yoksa { hata("bilinmeyen secenek veya gecersiz deger"); }
        } yoksa eğer metin_eşit(komut,"position") {
            aramayı_durdur();
            i:=0; tamam:=1;
            eğer n>=2 && metin_eşit(adres_oku(sözcük,1),"startpos") { başlangıç(geçici); i=2; }
            yoksa eğer n>=3 && metin_eşit(adres_oku(sözcük,1),"fen") {

                alanlar:=dizi(48);
                adres_yaz(alanlar,0,adres_oku(sözcük,2)); adres_yaz(alanlar,1,"w"); adres_yaz(alanlar,2,"-");
                adres_yaz(alanlar,3,"-"); adres_yaz(alanlar,4,"0"); adres_yaz(alanlar,5,"1");
                i=3; alan:=1;
                iken i<n && alan<6 && !metin_eşit(adres_oku(sözcük,i),"moves") {
                    adres_yaz(alanlar,alan,adres_oku(sözcük,i)); alan+=1; i+=1;
                }
                tamam=fen_oku(geçici,alanlar);
            }
            yoksa { tamam=0; }
            eğer tamam && i<n { eğer !metin_eşit(adres_oku(sözcük,i),"moves") { tamam=0; } i+=1; }
            g:=yerel(İz);
            iken tamam && i<n {
                h:=hamle_oku(geçici,adres_oku(sözcük,i));
                eğer h==0 || geçici.iz_sayısı>=AZAMİ_İZ-AZAMİ_KAT { tamam=0; kır; }
                ilerle(geçici,h,g); i+=1;
            }
            eğer tamam { bellek_kopyala(adres(oyun),adres(geçici),boyut(Konum)); } yoksa { hata("gecersiz position; onceki konum korundu"); }
        } yoksa eğer metin_eşit(komut,"evalbench") && n==2 {

            aramayı_durdur(); adet:=tamsayı(adres_oku(sözcük,1));
            eğer ağ==0 || adet<=0 { hata("ag yuklenmedi ya da adet gecersiz"); }
            yoksa { top:=0; t0:=zaman_ns(); yinele(i:=0;i<adet;i+=1) { top+=ağ_değeri(oyun,adres(oyun.öz)); } dt:=zaman_ns()-t0;
                    yaz("evalbench ns/eval "); rakam(dt/adet); yaz(" toplam "); rakam(top); satır_sonu(); }
        } yoksa eğer metin_eşit(komut,"perft") && n==2 {
            aramayı_durdur();
            d:=tamsayı(adres_oku(sözcük,1));
            eğer d>=0 && d<=8 { yaz("nodes "); rakam(perft(oyun,d)); satır_sonu(); } yoksa { hata("perft derinligi 0..8"); }
        } yoksa eğer metin_eşit(komut,"legal") {
            aramayı_durdur();
            l:=yerel(Hamleler); yasal_hamleler(oyun,l); b:=dizi(8); yaz("legal");
            yinele(i:=0;i<l.adet;i+=1) { harf_yaz(32); hamle_metni(i64(l.hamle[i]),oyun,b); yaz(b); } satır_sonu();
        } yoksa eğer metin_eşit(komut,"key") { aramayı_durdur(); yaz("key "); rakam(i64(oyun.anahtar)); satır_sonu(); }
        yoksa eğer metin_eşit(komut,"tbprobe") { tb_sonda_yaz(oyun); }
        yoksa eğer metin_eşit(komut,"polykey") { kilit_al(&çıktı_kilidi); yaz("info string polykey "); onaltılık(kitap_anahtarı(oyun)); satır_sonu(); dosya_boşalt(çıktı); kilit_bırak(&çıktı_kilidi); }
        yoksa eğer metin_eşit(komut,"eval") {
            aramayı_durdur(); eğer ağ==0 { hata("ag yuklenmedi"); }
            yoksa { yaz("eval "); rakam(ağ_değeri(oyun,adres(oyun.öz))); yaz(seç(deneme_ağı," testnet"," trained")); satır_sonu(); }
        } yoksa eğer metin_eşit(komut,"denetle") {
            aramayı_durdur(); tamam:=konumu_denetle(oyun); l:=yerel(Hamleler); yasal_hamleler(oyun,l); g:=yerel(İz);
            yinele(i:=0;i<l.adet;i+=1) { ilerle(oyun,i64(l.hamle[i]),g); tamam=tamam&&konumu_denetle(oyun); geri(oyun,g); tamam=tamam&&konumu_denetle(oyun); }
            metin_satırı(seç(tamam,"denetle ok","denetle HATA"));
        }
        yoksa { hata("bilinmeyen komut"); }
        dosya_boşalt(çıktı);
    }
    aramayı_durdur(); önbelleği_bırak();
    ağı_bırak();
    dön 0;
}
