open Bitcoinml;;
open Stdint;;
open OUnit2;;
open Hex;;

let base58_encode_check_test octx =
	let adr = Hex.to_string (`Hex "00010966776006953D5567439E5E39F86A0D273BEED61967F6") in
	let adrb58 = Base58.encode_check adr in
	assert_equal adrb58 "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM"
;;

let varint_parse_test bl res octx =
	let v1 = Varint.parse_varint (Bitstring.bitstring_of_string (Hex.to_string bl)) in
	assert_equal (fst v1) (Uint64.of_int res)
;;

let varint_serialize_test bl res octx =
	let l = Varint.bitstring_of_varint (Int64.of_int res) in
	assert_equal (Bitstring.string_of_bitstring l) (Hex.to_string bl)
;;

let script_parse_test sc scdec octx =
	let s = Script.parse (Hex.to_string sc) in
	assert_equal (fst s) (fst scdec)
;;

let script_to_string_test sc r octx =
	let s = Script.to_string sc in
	assert_equal s r
;;

let script_serialize_test sc scdec octx =
	let s = Script.serialize scdec in
	assert_equal (Hex.to_string sc) s
;;

let script_is_spendable_test sc octx =
	assert_equal (Script.is_spendable sc) true
;;

let script_spendable_by_test prefix sc adr octx =
	let s = Script.spendable_by sc prefix in
	assert_equal s (Some adr)
;;

let tx_parse_test raw octx =
	let raw', tx = Tx.parse (Hex.to_string raw) in
	match tx with
	| None -> assert_equal true false
	| Some (t) -> 
		(*Printf.printf "Serialized:\n%s\n\nRaw:\n%s\n----------\n" (Hex.hexdump_s @@ Hex.of_string (Tx.serialize t)) (Hex.hexdump_s @@ raw);*)
		assert_equal (Tx.serialize t) (Hex.to_string raw)
;;

let tx_to_string_test raw r octx =
	let raw', tx = Tx.parse (Hex.to_string raw) in
	match tx with
	| None -> assert_equal true false
	| Some (t) -> 
		(*Printf.printf "%s\n" @@ Tx.to_string t;*)
		Tx.to_string t |> assert_equal r
;;

let block_header_parse_test raw octx =
	let bl = Block.Header.parse (Hex.to_string raw) in
	match bl with
	| None -> assert_equal true false
	| Some (b) -> 
		assert_equal (Hex.to_string raw) @@ Block.Header.serialize b
;;


let block_parse_test raw octx =
	let bl = Block.parse (Hex.to_string raw) in
	match bl with
	| None -> assert_equal true false
	| Some (b) -> 
		assert_equal (Hex.to_string raw) @@ Block.serialize b
;;

let block_merkle_verify_test raw octx =
	let bl = Block.parse (Hex.to_string raw) in
	match bl with
	| None -> assert_equal true false
	| Some (b) -> 
		Merkle.of_txs b.txs |> assert_equal b.header.merkle_root
;;

let block_to_string_test raw r octx =
	let bl = Block.parse (Hex.to_string raw) in
	match bl with
	| None -> assert_equal true false
	| Some (b) -> 
		Block.to_string b |> assert_equal r
;;

let address_of_pub_test prefix pub addr octx =
	assert_equal
		addr @@ Address.of_pub prefix (Hex.to_string pub) 
;;

let address_of_pubhash_test prefix pub addr octx =
	assert_equal
		addr @@ Address.of_pubhash prefix (Hex.to_string pub) 
;;

let merkle_of_hashes_test hl mr octx =
	assert_equal 
		mr @@ Merkle.of_hashes hl
;;

let suite = "bitcoinml" >::: [
	"base58.encode_check" 	>:: base58_encode_check_test;
	
	"varint.parse" 			>:: varint_parse_test (`Hex "16") 0x16;
	"varint.parse2" 		>:: varint_parse_test (`Hex "FE32323232") 0x32323232;
	(*"varint.parse3" 		>:: varint_parse_test (`Hex "FF3232323232323232") 0x3232323232323232;*)
	"varint.serialize"		>:: varint_serialize_test (`Hex "16") 0x16;
	"varint.serialize2" 	>:: varint_serialize_test (`Hex "FE32323232") 0x32323232;
	(*"varint.serialize3"	>:: varint_serialize_test (`Hex "FF3232323232323232") 0x3232323232323232;*)

	"script.parse" 			>:: script_parse_test (`Hex "76A91489ABCDEFABBAABBAABBAABBAABBAABBAABBAABBA88AC")
		([
			Script.OP_DUP; Script.OP_HASH160; Script.OP_DATA (20, Hex.to_string (`Hex "89ABCDEFABBAABBAABBAABBAABBAABBAABBAABBA"));
			Script.OP_EQUALVERIFY; Script.OP_CHECKSIG
		], 25);
	"script.serialize" 		>:: script_serialize_test (`Hex "76A91489ABCDEFABBAABBAABBAABBAABBAABBAABBAABBA88AC")
		([
			Script.OP_DUP; Script.OP_HASH160; Script.OP_DATA (20, Hex.to_string (`Hex "89ABCDEFABBAABBAABBAABBAABBAABBAABBAABBA"));
			Script.OP_EQUALVERIFY; Script.OP_CHECKSIG
		], 25);
	"script.is_spendable"	>:: script_is_spendable_test
		([
			Script.OP_DUP; Script.OP_HASH160; Script.OP_DATA (20, Hex.to_string (`Hex "89ABCDEFABBAABBAABBAABBAABBAABBAABBAABBA"));
			Script.OP_EQUALVERIFY; Script.OP_CHECKSIG
		], 25);
	"script.spendable_by"	>:: script_spendable_by_test
		{ pubkeyhash= 0x00; scripthash= 0x05 }
		([
			Script.OP_DUP; Script.OP_HASH160; Script.OP_DATA (20, Hex.to_string (`Hex "89ABCDEFABBAABBAABBAABBAABBAABBAABBAABBA"));
			Script.OP_EQUALVERIFY; Script.OP_CHECKSIG
		], 25)
		"1DYwPTpZuLjY2qApmJdHaSAuWRvEF5skCN";
	"script.to_string" >:: script_to_string_test
		([
			Script.OP_DUP; Script.OP_HASH160; Script.OP_DATA (20, Hex.to_string (`Hex "89ABCDEFABBAABBAABBAABBAABBAABBAABBAABBA"));
			Script.OP_EQUALVERIFY; Script.OP_CHECKSIG
		], 25)
		"((OP_DUP OP_HASH160(OP_DATA 20 baabbaabbaabbaabbaabbaabbaabbaabefcdab89)OP_EQUALVERIFY OP_CHECKSIG)25)";

	"tx.parse" 		>:: tx_parse_test (`Hex "01000000017b1eabe0209b1fe794124575ef807057c77ada2138ae4fa8d6c4de0398a14f3f00000000494830450221008949f0cb400094ad2b5eb399d59d01c14d73d8fe6e96df1a7150deb388ab8935022079656090d7f6bac4c9a94e0aad311a4268e082a725f8aeae0573fb12ff866a5f01ffffffff01f0ca052a010000001976a914cbc20a7664f2f69e5355aa427045bc15e7c6c77288ac00000000");
	"tx.parse_witness" >:: tx_parse_test (`Hex "0100000000010115e180dc28a2327e687facc33f10f2a20da717e5548406f7ae8b4c811072f85603000000171600141d7cd6c75c2e86f4cbf98eaed221b30bd9a0b928ffffffff019caef505000000001976a9141d7cd6c75c2e86f4cbf98eaed221b30bd9a0b92888ac02483045022100f764287d3e99b1474da9bec7f7ed236d6c81e793b20c4b5aa1f3051b9a7daa63022016a198031d5554dbb855bdbe8534776a4be6958bd8d530dc001c32b828f6f0ab0121038262a6c6cec93c2d3ecd6c6072efea86d02ff8e3328bbd0242b20af3425990ac00000000");

	"tx.to_string" >:: tx_to_string_test
		(`Hex "01000000017b1eabe0209b1fe794124575ef807057c77ada2138ae4fa8d6c4de0398a14f3f00000000494830450221008949f0cb400094ad2b5eb399d59d01c14d73d8fe6e96df1a7150deb388ab8935022079656090d7f6bac4c9a94e0aad311a4268e082a725f8aeae0573fb12ff866a5f01ffffffff01f0ca052a010000001976a914cbc20a7664f2f69e5355aa427045bc15e7c6c77288ac00000000")
		"((hash c7736a0a0046d5a8cc61c8c3c2821d4d7517f5de2bc66a966011aaa79965ffba)(version 1)(txin(((out_hash 3f4fa19803dec4d6a84fae3821da7ac7577080ef75451294e71f9b20e0ab1e7b)(out_n 0)(script(((OP_DATA 72 015f6a86ff12fb7305aeaef825a782e068421a31ad0a4ea9c9c4baf6d79060657920023589ab88b3de50711adf966efed8734dc1019dd599b35e2bad940040cbf049890021024530))73))(witness_script())(sequence -1))))(txout(((value 4999990000)(script((OP_DUP OP_HASH160(OP_DATA 20 72c7c6e715bc457042aa55539ef6f264760ac2cb)OP_EQUALVERIFY OP_CHECKSIG)25)))))(locktime 0)(size 158)(witness()))";
	"tx.to_string_witness" >:: tx_to_string_test 
		(`Hex "0100000000010115e180dc28a2327e687facc33f10f2a20da717e5548406f7ae8b4c811072f85603000000171600141d7cd6c75c2e86f4cbf98eaed221b30bd9a0b928ffffffff019caef505000000001976a9141d7cd6c75c2e86f4cbf98eaed221b30bd9a0b92888ac02483045022100f764287d3e99b1474da9bec7f7ed236d6c81e793b20c4b5aa1f3051b9a7daa63022016a198031d5554dbb855bdbe8534776a4be6958bd8d530dc001c32b828f6f0ab0121038262a6c6cec93c2d3ecd6c6072efea86d02ff8e3328bbd0242b20af3425990ac00000000")
		"((hash 6bf4e4dfb860cf0906f49c836700b130ac78cc391c72a0911c94cdec4dcb10ec)(version 1)(txin(((out_hash 56f87210814c8baef7068454e517a70da2f2103fc3ac7f687e32a228dc80e115)(out_n 3)(script(((OP_DATA 22 28b9a0d90bb321d2ae8ef9cbf4862e5cc7d67c1d1400))23))(witness_script((ac905942f30ab24202bd8b32e3f82fd086eaef72606ccd3e2d3cc9cec6a6628203 01abf0f628b8321c00dc30d5d88b95e64b6a773485bebd55b8db54551d0398a116200263aa7d9a1b05f3a15a4b0cb293e7816c6d23edf7c7bea94d47b1993e7d2864f70021024530)))(sequence -1))))(txout(((value 99987100)(script((OP_DUP OP_HASH160(OP_DATA 20 28b9a0d90bb321d2ae8ef9cbf4862e5cc7d67c1d)OP_EQUALVERIFY OP_CHECKSIG)25)))))(locktime 0)(size 218)(witness(((hash 0000000000000000000000000000000000000000000000000000000000000000)(marker 0)(flag 1)(size 0)))))";

	"block.header.parse" >:: block_header_parse_test (`Hex "02000000f6e1cc50df9bfb420162e365fd26d783581367c0a4a7f2683ee60702000000000e65cda8974f3989caeafcaa46ad665ffd07fe558cb63f3f639fee284db83aa4436c6b500045011cec2b25fb");
	"block.parse" >:: block_parse_test (`Hex "0100000040f11b68435988807d64dff20261f7d9827825fbb37542601fb94d45000000000f28f7c69e2669981f92ff081c129e196200c60f4fad7911d93a682de0b49ea2ecd9d24c1844011d00d361050c01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff07041844011d0142ffffffff0100f2052a01000000434104a313febd5f91b6a13bd9c5317030518fee96d1319a0eb10076917294933d09c17dc1588a06953a264738f2acea0c66b99e796caa4f28158e0dd5f6fed69a185bac000000000100000001aa18a952c3f73e5d7440bc570b2aa78f72059887b25b6a1790514b7feedec090000000008b483045022100a970ee6e96fa8bea1cf76d3bda3fb70441a6ec50014d4ea3adcdeae9fbfb5129022025ce9e090366dd6175071a0a5b4a4727571b9bd7bdd5a74d3d3bad7f63eb5dd4014104ac44bdf511477465cb70fef1d06b9241e74d26047ccbdfa641ec9a0115ad35594cbb58a61a6fd56893a405bcffbf6555995ddedc7e6cd4e5ceb83a37e1cf8f98ffffffff02004d92d86a0000001976a914b8083945473bc8289efb681f94de7b07a5b851ad88ac00743ba40b0000001976a914ef01911c9efec6799d1ee5f7c6fb072d9669da8088ac000000000100000001438bd97cb2172e0dd6f341e455e00b7d089747bd4e7f54bd802afe6a6d006c7c000000008a47304402207db94026c96572519101a08e2c864bbe51c987eda6266079a35286df68f123ca02202d7d24c616776a70cce6cb2f97a424e47c30d466e96b750ca03564810249073c014104880286646dab4c894a5ff1bf62bd80047a50b86446b326f2155de94a54d01f9058d4cbc7452563a7c18b2bfb353262fc5adac6307a9446e8c4669daa58e97071ffffffff0200743ba40b0000001976a914fce443c743b456606d1e70ff0d98c4609addc10688ac00ba1dd2050000001976a91411e3e67c08e5d791c97b3d49a8d52025d3f78d3a88ac000000000100000001dc4a6300b6eca8d7ab8e119e9fc4b18890c0e26ec950e681b8d5e46c214aee24010000008b48304502202bcf8632a11192f6b4998343c13589771e6715a080236087dcb1771cbab01809022100edcc38488dd70cd38c058994f143ca5d259071b8fe54c66bf67e55d4468dcacb01410475106e33e14e9cf35bc359dd4120b580ecf5412bb8803f2a927aecd4218d1346e242c7056dca2e4c114fcf2f60799bc5e79107bd1a8b8d5135c92f02bdb59834ffffffff0200f2052a010000001976a9146c9715e09fb00ba84af1ff916ff409b4a5dc9ae288ac00c817a8040000001976a914f7be161206700eb7be1bca5768232c61e4694f4788ac000000000100000001b6cc12ff76247895cb7a604d888012136f06bba64654262044ecb93ff7762c2f000000008b48304502206d795045622c7cdfb4a211c5b41d477920437c21e69214ab4a14f10fe0306b78022100840e55114d6922f3c5e44c7cdcf85dc800d1caef64e7846998423e4ba86714e6014104f88ae9067bc05136cb53a8c18f8549f544ff55ab87ada8f3ba7e2aea773ec73585b61f18ade1c0ddd6c447788578be5fb785c245a64d29b7ff5d28b85cbec58cffffffff0200743ba40b0000001976a914c8081083a8b741da2da260bc0656b88c7bfa6fbf88ac00743ba40b0000001976a914fce443c743b456606d1e70ff0d98c4609addc10688ac0000000001000000019a8d70c7a27560b28dfe778db9ce7f2ff235faf98d5123c07991682be90a4c16000000008b483045022100a118c34f63854ee03d15cca2918d592c295035c42e03be7b0c7e86e66d40ea790220558336d2583a1da00ed5bcad2de5d3b9d485431f702bf2f002267b35ab0b41a0014104f88ae9067bc05136cb53a8c18f8549f544ff55ab87ada8f3ba7e2aea773ec73585b61f18ade1c0ddd6c447788578be5fb785c245a64d29b7ff5d28b85cbec58cffffffff0200743ba40b0000001976a914a440ef00c2e1d39be93607da66568caa26e0501888ac00743ba40b0000001976a914e1d3e65f78f962c4e9dfd04db2119aeefa4e111088ac000000000100000001883acd4bff920f19c4e570e6b3e2d7503d1072d3ca098a124e23534ecdc879d5000000008a473044022040677305de69fd8c18e2c54d5b3c67c5c05735cf6b73d420ccd306762c4bfda2022032cd32ac15ac1820265ffce82654a6008cda22a79fb619ebb65e0af806e14f9b0141044423ef78a2859eb57c4a59dc0878141cf5a4b1fdef71d649d3fb5cf8ea6b1114f4086e5d684a0999d4435db99217a994cc3cf7ad435c8f4e44613d9d160916c4ffffffff0100743ba40b0000001976a914fce443c743b456606d1e70ff0d98c4609addc10688ac000000000100000001ceb27fb142ce3bf9a1f263653dc3971332c71dd10e0e83d647037f608c459f12000000008b4830450220389218287e87d0d7b7113eb20cc1cbf1a00d7acdca32bba7f184cd066db74d6a022100b0998058e5a242699a48f931004cf5550f4e8802b866ce1baf1a0b2616861f27014104255a048d416984101c17514a89289a7d5d3dc8c562850c7a3599f0c7c39bcf9c3a43df75e1e614e51d70c5f85212c99298a21f087be93ecba7ef3900d02c0e8bffffffff0200743ba40b0000001976a914211fd13b614521ed566ddd42738381e42c3c2b2088ac00d956345f0000001976a914d3cc345ba8bdf51d7097955f0f259731f4c34f4388ac000000000100000001703701493f08e82bf6d8cb7c517070eee9f62d14904e14636a7b4af4f34180c7010000008a4730440220061a61eae90ffcf13c10c88a88c085b02954f488823c2f5c81e83a5a833e9f3b02204a61498a9668b2793e77fe3b68585f2daff4dd5daf6097a82615035325ada4730141040db6308d6170333e2c50dee4c9f18f0ab84a7a5c4c88a6836a91f39cb8f4712e08bd72979c542d4b3b60e8dc2021c1b3cc45ffaa83f36a9dec3c4473ea2aa2f3ffffffff0200f2052a010000001976a9143e7e087b9b09149e0266b7a416da2709b4ccf58788ac00d6117e030000001976a914777af71a3b2a48e48f2e467f65028d85c1b5eb5288ac0000000001000000014bdc82abc7db9c06613a712e488685c6feb4522d25017b856222171c17d144e0000000008b4830450221009eb7edcbf8d6be63529264b07bb9f40cf1a0ca779235999e40f5311d70706f1102207f65c5f66982519e6d82e13ca3e61f4f071c73da6c5830b3c4461252012b474e0141045af9665878e6696fd069669951acc54a87c5e3b256a9e20cd8858e0dc5a8c53624e0c979096c00af8a8c60136eef9ffa3d511309417b8315b7f9e3e41e805e8fffffffff0100743ba40b0000001976a914e1d3e65f78f962c4e9dfd04db2119aeefa4e111088ac000000000100000001a854b2b84a76e43de59db647121cdfe481bd8ae9623a345c2188369775b533f7010000008c493046022100c4db6ecf679264c9b525628ec5a983710ff45a1d2d4aa0b54ee218ca9a1ad4df022100dc2e0077cfdd3cbeb28f7463632902ad5306f6d5c77c8149e5b9249bfea8060e014104f9a476b612bb9788c64b9b1e4c9d2deaae1ef0baf6eb593a95d00e2ef8a2beb897ea1fb7c3832e842dd6307fd162816c19c8f458fd8dae331dbc9062fb02e5d8ffffffff0200651b90530000001976a914d5c7c9aec292a807005f013c4d2122f7126e257788ac00743ba40b0000001976a914211fd13b614521ed566ddd42738381e42c3c2b2088ac0000000001000000012908482e9f7d31e9dd392bb6e788a329458a3bc95230b468e4b8c578d27a63b3000000008a4730440220549a7b422fc2020671acabfb937349bd87d985b2e4b9698e4ccacc985f61aee102204dc272322079e9114746db2f8d035d82b64523a69cd7be674173e063090cc8ac014104011a6c220a5549ff112c92c6c38dec93f66ef1f0a21d1409b92f0ccf0fb159aa8173a5b2413a45140fc02b45d63775bae03691d9dc87fd7a10d709a04922900cffffffff0200743ba40b0000001976a914211fd13b614521ed566ddd42738381e42c3c2b2088ac00f1dfeb470000001976a9140adcb4e90cc87f53d7618294222a8a4e193ae9f088ac00000000");

	"block.to_string" >:: block_to_string_test 
		(`Hex "00000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a29ab5f49ffff001d1dac2b7c0101000000010000000000000000000000000000000000000000000000000000000000000000ffffffff4d04ffff001d0104455468652054696d65732030332f4a616e2f32303039204368616e63656c6c6f72206f6e206272696e6b206f66207365636f6e64206261696c6f757420666f722062616e6b73ffffffff0100f2052a01000000434104678afdb0fe5548271967f1a67130b7105cd6a828e03909a67962e0ea1f61deb649f6bc3f4cef38c4f35504e51ec112de5c384df7ba0b8d578a4c702b6bf11d5fac00000000")
		"((header((hash c966831d059daa7fa7997f0ce80f4317329def2c3c0e0e953f077f7434f3235e)(version 0)(prev_block fdeda33b00000000000000000000000000000000000000000000000000000000)(merkle_root 495fab294a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7a)(time 486604799)(bits 2083236893)(nonce 257)))(txs())(size 281))";

	"address.of_pub" >:: address_of_pub_test 0x0 (`Hex "0450863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B23522CD470243453A299FA9E77237716103ABC11A1DF38855ED6F2EE187E9C582BA6") "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM";
	"address.of_pubhash" >:: address_of_pubhash_test 0x05 (`Hex "010966776006953D5567439E5E39F86A0D273BEE") "31nVrspaydBz8aMpxH9WkS2DuhgqS1fCuG";
	"address.of_pubhash2" >:: address_of_pubhash_test 0x00 (`Hex "010966776006953D5567439E5E39F86A0D273BEE") "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM";

	"merkle.of_hashes" >:: merkle_of_hashes_test ["ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb"; "3e23e8160039594a33894f6564e1b1348bbd7a0088d42c4acb73eeaed59c009d"] "ba19cdde887c55f040e7ea751357133c23c9235709f58d5888a2059b6930b54e";
	"merkle.of_hashes2" >:: merkle_of_hashes_test [
		"0000000000000000000000000000000000000000000000000000000000000000"; 
		"0000000000000000000000000000000000000000000000000000000000000011"; 
		"0000000000000000000000000000000000000000000000000000000000000022"] 
		"d47780c084bad3830bcdaf6eace035e4c6cbf646d103795d22104fb105014ba3";
	"merkle.of_hashes3" >:: merkle_of_hashes_test (List.rev [
		"e2bab487cccb603c3e8a6ec5d6c9632ad354cd1d987345909ffa909c8f46aa76";
		"b3637ad278c5b8e468b43052c93b8a4529a388e7b62b39dde9317d9f2e480829";
		"9a128057e4f663a6e940ec8f13873d9030bc43ffc6f39427e6ec3311ce95e59d";
		"0b2c0221516033f397d692206b3ba90c08bdd00acf2b0485cf6ceb7833ad1898";
		"f733b575973688215c343a62e98abd81e4df1c1247b69de53de4764ab8b254a8";
		"e5d903d8156e77f66f25bd32805ffac0d013784f10be11f549da1618a8ca034f";
		"e044d1171c172262857b01252d52b4fec68586482e713a61069cdbc7ab82dc4b";
		"d579c8cd4e53234e128a09cad372103d50d7e2b3e670e5c4190f92ff4bcd3a88";
		"c78041f3f44a7b6a63144e90142df6e9ee7070517ccbd8f62be8083f49013770";
		"24ee4a216ce4d5b881e650c96ee2c09088b1c49f9e118eabd7a8ecb600634adc";
		"129f458c607f0347d6830e0ed11dc7321397c33d6563f2a1f93bce42b17fb2ce";
		"fba77fc3a8ddf358a247109af1130958533807899f573aaa388b13c71f81d703"])
		"a29eb4e02d683ad91179ad4f0fc60062199e121c08ff921f9869269ec6f7280f";
	"block.merkle.verify" >:: block_merkle_verify_test (`Hex "0100000040f11b68435988807d64dff20261f7d9827825fbb37542601fb94d45000000000f28f7c69e2669981f92ff081c129e196200c60f4fad7911d93a682de0b49ea2ecd9d24c1844011d00d361050c01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff07041844011d0142ffffffff0100f2052a01000000434104a313febd5f91b6a13bd9c5317030518fee96d1319a0eb10076917294933d09c17dc1588a06953a264738f2acea0c66b99e796caa4f28158e0dd5f6fed69a185bac000000000100000001aa18a952c3f73e5d7440bc570b2aa78f72059887b25b6a1790514b7feedec090000000008b483045022100a970ee6e96fa8bea1cf76d3bda3fb70441a6ec50014d4ea3adcdeae9fbfb5129022025ce9e090366dd6175071a0a5b4a4727571b9bd7bdd5a74d3d3bad7f63eb5dd4014104ac44bdf511477465cb70fef1d06b9241e74d26047ccbdfa641ec9a0115ad35594cbb58a61a6fd56893a405bcffbf6555995ddedc7e6cd4e5ceb83a37e1cf8f98ffffffff02004d92d86a0000001976a914b8083945473bc8289efb681f94de7b07a5b851ad88ac00743ba40b0000001976a914ef01911c9efec6799d1ee5f7c6fb072d9669da8088ac000000000100000001438bd97cb2172e0dd6f341e455e00b7d089747bd4e7f54bd802afe6a6d006c7c000000008a47304402207db94026c96572519101a08e2c864bbe51c987eda6266079a35286df68f123ca02202d7d24c616776a70cce6cb2f97a424e47c30d466e96b750ca03564810249073c014104880286646dab4c894a5ff1bf62bd80047a50b86446b326f2155de94a54d01f9058d4cbc7452563a7c18b2bfb353262fc5adac6307a9446e8c4669daa58e97071ffffffff0200743ba40b0000001976a914fce443c743b456606d1e70ff0d98c4609addc10688ac00ba1dd2050000001976a91411e3e67c08e5d791c97b3d49a8d52025d3f78d3a88ac000000000100000001dc4a6300b6eca8d7ab8e119e9fc4b18890c0e26ec950e681b8d5e46c214aee24010000008b48304502202bcf8632a11192f6b4998343c13589771e6715a080236087dcb1771cbab01809022100edcc38488dd70cd38c058994f143ca5d259071b8fe54c66bf67e55d4468dcacb01410475106e33e14e9cf35bc359dd4120b580ecf5412bb8803f2a927aecd4218d1346e242c7056dca2e4c114fcf2f60799bc5e79107bd1a8b8d5135c92f02bdb59834ffffffff0200f2052a010000001976a9146c9715e09fb00ba84af1ff916ff409b4a5dc9ae288ac00c817a8040000001976a914f7be161206700eb7be1bca5768232c61e4694f4788ac000000000100000001b6cc12ff76247895cb7a604d888012136f06bba64654262044ecb93ff7762c2f000000008b48304502206d795045622c7cdfb4a211c5b41d477920437c21e69214ab4a14f10fe0306b78022100840e55114d6922f3c5e44c7cdcf85dc800d1caef64e7846998423e4ba86714e6014104f88ae9067bc05136cb53a8c18f8549f544ff55ab87ada8f3ba7e2aea773ec73585b61f18ade1c0ddd6c447788578be5fb785c245a64d29b7ff5d28b85cbec58cffffffff0200743ba40b0000001976a914c8081083a8b741da2da260bc0656b88c7bfa6fbf88ac00743ba40b0000001976a914fce443c743b456606d1e70ff0d98c4609addc10688ac0000000001000000019a8d70c7a27560b28dfe778db9ce7f2ff235faf98d5123c07991682be90a4c16000000008b483045022100a118c34f63854ee03d15cca2918d592c295035c42e03be7b0c7e86e66d40ea790220558336d2583a1da00ed5bcad2de5d3b9d485431f702bf2f002267b35ab0b41a0014104f88ae9067bc05136cb53a8c18f8549f544ff55ab87ada8f3ba7e2aea773ec73585b61f18ade1c0ddd6c447788578be5fb785c245a64d29b7ff5d28b85cbec58cffffffff0200743ba40b0000001976a914a440ef00c2e1d39be93607da66568caa26e0501888ac00743ba40b0000001976a914e1d3e65f78f962c4e9dfd04db2119aeefa4e111088ac000000000100000001883acd4bff920f19c4e570e6b3e2d7503d1072d3ca098a124e23534ecdc879d5000000008a473044022040677305de69fd8c18e2c54d5b3c67c5c05735cf6b73d420ccd306762c4bfda2022032cd32ac15ac1820265ffce82654a6008cda22a79fb619ebb65e0af806e14f9b0141044423ef78a2859eb57c4a59dc0878141cf5a4b1fdef71d649d3fb5cf8ea6b1114f4086e5d684a0999d4435db99217a994cc3cf7ad435c8f4e44613d9d160916c4ffffffff0100743ba40b0000001976a914fce443c743b456606d1e70ff0d98c4609addc10688ac000000000100000001ceb27fb142ce3bf9a1f263653dc3971332c71dd10e0e83d647037f608c459f12000000008b4830450220389218287e87d0d7b7113eb20cc1cbf1a00d7acdca32bba7f184cd066db74d6a022100b0998058e5a242699a48f931004cf5550f4e8802b866ce1baf1a0b2616861f27014104255a048d416984101c17514a89289a7d5d3dc8c562850c7a3599f0c7c39bcf9c3a43df75e1e614e51d70c5f85212c99298a21f087be93ecba7ef3900d02c0e8bffffffff0200743ba40b0000001976a914211fd13b614521ed566ddd42738381e42c3c2b2088ac00d956345f0000001976a914d3cc345ba8bdf51d7097955f0f259731f4c34f4388ac000000000100000001703701493f08e82bf6d8cb7c517070eee9f62d14904e14636a7b4af4f34180c7010000008a4730440220061a61eae90ffcf13c10c88a88c085b02954f488823c2f5c81e83a5a833e9f3b02204a61498a9668b2793e77fe3b68585f2daff4dd5daf6097a82615035325ada4730141040db6308d6170333e2c50dee4c9f18f0ab84a7a5c4c88a6836a91f39cb8f4712e08bd72979c542d4b3b60e8dc2021c1b3cc45ffaa83f36a9dec3c4473ea2aa2f3ffffffff0200f2052a010000001976a9143e7e087b9b09149e0266b7a416da2709b4ccf58788ac00d6117e030000001976a914777af71a3b2a48e48f2e467f65028d85c1b5eb5288ac0000000001000000014bdc82abc7db9c06613a712e488685c6feb4522d25017b856222171c17d144e0000000008b4830450221009eb7edcbf8d6be63529264b07bb9f40cf1a0ca779235999e40f5311d70706f1102207f65c5f66982519e6d82e13ca3e61f4f071c73da6c5830b3c4461252012b474e0141045af9665878e6696fd069669951acc54a87c5e3b256a9e20cd8858e0dc5a8c53624e0c979096c00af8a8c60136eef9ffa3d511309417b8315b7f9e3e41e805e8fffffffff0100743ba40b0000001976a914e1d3e65f78f962c4e9dfd04db2119aeefa4e111088ac000000000100000001a854b2b84a76e43de59db647121cdfe481bd8ae9623a345c2188369775b533f7010000008c493046022100c4db6ecf679264c9b525628ec5a983710ff45a1d2d4aa0b54ee218ca9a1ad4df022100dc2e0077cfdd3cbeb28f7463632902ad5306f6d5c77c8149e5b9249bfea8060e014104f9a476b612bb9788c64b9b1e4c9d2deaae1ef0baf6eb593a95d00e2ef8a2beb897ea1fb7c3832e842dd6307fd162816c19c8f458fd8dae331dbc9062fb02e5d8ffffffff0200651b90530000001976a914d5c7c9aec292a807005f013c4d2122f7126e257788ac00743ba40b0000001976a914211fd13b614521ed566ddd42738381e42c3c2b2088ac0000000001000000012908482e9f7d31e9dd392bb6e788a329458a3bc95230b468e4b8c578d27a63b3000000008a4730440220549a7b422fc2020671acabfb937349bd87d985b2e4b9698e4ccacc985f61aee102204dc272322079e9114746db2f8d035d82b64523a69cd7be674173e063090cc8ac014104011a6c220a5549ff112c92c6c38dec93f66ef1f0a21d1409b92f0ccf0fb159aa8173a5b2413a45140fc02b45d63775bae03691d9dc87fd7a10d709a04922900cffffffff0200743ba40b0000001976a914211fd13b614521ed566ddd42738381e42c3c2b2088ac00f1dfeb470000001976a9140adcb4e90cc87f53d7618294222a8a4e193ae9f088ac00000000")
];;

let () = run_test_tt_main suite;;