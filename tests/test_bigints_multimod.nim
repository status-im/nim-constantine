# Constantine
# Copyright (c) 2018-2019    Status Research & Development GmbH
# Copyright (c) 2020-Present Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  # Standard library
  unittest,
  # Third-party
  ../constantine/io/io_bigints,
  ../constantine/arithmetic/bigints,
  ../constantine/primitives

proc main() =
  suite "Bigints - Multiprecision modulo":
    test "bitsize 237 mod bitsize 192":
      let a = BigInt[237].fromHex("0x123456789012345678901234567890123456789012345678901234567890")
      let m = BigInt[192].fromHex("0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB")

      let expected = BigInt[192].fromHex("0x34567890123456789012345678901234567886f8091a3087")

      var r: BigInt[192]
      r.reduce(a, m)

      check:
        bool(r == expected)

    test "bitsize 365 mod bitsize 258":
      block:
        let a = BigInt[365].fromHex("0x6c8ae85a6cab4bc530b91177e3f399894ff1fe335b6b3fcdc577ea4f8d754bbe71a6353e8609a4769ec8c56727a")
        let m = BigInt[258].fromHex("0x2cadadfa2bb7d7141ad9728d6955ddb68a8b81ecb6a7610575bf4d6f562b09f0d")

        let expected = BigInt[258].fromHex("0xb7c8844f534bf298645dc118384e975245c1a44ba4b0bca8a04c9db0c9035b9")

        var r: BigInt[258]
        r.reduce(a, m)

        check:
          bool(r == expected)

      block:
        let a = BigInt[365].fromHex("0xbf3e7574adacfcba0016a92269ef5db4a6252cda4f0493e968a83f33657b85a7d23d59630a1f5455ff426ecb9ee")
        let m = BigInt[258].fromHex("0x38aa8382b17797e08a89487925eb716be55620aa482a7098b4d02a4a30a4a1178")

        let expected = BigInt[258].fromHex("0x2512663958ef1b3e6e7f14ce722e72d82e10cbdd05e9fdcfb7cd5580bf074a3fe")

        var r: BigInt[258]
        r.reduce(a, m)

        check:
          bool(r == expected)

      block:
        let a = BigInt[365].fromHex("0x16e20483c4a7f891fae2ddd77688fe72718c843ef4bc211069365a4e23bdc0b62680248fb0bf88760810de9f592b")
        let m = BigInt[258].fromHex("0x315d9c9ed0df4257a2db89e907e5f8a06e26d149e058b73c6db33bdc84c1619a4")

        let expected = BigInt[258].fromHex("0x1b264b514412fdfb7579204afaad1b96d09ed6e4c985baf7e96815ab1c065e88f")

        var r: BigInt[258]
        r.reduce(a, m)

        check:
          bool(r == expected)

    test "bitsize 1955 mod bitsize 459":
        let a = BigInt[1955].fromHex("0x4f688e286a7c6e2b64663d8925c2f686994f2b90d58e7a843087c676c2c614ebab3eef9c765a88fe597b23b0e1fb28c812627366020edeafeefd0bf67a95215b4335412e2bd623b4cf7b69e669e1a8e782ab9a3e5fd443f10f459eed4ec9bd61821d94da82e937989245d481612b83b75d6d393e5de2258ac92aec7cd6e4f12c6b035e1fac3ef22851a8e211232b57db7551c03a88e9272411eea86e15c989be9d2962d5ae32ca35b18060212aaf6599b5a5f2416e436f009728b4017f87f70f4e528c9a33042b6810040c1e64457d56695d03b701540a5537c8cf781ff2ea4be2aa6daf1a5f2f0874a1cf495485a01254c2e2f4a")
        let m = BigInt[459].fromHex("0x47304803a4a8c31e18287ad51c1ac7546c42e23206e9dc43e51eff5fa003f44bd08e542ec2659c405bfa4c9eb518ada943412767361029a902b")

        let expected = BigInt[459].fromHex("0x1f039dfe7c9da071d578b3b852db3916f4d79f6169818085994cbc41610abb7abb96e10d1126313cc281a87c309c2dd43bed745a9603f3c606c")

        var r: BigInt[459]
        r.reduce(a, m)

        check:
          bool(r == expected)

    test "bitsize 2346 mod bitsize 97":
        let a = BigInt[2346].fromHex("0x1b5efa688e4124a71edd035f106c6ea81bafd78f610cd59d46fc6cda548fd970dde6b91c6fa10ab6d198026dea3c46c41495294082f2acc8210fd7ebfb25fdc6ce8131676ab0d749c5a4a83dd08172b3849df30304685192708ff0b510600cbf87be3179ce704adc43f2c9b22ba28c77f0a364fa1a96344d7f338227a8f346c0e721bc1312f53cebfc20fd0763ec039aa83a77ba489056ebee2a462058f1daffec9b5df29474f638185c6684729482a29764b46a5487e159fc4eedda5018d3d18ae1c0c6503ebbbd859b4dff3e09b6567b752d51c9733fc822b2758b69ffd65974a8fbf4ad25a40761bb9b9b6a1f886928fe08f9c1571fe3e3987b15e37208a22f64e2c3ff75a36815b7906fc2a52f7bd32d15e8b0441e8c39ae9127d80946e146db5cd2738")
        let m = BigInt[97].fromHex("0x1100d0717f9fff44c6cc7442e")

        let expected = BigInt[97].fromHex("0x0104ea05300eeb05cd374197b6")

        var r: BigInt[97]
        r.reduce(a, m)

        check:
          bool(r == expected)

    test "bitsize 1882 mod bitsize 312":
        let a = BigInt[1882].fromHex("0x3feb1d432a950d856fc121c5057671cf81bf9d283a30b69128e84d57900aba486136b9e93f96293dbf7e280b8a641d970748b27ba0986411c7359f32f37447e34ae9e9189336269326fb62fd4d0891bf2383548e8ada92517cf5001e449dd5b4c6501b361636c13f3d5db5ed40f7048f8b1b8db65e9a34a08992e19527ded175fd6b4c4559c25c384691f0567ad27cf5df2b4192d94dc3bf596216067fd02a3790c048bc4bff16e70f84c395ff1243d4b92b514d0c22fc35a82611b77137f09ec8bc31df58fbea2b532ef38ed9078bd2982893326833a20daf2792bdf1ac75ca80e2ffd063f49bb173e7b100")
        let m = BigInt[312].fromHex("0x8bad37615c65cb40b592525aeb19de0b8a3f9db87f3c77050a77050ebe81712d78253cdc0eafec")

        let expected = BigInt[312].fromHex("0x1d79fa2f576827a70b38b303036884b346fc52941b2df0863e8f635c467ea1aec04520e6feb614")

        var r: BigInt[312]
        r.reduce(a, m)

        check:
          bool(r == expected)

    test "bitsize 5276 mod bitsize 337":
        let a = BigInt[5276].fromHex("0xdcc610304e437c91df568effa736e9ec472d921d2e32f0123f59f8a0e7a639a84db3d6e91c4ce9164e2183aeb9efdfdf5b179b1e5b8074602193b9ba0f5cf547ce31c6c6d33317c40fdcc66090d13034a8ed82b1244cd9e82ec43b08a4a8cd7aaa4937b72b19b01c942427db3e630e70f6823f36a4d0db17b0515ab1582672f613c22f43b2743929d92a924b2d7529a08fa2950ac90fd529207d3dd55a65f80f77715b340755f545424375a1f6dfe3eea1309365036d924226297ecd1296c5938a7b18fe36c3126f54161818ff8e29d69c25b7a47a47061f6e76b6ffbe0c2dbcbf83f49b0bd24cb6f2de460e6c6540e15e23e23573a04dff7d18f88e266a1e36627181dd18a9a182182b1c4e1ec8123b916d18a82139c6b2f5cc7206681b21ec3b14f4da44337892a90db21e070c8799a5cd7e81c03b901ade08021401d6a4cd27bef1e1215c65c2e8abadf44cc455383b37c12fe1f25774bbb0552ca54699c8d38cd88b56ff80c130734dbd231f8f2d15e62effe7bfedde43c4d06f06115befbafabcb1128b3c80f8c6395696f28b6d32c12cc74ba7fcef95e97bd854c98716b6c079d971199a4d3fa4f6d7f901f5370b3f0a4fa6dddff81820ca012bb821560b86701d25a3c99f0daae5824bc5d4731c1e5e879b94bb0a5a862ac79d22fc42d20d3d8963a49997627d4d246088a21531e58174e55eed8007c7e05bece76c64a368c42a7e178b0ba0ce3b54f1d9a568755c71f3518e5d10caa2eda8edd74f13c41b70c6ff0a75f6b821b38cb6148acf6890fc79d508cfa741c8514498b81aaf1698420bf844742d325afe8fce3e85c1d2aefc6bc254e3628f19116643a538c6657a937d62069dfe7217a9e9138e8a12f9857c9eb671c2adb3b3129d0653eb62296bdcfe51335b966e39838a4b18fce380af1f00")
        let m = BigInt[337].fromHex("0x016255c2e37f1b1405f9f195040e80778b896b23a1487a40ece792894025590800bcadc343fcef4e2d01b8")

        let expected = BigInt[337].fromHex("0x66bb36adf84b9024f97100688cc66be2f412fd91e9bae3623e810dcae86166a52bdb4c889fa0e5d128d8")

        var r: BigInt[337]
        r.reduce(a, m)

        check:
          bool(r == expected)

    test "bitsize 4793 mod bitsize 190":
        let a = BigInt[4793].fromHex("0x20924645cabc04f0213ba42961e10dedd2c6bd0c9625d04949037b15f9546001551651049038285b441824ef5540a174da0d5ab5f6f07750b9d6ea21a8dd127b467cd1ff0d547d7c86705402bfb8efee231c8385d14666d4e5fdd4e4e6c230ed61b631a6387c57823578139db306c1687bb950985e608c2792694e895e97039c0c155c79b3d595b391f5f8217feeebc20b093658d3e7612449ef575da3d0cde0d3726c58ca9302952deaee8b44a31029086db65838767c60b63f68f9c207ca128574ff9023fc29de264c8e4df20b7764064f9228a2481d5936cc840e107f73b04fcf31f8060c38ea5fb9c8f165e4bbdd1c7b8f0cfb950be57d87678a0a3d45eb1ccbef1a977e881de4f4f95ef0e144a0486ca47084a565242a2baab7a5383e85d51c466d7b03e1f06285bfe04cbb4b90e829a50af103ab8a812cfdad100344b3ae0ab3b96e26a0d97cf16d1910212471f9b3f5e3d0133360387ca3a52682d68447e7ac454e321bc5381a24ff5348baad68d3609a7dfa2118275f2620cf30b1ebb21d98b1d783b45c2acf4a9a9b1cfeba21b2fe1d93fda3234ee90bdba1b23e3a514c7e2189f7bf07236397e1efc5cb5b3a3e748ba130272d880b9d74fc6c2386f19c9e51093ce885ad60493a3d4d0c84154e6fb6d4bb222207eb9f3a2136cebe883a5a89b95eba5363c113f330636d00dda40f3445afb651a56a1d00e5d3815b3c06f123e5eb6b8ce5621ab8f05765fe803e94a12998c249cb1e84c9c4785c8631454283e0471149bc541eebc691b3231e4969b433b9c8195db915cb3baef8db7b3ab0dff2aa7f284e5b86e8055ab95bf45086a216138000")
        let m = BigInt[190].fromHex("0x3cf10d948e00a135ab10a6d073b8289e8465d5798d06891c")

        let expected = BigInt[190].fromHex("0x1154587f8cfac96bc146790bc49262ad32e1560a0bf734a4")

        var r: BigInt[190]
        r.reduce(a, m)

        check:
          bool(r == expected)

    test "bitsize 5240 mod bitsize 3072":
        let a = BigInt[5240].fromHex("0xfd76093ad413df93dddded94a16c17ffbdd1d8ce9377f5940af54293410603fd381822bb9cec0074005f68dd7bc33f879fb0613b9cd0bac50c27e5e40a0c3948e5b4a07e6c9b1795f2f60647d67b9fd5025d82deffcbb62209a921eb766f7a2335d1b6ca0a4877c948d5cf68aaa2d5bdbea3f991eb027b91d03c91712d739cf6522279007add5febb85fe8f5ef661641fc2dc36b37e709d77f3a0f016f1b421527d2a28c9e8734f243a81e985a26e6ec5650ae81f10381869a9a78e5dac5e6d65783c40f8c232398425e96da2c6d94290ee6463580c826c609691a860f8ceb233a072fca384a9a74d15beaad7df8f1dcde437a02db6218b0c0bca43f9f936bdede271b730b098cf4dd97a84a10feb7eb04841ac01e4728a12a1f96b88ac91bef33818095777893813635cc918480f255a45bf9ebc740e3992877879d4ee64b1aad22439dc9872e5ff13a25dcb32669dab77e05982adbfb06073d5b9bd2b0dcdc7a515296b13e7251d3fb6ca132492f66d312e2610011284b6a2f2a1c26a873959ff5935ddd1e229d4ec7cdf3fa1ce1f55bc549481adfee5ec8aa8b4eddad88c74298d50c2d310be6c21e92067bf8b5ae2330f750f60122251d1fcf84c58a3abee3bed8715dda1c016eb58672faed0a5c678806028195586a349702eeff0738d14ac9a2ced66a50e894cf0a3d546608e6666443d5ea4bc6e7078ae356257ce12fc3d6cf84fe52f13fe27ad89038d041698ed615c856d326d2f1fc5cc916a5176d44a965cf5247b81b901212eb3f35912e82d68b28fe438b3f9cb43362794a53976dcc6ec21aa097813e47f7cb02af3e2bdd9f4323e3ffb577a800cdb5fe925b832263db0332a235c6d8de3df97d8a963c8062f1d39aa302f8db2e2ac292fb6f66d4e2e074e8ce4c77ca0a311bcd3455")
        let m = BigInt[3072].fromHex("0x82a3b927471854fe51e4246c36e83a110ab5fec30a5f26fca0316b8ab42784bc17015ef9d0217769e695b92bfe4f30ffcfef881179edc6623dcaf305ee4424da00d8c49a873535e095ac64a8cc66767c26ffa7f2f1acdaedd82b09b62d297f951cd3af83e7023b4eafea8056fc9e4f53f03eb9ee93613d58219214f8d884f51d4e09b336a4bf53fb29a4394fc9b8d4004f4ab04cdfda43441e63846e3dbd02c46ab521b85a16d4a063c33be63e88c9b3fec486f9eda4958a167cb4dd64dd44c7047e4f1372e6ce6f29bbc4a6cc0f498c0428dbc35daaa81abedd937e602ce3eb38666f0ccd603955949e068dd005e2e2bf6d423fd183fcbf61c504eeffa589c3482251b1191e7d71b8e31fc05979b4ebb6ab57ce810d6e34144a8417ab2ca45709b3841bb08cbf38658d2f4129adee121933369deb238db2f74df4490ea5486685554cc4dac015f4d09ded70a4fc808b080142eb7c865fe8e89046f3c0de448f1442258d2cd565dfd457cfb49ab0c0a735196e6cb06a962f29e53060576327b8")

        let expected = BigInt[3072].fromHex("0x75be9187192dccf08bedcb06c7fba60830840cb8a5c3a5895e63ffd78073f2f7e0ccc72ae2f91c2be9fe51e48373bf4426e6e1babb9bc5374747a0e24b982a27359cf403a6bb900800b6dd52b309788df7f599f3db6f5b5ba5fbe88b8d03ab32fbe8d75dbbad0178f70dc4dfbc39008e5c8a4975f08060f4af1718e1a8811b0b73daabf67bf971c1fa79d678e3e2bf878a844004d1ab5b11a2c3e4fa8abbbe15b75a4a15a4c0eecd128ad7b13571545a967cac88d1b1e88c3b09723849c54adede6b36dd21000f41bc404083bf01902d2d3591c2e51fe0cc26d691cbc9ba6ea3137bd977745cc8761c828f7d54899841701faeca7ff5fc975968693284c2dcaf68e9852a67b5782810834f2eed0ba8e69d18c2a9d8aa1d81528110f0156610febe5ee2db65add65006a9f91370828e356c7751fa50bb49f43b408cd2f4767a43bc57888afe01d2a85d457c68a3eb60de713b79c318b92cb1b2837cf78f9e6e5ec0091d2810a34a1c75400190f8582a8b42f436b799db088689f8187b6db8530d")

        var r: BigInt[3072]
        r.reduce(a, m)

        check:
          bool(r == expected)

main()
