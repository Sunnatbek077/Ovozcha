# Murabbiy ovozi: yozib olish ro'yxati

> Bu fayl avtomatik yasalgan: `sh Tools/voice-recordings/generate.sh`.
> Qo'lda tahrirlamang — darslar o'zgarsa, skriptni qayta ishga tushiring.

Talaffuz murabbiyi jonli ovoz bilan gapiradi (TTS emas). Har bir gap alohida qisqa fayl:
ilova ularni ketma-ket ulab, to'liq gap yasaydi. Masalan:

    word_rasm + coach_pos_start + letter_r + coach_instead_of + letter_l + coach_i_heard
    = "rasm soʻzining boshida r oʻrniga l eshitdim."

Fayl yo'q bo'lsa ilova buzilmaydi: murabbiy gapi faqat matn bo'lib ko'rinadi. Faqat
**quloq o'yini** `word_*` va `wrong_*` yozuvlarisiz yopiq turadi.

Jami: **410 ta fayl**. Hammasini birdan yozish shart emas — bir harfdan boshlang
(masalan R): shu harfning ko'rsatmasi, tovushi, bo'g'inlari va so'zlari yetarli.

## Qayerga qo'yiladi

    Sources/Ovozcha/Resources/Audio/<fayl nomi>.m4a

Papka yo'q bo'lsa, yarating. Qo'yilgandan keyin ilovani qayta yig'ing
(`skip app launch`). Fayl nomi aynan jadvaldagidek bo'lishi shart (kichik harf, `_`).

## Yozish qoidalari

- Format: **m4a (AAC), mono**. mp3 va wav ham ishlaydi.
- Tinch xona, telefon og'izdan ~20 sm. Bir kishi, bir xil ohang.
- Boshi va oxiridagi jimlikni kesing (0.1 s dan oshmasin) — bo'laklar ulanganda
  gap tabiiy eshitilishi uchun.
- Bolaga gapirgandek: iliq, sekinroq, aniq.
- Bo'lak gaplarni (masalan `coach_pos_start`) gap o'rtasidagidek, pasaymaydigan ohangda ayting.

## Qo'shimcha foyda: nutq tanish etalonlari

`word_*` yozuvlari tekshiruv aniqligini ham oshiradi. Whisper to'g'ri aytilgan so'zni ham
xato yozishi mumkin ("robot" -> "Lobots"). Buni bola xatosi deb hisoblamaslik uchun ularni
`Tools/reference-transcripts/audio/` ga so'zning o'zi nomi bilan nusxalang
(`word_robot.m4a` -> `robot.m4a`) va `Tools/reference-transcripts/build.py` ni ishga tushiring.

## 1. Murabbiy iboralari (25 ta)

| Fayl | Nima deyiladi |
|---|---|
| `coach_praise_1` | Barakalla! |
| `coach_praise_2` | Zoʻr! |
| `coach_praise_3` | Juda toʻgʻri! |
| `coach_listen_repeat` | Tingla va takrorla. |
| `coach_say_word` | Tingla, keyin oʻzing ayt. |
| `coach_say_aloud` | Ovoz chiqarib ayt. |
| `coach_self_listen` | Yaxshi! Endi oʻz ovozingni tingla. |
| `coach_which_right` | Tingla: qaysi biri toʻgʻri? |
| `coach_first` | Birinchisi: |
| `coach_second` | Ikkinchisi: |
| `coach_listen_again` | Yana bir tinglab koʻr. |
| `coach_almost` | Deyarli! Yana bir marta, sekinroq ayt. |
| `coach_try_again` | Yana bir marta aytib koʻr. |
| `coach_not_heard` | Eshitmadim. Balandroq ayt. |
| `coach_move_on` | Yaxshi urinding! Xohlasang, keyingisiga oʻtamiz. |
| `coach_once_more` | Yana bir bor! |
| `coach_stage_done` | Barakalla! Bu bosqichni tugatding. |
| `coach_stage_partial` | Yaxshi! Yana mashq qilsak, hammasi chiqadi. |
| `coach_stage_retry` | Bosqich tugadi. Keling, yana bir bor urinib koʻramiz. |
| `coach_pos_start` | soʻzining boshida |
| `coach_pos_middle` | soʻzining oʻrtasida |
| `coach_pos_end` | soʻzining oxirida |
| `coach_instead_of` | oʻrniga |
| `coach_i_heard` | eshitdim. |
| `coach_sound_not_heard` | tovushini eshitmadim. |

## 2. Tovushni qanday aytish (29 ta)

Har bir dars boshida va xatodan keyin aytiladi.

| Fayl | Nima deyiladi |
|---|---|
| `coach_hint_a` | Ogʻzingni katta och: aaa. |
| `coach_hint_b` | Lablaringni yum, keyin ovoz bilan och: b-b-b. |
| `coach_hint_d` | Til uchini tishlaring orqasiga tegizib, ovoz bilan: d-d-d. |
| `coach_hint_e` | Ogʻzingni biroz och, lablaringni yon tomonga choʻz: eee. |
| `coach_hint_f` | Yuqori tishlaringni pastki labingga tegizib, pufla: fff. |
| `coach_hint_g` | Til orqasini tepaga koʻtar, ovoz bilan: g-g-g. |
| `coach_hint_h` | Ogʻzingni ochib, iliq havo chiqar: hhh. |
| `coach_hint_i` | Jilmayib, lablaringni choʻz: iii. |
| `coach_hint_j` | Lablaringni oldinga choʻzib, ovoz bilan: j-j-j. |
| `coach_hint_k` | Til orqasini tepaga koʻtar, ovozsiz: k-k-k. |
| `coach_hint_l` | Til uchini yuqori tishlaring orqasiga tegizib tur: lll. |
| `coach_hint_m` | Lablaringni yum va gʻuvilla: mmm. |
| `coach_hint_n` | Til uchini tishlaring orqasiga tegizib, burundan: nnn. |
| `coach_hint_o` | Lablaringni yumaloq qil: ooo. |
| `coach_hint_p` | Lablaringni yum, keyin puflab och: p-p-p. |
| `coach_hint_q` | Tovushni tomogʻingning ichkarisidan chiqar: q-q-q. |
| `coach_hint_r` | Tilingni tepaga koʻtar va titrat: rrr. |
| `coach_hint_s` | Tishlaringni yaqin qilib, ilondek vishilla: sss. |
| `coach_hint_t` | Til uchini tishlaring orqasiga tegizib, ovozsiz: t-t-t. |
| `coach_hint_u` | Lablaringni oldinga, trubadek choʻz: uuu. |
| `coach_hint_v` | Yuqori tishlaringni pastki labingga tegizib, ovoz bilan: vvv. |
| `coach_hint_x` | Tomogʻingdan havo chiqarib xirilla: xxx. |
| `coach_hint_y` | Til oʻrtasini tepaga koʻtar: ya, yo, yu. |
| `coach_hint_z` | Tishlaringni yaqin qilib, ariday gʻuvilla: zzz. |
| `coach_hint_o_apos` | Lablaringni yumaloq qilib, chuqurroq: oʻoʻoʻ. |
| `coach_hint_g_apos` | Tomogʻingdan, gʻargʻara qilganday: gʻgʻgʻ. |
| `coach_hint_sh` | Lablaringni oldinga choʻzib, “jim” deganday: shhh. |
| `coach_hint_ch` | Lablaringni oldinga choʻzib, poyezddek: ch-ch-ch. |
| `coach_hint_ng` | Ogʻzingni ochiq tut, ovozni burundan chiqar: ng. |

## 3. Harf tovushlari (29 ta)

Harfning **nomi emas, tovushi** ("er" emas, "r"). Harflar, Sonlar va Talaffuz bo'limlarida ishlatiladi.

| Fayl | Nima deyiladi |
|---|---|
| `letter_a` | a |
| `letter_b` | b |
| `letter_d` | d |
| `letter_e` | e |
| `letter_f` | f |
| `letter_g` | g |
| `letter_h` | h |
| `letter_i` | i |
| `letter_j` | j |
| `letter_k` | k |
| `letter_l` | l |
| `letter_m` | m |
| `letter_n` | n |
| `letter_o` | o |
| `letter_p` | p |
| `letter_q` | q |
| `letter_r` | r |
| `letter_s` | s |
| `letter_t` | t |
| `letter_u` | u |
| `letter_v` | v |
| `letter_x` | x |
| `letter_y` | y |
| `letter_z` | z |
| `letter_o_apos` | oʻ |
| `letter_g_apos` | gʻ |
| `letter_sh` | sh |
| `letter_ch` | ch |
| `letter_ng` | ng |

## 4. Tovush va bo'g'inlar (74 ta)

Cho'ziladigan tovushni 2 soniyacha cho'zing; bo'g'inlar orasida qisqa pauza.

| Fayl | Nima deyiladi |
|---|---|
| `sound_a` | aaa |
| `sound_b` | b-b-b |
| `syl_b_open` | ba, bo, bu |
| `syl_b_closed` | ab, ob, ub |
| `sound_d` | d-d-d |
| `syl_d_open` | da, do, du |
| `syl_d_closed` | ad, od, ud |
| `sound_e` | eee |
| `sound_f` | fff |
| `syl_f_open` | fa, fo, fu |
| `syl_f_closed` | af, of, uf |
| `sound_g` | g-g-g |
| `syl_g_open` | ga, go, gu |
| `syl_g_closed` | ag, og, ug |
| `sound_h` | hhh |
| `syl_h_open` | ha, ho, hu |
| `syl_h_closed` | ah, oh, uh |
| `sound_i` | iii |
| `sound_j` | j-j-j |
| `syl_j_open` | ja, jo, ju |
| `syl_j_closed` | aj, oj, uj |
| `sound_k` | k-k-k |
| `syl_k_open` | ka, ko, ku |
| `syl_k_closed` | ak, ok, uk |
| `sound_l` | lll |
| `syl_l_open` | la, lo, lu |
| `syl_l_closed` | al, ol, ul |
| `sound_m` | mmm |
| `syl_m_open` | ma, mo, mu |
| `syl_m_closed` | am, om, um |
| `sound_n` | nnn |
| `syl_n_open` | na, no, nu |
| `syl_n_closed` | an, on, un |
| `sound_o` | ooo |
| `sound_p` | p-p-p |
| `syl_p_open` | pa, po, pu |
| `syl_p_closed` | ap, op, up |
| `sound_q` | q-q-q |
| `syl_q_open` | qa, qo, qu |
| `syl_q_closed` | aq, oq, uq |
| `sound_rrr` | rrr |
| `syl_ra_ro_ru` | ra, ro, ru |
| `syl_ar_or_ur` | ar, or, ur |
| `sound_s` | sss |
| `syl_s_open` | sa, so, su |
| `syl_s_closed` | as, os, us |
| `sound_t` | t-t-t |
| `syl_t_open` | ta, to, tu |
| `syl_t_closed` | at, ot, ut |
| `sound_u` | uuu |
| `sound_v` | vvv |
| `syl_v_open` | va, vo, vu |
| `syl_v_closed` | av, ov, uv |
| `sound_x` | xxx |
| `syl_x_open` | xa, xo, xu |
| `syl_x_closed` | ax, ox, ux |
| `sound_y` | y-y-y |
| `syl_y_open` | ya, yo, yu |
| `syl_y_closed` | ay, oy, uy |
| `sound_z` | zzz |
| `syl_z_open` | za, zo, zu |
| `syl_z_closed` | az, oz, uz |
| `sound_o_apos` | oʻoʻoʻ |
| `sound_g_apos` | gʻgʻgʻ |
| `syl_g_apos_open` | gʻa, gʻo, gʻu |
| `syl_g_apos_closed` | agʻ, ogʻ, ugʻ |
| `sound_sh` | shhh |
| `syl_sh_open` | sha, sho, shu |
| `syl_sh_closed` | ash, osh, ush |
| `sound_ch` | ch-ch-ch |
| `syl_ch_open` | cha, cho, chu |
| `syl_ch_closed` | ach, och, uch |
| `sound_ng` | ng-ng-ng |
| `syl_ng_closed` | ang, ong, ung |

## 5. So'zlar — to'g'ri aytilishi (193 ta)

Bir so'z bir necha darsda uchrasa ham, fayl bitta.

| Fayl | Nima deyiladi |
|---|---|
| `word_akula` | akula |
| `word_ananas` | ananas |
| `word_archa` | archa |
| `word_ari` | ari |
| `word_arra` | arra |
| `word_asal` | asal |
| `word_avtobus` | avtobus |
| `word_ayiq` | ayiq |
| `word_ayol` | ayol |
| `word_baliq` | baliq |
| `word_banan` | banan |
| `word_barg` | barg |
| `word_bo_ri` | boʻri |
| `word_bodring` | bodring |
| `word_bog_` | bogʻ |
| `word_bola` | bola |
| `word_buqa` | buqa |
| `word_burun` | burun |
| `word_chana` | chana |
| `word_chaqmoq` | chaqmoq |
| `word_chelak` | chelak |
| `word_chipta` | chipta |
| `word_chiroq` | chiroq |
| `word_chivin` | chivin |
| `word_chizg_ich` | chizgʻich |
| `word_cho_tka` | choʻtka |
| `word_choy` | choy |
| `word_daftar` | daftar |
| `word_dala` | dala |
| `word_daraxt` | daraxt |
| `word_delfin` | delfin |
| `word_dengiz` | dengiz |
| `word_devor` | devor |
| `word_dori` | dori |
| `word_dunyo` | dunyo |
| `word_echki` | echki |
| `word_eshak` | eshak |
| `word_eshik` | eshik |
| `word_et` | et |
| `word_etik` | etik |
| `word_ferma` | ferma |
| `word_fil` | fil |
| `word_fonar` | fonar |
| `word_fontan` | fontan |
| `word_futbol` | futbol |
| `word_g_ildirak` | gʻildirak |
| `word_g_isht` | gʻisht |
| `word_g_or` | gʻor |
| `word_g_oz` | gʻoz |
| `word_gazeta` | gazeta |
| `word_gilos` | gilos |
| `word_globus` | globus |
| `word_gubka` | gubka |
| `word_gul` | gul |
| `word_guruch` | guruch |
| `word_hammom` | hammom |
| `word_hamyon` | hamyon |
| `word_hokkey` | hokkey |
| `word_hovli` | hovli |
| `word_hujjat` | hujjat |
| `word_idish` | idish |
| `word_igna` | igna |
| `word_ikki` | ikki |
| `word_ilon` | ilon |
| `word_inson` | inson |
| `word_ip` | ip |
| `word_it` | it |
| `word_jamoa` | jamoa |
| `word_jinsi` | jinsi |
| `word_jiraf` | jiraf |
| `word_jo_ja` | joʻja |
| `word_jun` | jun |
| `word_kalit` | kalit |
| `word_karam` | karam |
| `word_kema` | kema |
| `word_kitob` | kitob |
| `word_kiyik` | kiyik |
| `word_koptok` | koptok |
| `word_kuchuk` | kuchuk |
| `word_lab` | lab |
| `word_lampa` | lampa |
| `word_lenta` | lenta |
| `word_lift` | lift |
| `word_lola` | lola |
| `word_makkajo_xori` | makkajoʻxori |
| `word_mashina` | mashina |
| `word_masjid` | masjid |
| `word_meva` | meva |
| `word_mikroskop` | mikroskop |
| `word_ming` | ming |
| `word_mix` | mix |
| `word_mushuk` | mushuk |
| `word_muz` | muz |
| `word_nay` | nay |
| `word_nok` | nok |
| `word_non` | non |
| `word_nonushta` | nonushta |
| `word_nur` | nur |
| `word_o_g_il` | oʻgʻil |
| `word_o_rdak` | oʻrdak |
| `word_o_rgimchak` | oʻrgimchak |
| `word_o_rmon` | oʻrmon |
| `word_o_t` | oʻt |
| `word_o_tin` | oʻtin |
| `word_ohang` | ohang |
| `word_olcha` | olcha |
| `word_olma` | olma |
| `word_olov` | olov |
| `word_ona` | ona |
| `word_oqqush` | oqqush |
| `word_oshxona` | oshxona |
| `word_ot` | ot |
| `word_oy` | oy |
| `word_oyna` | oyna |
| `word_palma` | palma |
| `word_palto` | palto |
| `word_paypoq` | paypoq |
| `word_pingvin` | pingvin |
| `word_piyoz` | piyoz |
| `word_pomidor` | pomidor |
| `word_poyezd` | poyezd |
| `word_pul` | pul |
| `word_qalam` | qalam |
| `word_qaychi` | qaychi |
| `word_qo_y` | qoʻy |
| `word_qor` | qor |
| `word_qovun` | qovun |
| `word_qozon` | qozon |
| `word_qulf` | qulf |
| `word_qush` | qush |
| `word_quyosh` | quyosh |
| `word_ra_no` | raʼno |
| `word_raketa` | raketa |
| `word_randa` | randa |
| `word_rang` | rang |
| `word_raqs` | raqs |
| `word_rasm` | rasm |
| `word_robot` | robot |
| `word_ruchka` | ruchka |
| `word_sabzi` | sabzi |
| `word_shaftoli` | shaftoli |
| `word_shahar` | shahar |
| `word_shakar` | shakar |
| `word_shar` | shar |
| `word_shim` | shim |
| `word_shisha` | shisha |
| `word_shlyapa` | shlyapa |
| `word_shokolad` | shokolad |
| `word_sholg_om` | sholgʻom |
| `word_sichqon` | sichqon |
| `word_sigir` | sigir |
| `word_singil` | singil |
| `word_soat` | soat |
| `word_stul` | stul |
| `word_sut` | sut |
| `word_suv` | suv |
| `word_tarvuz` | tarvuz |
| `word_telefon` | telefon |
| `word_tish` | tish |
| `word_tog_` | togʻ |
| `word_tong` | tong |
| `word_tovuq` | tovuq |
| `word_tuya` | tuya |
| `word_tuz` | tuz |
| `word_ukki` | ukki |
| `word_usta` | usta |
| `word_uy` | uy |
| `word_uzuk` | uzuk |
| `word_uzum` | uzum |
| `word_vagon` | vagon |
| `word_vaza` | vaza |
| `word_velosiped` | velosiped |
| `word_vilka` | vilka |
| `word_vulqon` | vulqon |
| `word_xalta` | xalta |
| `word_xamir` | xamir |
| `word_xarita` | xarita |
| `word_xat` | xat |
| `word_xo_roz` | xoʻroz |
| `word_yaproq` | yaproq |
| `word_yer` | yer |
| `word_yo_l` | yoʻl |
| `word_yog_` | yogʻ |
| `word_yomg_ir` | yomgʻir |
| `word_yong_oq` | yongʻoq |
| `word_yoz` | yoz |
| `word_yulduz` | yulduz |
| `word_yurak` | yurak |
| `word_zanjir` | zanjir |
| `word_zavod` | zavod |
| `word_zaytun` | zaytun |
| `word_zebra` | zebra |
| `word_zontik` | zontik |

## 6. Quloq o'yini — noto'g'ri aytilishi (60 ta)

Bola qanday xato qilsa, aynan shunday ayting: aniq, lekin masxara qilmasdan.

| Fayl | Nima deyiladi |
|---|---|
| `wrong_ayya` | ayya (arra o'rniga) |
| `wrong_bagon` | bagon (vagon o'rniga) |
| `wrong_baza` | baza (vaza o'rniga) |
| `wrong_bilka` | bilka (vilka o'rniga) |
| `wrong_bulqon` | bulqon (vulqon o'rniga) |
| `wrong_deniz` | deniz (dengiz o'rniga) |
| `wrong_dilos` | dilos (gilos o'rniga) |
| `wrong_dubka` | dubka (gubka o'rniga) |
| `wrong_dul` | dul (gul o'rniga) |
| `wrong_duruch` | duruch (guruch o'rniga) |
| `wrong_gildirak` | gildirak (gʻildirak o'rniga) |
| `wrong_gisht` | gisht (gʻisht o'rniga) |
| `wrong_gor` | gor (gʻor o'rniga) |
| `wrong_goz` | goz (gʻoz o'rniga) |
| `wrong_kalta` | kalta (xalta o'rniga) |
| `wrong_kamir` | kamir (xamir o'rniga) |
| `wrong_kat` | kat (xat o'rniga) |
| `wrong_ko_roz` | koʻroz (xoʻroz o'rniga) |
| `wrong_ko_y` | koʻy (qoʻy o'rniga) |
| `wrong_kor` | kor (qor o'rniga) |
| `wrong_kulf` | kulf (qulf o'rniga) |
| `wrong_kush` | kush (qush o'rniga) |
| `wrong_laketa` | laketa (raketa o'rniga) |
| `wrong_lasm` | lasm (rasm o'rniga) |
| `wrong_lobot` | lobot (robot o'rniga) |
| `wrong_min` | min (ming o'rniga) |
| `wrong_og_il` | ogʻil (oʻgʻil o'rniga) |
| `wrong_ordak` | ordak (oʻrdak o'rniga) |
| `wrong_ot` | ot (oʻt o'rniga) |
| `wrong_otin` | otin (oʻtin o'rniga) |
| `wrong_perma` | perma (ferma o'rniga) |
| `wrong_pil` | pil (fil o'rniga) |
| `wrong_pinvin` | pinvin (pingvin o'rniga) |
| `wrong_ponar` | ponar (fonar o'rniga) |
| `wrong_pontan` | pontan (fontan o'rniga) |
| `wrong_sahar` | sahar (shahar o'rniga) |
| `wrong_sanjir` | sanjir (zanjir o'rniga) |
| `wrong_sar` | sar (shar o'rniga) |
| `wrong_savod` | savod (zavod o'rniga) |
| `wrong_saytun` | saytun (zaytun o'rniga) |
| `wrong_sebra` | sebra (zebra o'rniga) |
| `wrong_shana` | shana (chana o'rniga) |
| `wrong_shelak` | shelak (chelak o'rniga) |
| `wrong_shipta` | shipta (chipta o'rniga) |
| `wrong_shoy` | shoy (choy o'rniga) |
| `wrong_sim` | sim (shim o'rniga) |
| `wrong_sinil` | sinil (singil o'rniga) |
| `wrong_sisa` | sisa (shisha o'rniga) |
| `wrong_talit` | talit (kalit o'rniga) |
| `wrong_taram` | taram (karam o'rniga) |
| `wrong_tema` | tema (kema o'rniga) |
| `wrong_titob` | titob (kitob o'rniga) |
| `wrong_yab` | yab (lab o'rniga) |
| `wrong_yampa` | yampa (lampa o'rniga) |
| `wrong_yift` | yift (lift o'rniga) |
| `wrong_yoya` | yoya (lola o'rniga) |
| `wrong_zamoa` | zamoa (jamoa o'rniga) |
| `wrong_zinsi` | zinsi (jinsi o'rniga) |
| `wrong_zo_za` | zoʻza (joʻja o'rniga) |
| `wrong_zun` | zun (jun o'rniga) |

