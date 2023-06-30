
;; title: nft-from-btc
;; version: 1.0.0
;; summary: mint stacks nft when a btc address recieves funds 
;; description: mint a SIP-009 NFT on Stacks when a specified Bitcoin address receives funds.

;; traits
;;

;; token definitions
;; 

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

(define-constant SATS-PER-STX u1000)
(define-constant err-not-found (err u404))
(define-constant err-unsupported-tx (err u500))
(define-constant err-out-not-found (err u501))
(define-constant err-in-not-found (err u502))


;; ;; TODO get price from miners
;; (define-read-only (sats-to-stx (sats uint))
;;     (/ sats SATS-PER-STX))

;; for compressed public keys
(define-read-only (p2pkh-to-principal (scriptSig (buff 256)))
  (let ((pk (unwrap! (as-max-len? (unwrap! (slice? scriptSig (- (len scriptSig) u33) (len scriptSig)) none) u33) none)))
    (some (unwrap! (principal-of? pk) none))))

(define-public (mint-to-first-input (height uint) (tx (buff 1024))
                        (header { version: (buff 4), parent: (buff 32), merkle-root: (buff 32), timestamp: (buff 4), nbits: (buff 4), nonce: (buff 4) })
                        (proof { tx-index: uint, hashes: (list 14 (buff 32)), tree-depth: uint}))
    (let (
        ;; extract parts of Bitcoin transaction
          (tx-obj (try! (contract-call? .clarity-bitcoin parse-tx tx)))
          (was-mined (try! (contract-call? .clarity-bitcoin was-tx-mined height tx header proof)))
          (first-output (unwrap! (element-at (get outs tx-obj) u0) err-out-not-found))
          (first-input (unwrap! (element-at (get ins tx-obj) u0) err-in-not-found)))
        ;; TODO check whether the tx-sender is the same as the first output

        ;; transfer stx to first-input
        (if was-mined
            ;; (stx-transfer? (sats-to-stx (get value first-output)) tx-sender (unwrap! (p2pkh-to-principal (get scriptSig first-input)) err-unsupported-tx))
            (nft-mint? btc-nft token-id (unwrap! (p2pkh-to-principal (get scriptSig first-input)) err-unsupported-tx)) 
            err-not-found)))