open Conv_helper;;

type prefix = {
  pubkeyhash: int;
  scripthash: int;
  hrp: string;
};;

type t = string;;

module Bech32 = struct
  let charset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l";;

  let polymod values =
    let generators = [ 0x3b6a57b2; 0x26508e6d; 0x1ea119fa; 0x3d4233dd; 0x2a1462b3 ] in
    let rec pm vl chk = match vl with 
    | [] -> chk
    | v :: vl' -> 
      let top = chk lsl 25 in
      let chk' = (chk land 0x1ffffff) lsr 5 lxor v in
      let rec genapply gl chk i = match gl with
      | [] -> chk
      | g::gl' -> genapply gl' (chk lxor (if ((top lsr i) land 1) = 1 then g else 0)) (i+1)
      in pm vl' @@ genapply generators chk' 0
    in pm values 1
  ;;

  let hrp_expand hrp =
    let hrl = Conv_helper.b2l hrp in
    (List.map (fun x -> x lsr 5) hrl) @ [0] @ (List.map (fun x -> x land 31) hrl)
  ;;

  let verify_checksum hrp data = polymod ((hrp_expand hrp) @ data) = 1;;

  let create_checksum hrp data = 
    let pm = polymod ((hrp_expand hrp) @ data @ [0; 0; 0; 0; 0; 0]) lxor 1 in
    let rec pmp i pm = match pm with
    | 6 -> pm
    | i -> pmp (i+1) ((pm lsr 5 * (5 - i)) land 31)
    in pmp 0 pm
  ;;

  let b32_encode hrp data = 
    let comb = data @ [create_checksum hrp data] in
    let st = (List.fold_left (fun acc x -> String.make 1 (charset.[x]) ^ acc) "" comb) in
    hrp ^ "1" ^ st
  ;;

  let convertbits prog fromb tob =
    []
  ;;

  let encode hrp witver witprog = 
    b32_encode hrp @@ [witver] @ convertbits witprog 8 5
  ;;
end

let of_pubhash prefix pkh =
  let epkh = (Bytes.make 1 @@ Char.chr prefix) ^ pkh in
  let shrip = Bytes.sub (Hash.dsha256 epkh) 0 4 in
  (epkh ^ shrip) |> Base58.encode_check
;;


let of_pub prefix pk =
	pk |> Hash.sha256 |> Hash.ripemd160 |> of_pubhash prefix
;;


let of_witness hrp witver witprog = 
  Bech32.encode hrp witver witprog
;;