;; Loyalty Token Contract
;; Smart contract to issue and manage loyalty tokens for a blockchain-based loyalty program
;; Provides token minting, burning, transfers, and merchant management functionality

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_OWNER_ONLY (err u100))
(define-constant ERR_NOT_TOKEN_OWNER (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_INVALID_AMOUNT (err u103))
(define-constant ERR_MERCHANT_NOT_FOUND (err u104))
(define-constant ERR_MERCHANT_ALREADY_EXISTS (err u105))
(define-constant ERR_INVALID_RECIPIENT (err u106))
(define-constant ERR_SELF_TRANSFER (err u107))
(define-constant ERR_TOKEN_NOT_ACTIVE (err u108))

;; Data Variables
(define-data-var token-name (string-ascii 32) "LoyaltyToken")
(define-data-var token-symbol (string-ascii 10) "LOYAL")
(define-data-var token-decimals uint u0)
(define-data-var total-supply uint u0)
(define-data-var contract-active bool true)
(define-data-var next-merchant-id uint u1)

;; Data Maps
(define-map token-balances principal uint)
(define-map token-allowances {owner: principal, spender: principal} uint)
(define-map merchants uint {address: principal, name: (string-ascii 50), active: bool})
(define-map merchant-allocations {merchant-id: uint, user: principal} uint)
(define-map transfer-history uint {from: principal, to: principal, amount: uint, block-height: uint})
(define-data-var next-transfer-id uint u0)

;; Private Functions

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT_OWNER))

;; Check if contract is active
(define-private (is-contract-active)
  (var-get contract-active))

;; Get balance with default of 0
(define-private (get-balance-or-default (account principal))
  (default-to u0 (map-get? token-balances account)))

;; Update balance in map
(define-private (set-balance (account principal) (balance uint))
  (if (> balance u0)
    (map-set token-balances account balance)
    (map-delete token-balances account)))

;; Record transfer in history
(define-private (record-transfer (from principal) (to principal) (amount uint))
  (let
    ((transfer-id (var-get next-transfer-id)))
    (map-set transfer-history transfer-id 
      {from: from, to: to, amount: amount, block-height: stacks-block-height})
    (var-set next-transfer-id (+ transfer-id u1))
    (ok transfer-id)))

;; Public Functions

;; Get token information
(define-read-only (get-name)
  (ok (var-get token-name)))

(define-read-only (get-symbol)
  (ok (var-get token-symbol)))

(define-read-only (get-decimals)
  (ok (var-get token-decimals)))

(define-read-only (get-total-supply)
  (ok (var-get total-supply)))

;; Get balance of an account
(define-read-only (get-balance (account principal))
  (ok (get-balance-or-default account)))

;; Get contract status
(define-read-only (is-active)
  (ok (var-get contract-active)))

;; Mint tokens - only contract owner can mint
(define-public (mint-tokens (amount uint) (recipient principal))
  (begin
    ;; Check if contract is active
    (asserts! (is-contract-active) ERR_TOKEN_NOT_ACTIVE)
    ;; Check if caller is owner
    (asserts! (is-contract-owner) ERR_OWNER_ONLY)
    ;; Check if amount is valid
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    ;; Check if recipient is valid
    (asserts! (not (is-eq recipient CONTRACT_OWNER)) ERR_INVALID_RECIPIENT)
    
    (let
      ((current-balance (get-balance-or-default recipient))
       (new-balance (+ current-balance amount))
       (new-total-supply (+ (var-get total-supply) amount)))
      
      ;; Update recipient balance
      (set-balance recipient new-balance)
      ;; Update total supply
      (var-set total-supply new-total-supply)
      ;; Record the mint as a transfer from contract
      (unwrap-panic (record-transfer CONTRACT_OWNER recipient amount))
      
      (ok new-balance))))

;; Burn tokens - account holder can burn their own tokens
(define-public (burn-tokens (amount uint))
  (begin
    ;; Check if contract is active
    (asserts! (is-contract-active) ERR_TOKEN_NOT_ACTIVE)
    ;; Check if amount is valid
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    (let
      ((current-balance (get-balance-or-default tx-sender))
       (new-balance (- current-balance amount))
       (new-total-supply (- (var-get total-supply) amount)))
      
      ;; Check if sender has sufficient balance
      (asserts! (>= current-balance amount) ERR_INSUFFICIENT_BALANCE)
      
      ;; Update sender balance
      (set-balance tx-sender new-balance)
      ;; Update total supply
      (var-set total-supply new-total-supply)
      ;; Record the burn as a transfer to contract
      (unwrap-panic (record-transfer tx-sender CONTRACT_OWNER amount))
      
      (ok new-balance))))

;; Transfer tokens between accounts
(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    ;; Check if contract is active
    (asserts! (is-contract-active) ERR_TOKEN_NOT_ACTIVE)
    ;; Check if caller is the sender
    (asserts! (is-eq tx-sender sender) ERR_NOT_TOKEN_OWNER)
    ;; Check if amount is valid
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    ;; Check if not self transfer
    (asserts! (not (is-eq sender recipient)) ERR_SELF_TRANSFER)
    
    (let
      ((sender-balance (get-balance-or-default sender))
       (recipient-balance (get-balance-or-default recipient))
       (new-sender-balance (- sender-balance amount))
       (new-recipient-balance (+ recipient-balance amount)))
      
      ;; Check if sender has sufficient balance
      (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)
      
      ;; Update balances
      (set-balance sender new-sender-balance)
      (set-balance recipient new-recipient-balance)
      ;; Record transfer
      (unwrap-panic (record-transfer sender recipient amount))
      
      (print {transfer: {sender: sender, recipient: recipient, amount: amount, memo: memo}})
      (ok true))))

;; Register a new merchant - only contract owner
(define-public (register-merchant (merchant-address principal) (merchant-name (string-ascii 50)))
  (begin
    ;; Check if caller is owner
    (asserts! (is-contract-owner) ERR_OWNER_ONLY)
    
    (let
      ((merchant-id (var-get next-merchant-id)))
      
      ;; Add merchant to map
      (map-set merchants merchant-id {address: merchant-address, name: merchant-name, active: true})
      ;; Increment merchant ID counter
      (var-set next-merchant-id (+ merchant-id u1))
      
      (ok merchant-id))))

;; Get merchant details
(define-read-only (get-merchant (merchant-id uint))
  (map-get? merchants merchant-id))

;; Allocate tokens to user from merchant - only merchant can allocate
(define-public (allocate-tokens (merchant-id uint) (user principal) (amount uint))
  (begin
    ;; Check if contract is active
    (asserts! (is-contract-active) ERR_TOKEN_NOT_ACTIVE)
    ;; Check if amount is valid
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    (match (map-get? merchants merchant-id)
      merchant-data
      (begin
        ;; Check if caller is the merchant
        (asserts! (is-eq tx-sender (get address merchant-data)) ERR_NOT_TOKEN_OWNER)
        ;; Check if merchant is active
        (asserts! (get active merchant-data) ERR_MERCHANT_NOT_FOUND)
        
        (let
          ((current-allocation (default-to u0 (map-get? merchant-allocations {merchant-id: merchant-id, user: user})))
           (new-allocation (+ current-allocation amount))
           (current-user-balance (get-balance-or-default user))
           (new-user-balance (+ current-user-balance amount))
           (new-total-supply (+ (var-get total-supply) amount)))
          
          ;; Update allocation
          (map-set merchant-allocations {merchant-id: merchant-id, user: user} new-allocation)
          ;; Update user balance
          (set-balance user new-user-balance)
          ;; Update total supply
          (var-set total-supply new-total-supply)
          ;; Record allocation as transfer from merchant
          (unwrap-panic (record-transfer tx-sender user amount))
          
          (ok new-allocation)))
      ERR_MERCHANT_NOT_FOUND)))

;; Get allocation for a specific merchant-user pair
(define-read-only (get-merchant-allocation (merchant-id uint) (user principal))
  (default-to u0 (map-get? merchant-allocations {merchant-id: merchant-id, user: user})))

;; Get transfer history entry
(define-read-only (get-transfer (transfer-id uint))
  (map-get? transfer-history transfer-id))

;; Deactivate merchant - only contract owner
(define-public (deactivate-merchant (merchant-id uint))
  (begin
    ;; Check if caller is owner
    (asserts! (is-contract-owner) ERR_OWNER_ONLY)
    
    (match (map-get? merchants merchant-id)
      merchant-data
      (begin
        (map-set merchants merchant-id 
          (merge merchant-data {active: false}))
        (ok true))
      ERR_MERCHANT_NOT_FOUND)))

;; Emergency functions - only contract owner

;; Pause/unpause contract
(define-public (set-contract-status (active bool))
  (begin
    ;; Check if caller is owner
    (asserts! (is-contract-owner) ERR_OWNER_ONLY)
    (var-set contract-active active)
    (ok active)))

;; Update token metadata - only contract owner
(define-public (set-token-metadata (name (string-ascii 32)) (symbol (string-ascii 10)))
  (begin
    ;; Check if caller is owner
    (asserts! (is-contract-owner) ERR_OWNER_ONLY)
    (var-set token-name name)
    (var-set token-symbol symbol)
    (ok true)))

;; title: loyalty-token
;; version:
;; summary:
;; description:

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

