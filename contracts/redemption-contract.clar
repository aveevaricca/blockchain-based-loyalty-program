;; Redemption Contract
;; Smart contract to redeem loyalty points for products or services
;; Manages reward catalog, redemption transactions, and redemption history

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_OWNER_ONLY (err u200))
(define-constant ERR_REWARD_NOT_FOUND (err u201))
(define-constant ERR_INSUFFICIENT_POINTS (err u202))
(define-constant ERR_REWARD_INACTIVE (err u203))
(define-constant ERR_INVALID_AMOUNT (err u204))
(define-constant ERR_INVALID_PRICE (err u205))
(define-constant ERR_REWARD_EXISTS (err u206))
(define-constant ERR_INVALID_QUANTITY (err u207))
(define-constant ERR_OUT_OF_STOCK (err u208))
(define-constant ERR_REDEMPTION_NOT_FOUND (err u209))
(define-constant ERR_CONTRACT_INACTIVE (err u210))
(define-constant ERR_INVALID_MERCHANT (err u211))
(define-constant ERR_MERCHANT_INACTIVE (err u212))

;; Data Variables
(define-data-var next-reward-id uint u1)
(define-data-var next-redemption-id uint u1)
(define-data-var contract-active bool true)
(define-data-var total-redemptions uint u0)
(define-data-var total-points-redeemed uint u0)
(define-data-var next-merchant-id uint u1)

;; Data Maps
(define-map rewards uint {
  name: (string-ascii 50),
  description: (string-ascii 200),
  points-required: uint,
  quantity-available: uint,
  active: bool,
  merchant-id: uint,
  category: (string-ascii 20)
})

(define-map redemptions uint {
  user: principal,
  reward-id: uint,
  points-spent: uint,
  quantity: uint,
  block-height: uint,
  merchant-id: uint
})

(define-map user-redemption-history principal (list 100 uint))
(define-map reward-redemption-count uint uint)
(define-map merchant-rewards uint (list 50 uint))
(define-map user-points principal uint)

(define-map merchants uint {
  address: principal,
  name: (string-ascii 50),
  active: bool,
  total-rewards: uint
})

;; Private Functions

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT_OWNER))

;; Check if contract is active
(define-private (is-contract-active)
  (var-get contract-active))

;; Get user points balance
(define-private (get-user-points-balance (user principal))
  (default-to u0 (map-get? user-points user)))

;; Update user points balance
(define-private (set-user-points (user principal) (points uint))
  (if (> points u0)
    (map-set user-points user points)
    (map-delete user-points user)))

;; Add redemption to user history
(define-private (add-to-user-history (user principal) (redemption-id uint))
  (let
    ((current-history (default-to (list) (map-get? user-redemption-history user))))
    (if (< (len current-history) u100)
      (map-set user-redemption-history user (unwrap-panic (as-max-len? (append current-history redemption-id) u100)))
      ;; If history is full, remove first element and add new one
      (map-set user-redemption-history user 
        (unwrap-panic (as-max-len? (append (unwrap-panic (slice? current-history u1 u100)) redemption-id) u100))))))

;; Add reward to merchant's reward list
(define-private (add-reward-to-merchant (merchant-id uint) (reward-id uint))
  (let
    ((current-rewards (default-to (list) (map-get? merchant-rewards merchant-id))))
    (if (< (len current-rewards) u50)
      (begin
        (map-set merchant-rewards merchant-id (unwrap-panic (as-max-len? (append current-rewards reward-id) u50)))
        (ok true))
      (err ERR_INVALID_QUANTITY))))

;; Public Functions

;; Get contract status
(define-read-only (is-active)
  (ok (var-get contract-active)))

;; Get total redemptions count
(define-read-only (get-total-redemptions)
  (ok (var-get total-redemptions)))

;; Get total points redeemed
(define-read-only (get-total-points-redeemed)
  (ok (var-get total-points-redeemed)))

;; Register merchant
(define-public (register-merchant (merchant-address principal) (merchant-name (string-ascii 50)))
  (begin
    ;; Check if caller is owner
    (asserts! (is-contract-owner) ERR_OWNER_ONLY)
    
    (let
      ((merchant-id (var-get next-merchant-id)))
      
      ;; Add merchant
      (map-set merchants merchant-id {
        address: merchant-address,
        name: merchant-name,
        active: true,
        total-rewards: u0
      })
      
      ;; Increment merchant ID
      (var-set next-merchant-id (+ merchant-id u1))
      
      (ok merchant-id))))

;; Get merchant details
(define-read-only (get-merchant (merchant-id uint))
  (map-get? merchants merchant-id))

;; Add points to user account - simulating earning points
(define-public (add-user-points (user principal) (points uint))
  (begin
    ;; Check if contract is active
    (asserts! (is-contract-active) ERR_CONTRACT_INACTIVE)
    ;; Check if caller is owner (or could be merchant in extended version)
    (asserts! (is-contract-owner) ERR_OWNER_ONLY)
    ;; Check if points amount is valid
    (asserts! (> points u0) ERR_INVALID_AMOUNT)
    
    (let
      ((current-points (get-user-points-balance user))
       (new-points (+ current-points points)))
      
      ;; Update user points
      (set-user-points user new-points)
      
      (ok new-points))))

;; Get user points balance
(define-read-only (get-user-points (user principal))
  (ok (get-user-points-balance user)))

;; Add a new reward to the catalog
(define-public (add-reward 
  (name (string-ascii 50))
  (description (string-ascii 200))
  (points-required uint)
  (quantity-available uint)
  (merchant-id uint)
  (category (string-ascii 20)))
  (begin
    ;; Check if contract is active
    (asserts! (is-contract-active) ERR_CONTRACT_INACTIVE)
    ;; Check if points required is valid
    (asserts! (> points-required u0) ERR_INVALID_PRICE)
    ;; Check if quantity is valid
    (asserts! (> quantity-available u0) ERR_INVALID_QUANTITY)
    
    ;; Check if merchant exists and caller is merchant or owner
    (match (map-get? merchants merchant-id)
      merchant-data
      (begin
        ;; Check if merchant is active
        (asserts! (get active merchant-data) ERR_MERCHANT_INACTIVE)
        ;; Check if caller is merchant or owner
        (asserts! (or (is-contract-owner) (is-eq tx-sender (get address merchant-data))) ERR_INVALID_MERCHANT)
        
        (let
          ((reward-id (var-get next-reward-id)))
          
          ;; Add reward to catalog
          (map-set rewards reward-id {
            name: name,
            description: description,
            points-required: points-required,
            quantity-available: quantity-available,
            active: true,
            merchant-id: merchant-id,
            category: category
          })
          
          ;; Add reward to merchant's list
          (unwrap-panic (add-reward-to-merchant merchant-id reward-id))
          
          ;; Update merchant's total rewards count
          (map-set merchants merchant-id 
            (merge merchant-data {total-rewards: (+ (get total-rewards merchant-data) u1)}))
          
          ;; Increment reward ID
          (var-set next-reward-id (+ reward-id u1))
          
          (ok reward-id)))
      ERR_INVALID_MERCHANT)))

;; Get reward details
(define-read-only (get-reward-details (reward-id uint))
  (map-get? rewards reward-id))

;; Get merchant's rewards
(define-read-only (get-merchant-rewards (merchant-id uint))
  (default-to (list) (map-get? merchant-rewards merchant-id)))

;; Update reward availability
(define-public (update-reward-quantity (reward-id uint) (new-quantity uint))
  (begin
    ;; Check if contract is active
    (asserts! (is-contract-active) ERR_CONTRACT_INACTIVE)
    
    (match (map-get? rewards reward-id)
      reward-data
      (begin
        ;; Check if caller is merchant or owner
        (match (map-get? merchants (get merchant-id reward-data))
          merchant-data
          (begin
            (asserts! (or (is-contract-owner) (is-eq tx-sender (get address merchant-data))) ERR_INVALID_MERCHANT)
            
            ;; Update quantity
            (map-set rewards reward-id (merge reward-data {quantity-available: new-quantity}))
            
            (ok new-quantity))
          ERR_INVALID_MERCHANT))
      ERR_REWARD_NOT_FOUND)))

;; Redeem points for a reward
(define-public (redeem-points (reward-id uint) (quantity uint))
  (begin
    ;; Check if contract is active
    (asserts! (is-contract-active) ERR_CONTRACT_INACTIVE)
    ;; Check if quantity is valid
    (asserts! (> quantity u0) ERR_INVALID_QUANTITY)
    
    (match (map-get? rewards reward-id)
      reward-data
      (begin
        ;; Check if reward is active
        (asserts! (get active reward-data) ERR_REWARD_INACTIVE)
        ;; Check if sufficient quantity available
        (asserts! (>= (get quantity-available reward-data) quantity) ERR_OUT_OF_STOCK)
        
        (let
          ((total-points-needed (* (get points-required reward-data) quantity))
           (current-user-points (get-user-points-balance tx-sender))
           (redemption-id (var-get next-redemption-id))
           (new-quantity (- (get quantity-available reward-data) quantity))
           (new-user-points (- current-user-points total-points-needed)))
          
          ;; Check if user has sufficient points
          (asserts! (>= current-user-points total-points-needed) ERR_INSUFFICIENT_POINTS)
          
          ;; Update user points
          (set-user-points tx-sender new-user-points)
          
          ;; Update reward quantity
          (map-set rewards reward-id (merge reward-data {quantity-available: new-quantity}))
          
          ;; Record redemption
          (map-set redemptions redemption-id {
            user: tx-sender,
            reward-id: reward-id,
            points-spent: total-points-needed,
            quantity: quantity,
            block-height: stacks-block-height,
            merchant-id: (get merchant-id reward-data)
          })
          
          ;; Add to user history
          (add-to-user-history tx-sender redemption-id)
          
          ;; Update redemption count for reward
          (map-set reward-redemption-count reward-id 
            (+ (default-to u0 (map-get? reward-redemption-count reward-id)) quantity))
          
          ;; Update global counters
          (var-set next-redemption-id (+ redemption-id u1))
          (var-set total-redemptions (+ (var-get total-redemptions) u1))
          (var-set total-points-redeemed (+ (var-get total-points-redeemed) total-points-needed))
          
          (print {redemption: {user: tx-sender, reward-id: reward-id, quantity: quantity, points-spent: total-points-needed}})
          
          (ok redemption-id)))
      ERR_REWARD_NOT_FOUND)))

;; Get redemption details
(define-read-only (get-redemption-details (redemption-id uint))
  (map-get? redemptions redemption-id))

;; Get user's redemption history
(define-read-only (get-user-redemption-history (user principal))
  (default-to (list) (map-get? user-redemption-history user)))

;; Get reward redemption statistics
(define-read-only (get-reward-redemption-count (reward-id uint))
  (default-to u0 (map-get? reward-redemption-count reward-id)))

;; Deactivate/reactivate reward
(define-public (set-reward-status (reward-id uint) (active bool))
  (begin
    ;; Check if contract is active
    (asserts! (is-contract-active) ERR_CONTRACT_INACTIVE)
    
    (match (map-get? rewards reward-id)
      reward-data
      (begin
        ;; Check if caller is merchant or owner
        (match (map-get? merchants (get merchant-id reward-data))
          merchant-data
          (begin
            (asserts! (or (is-contract-owner) (is-eq tx-sender (get address merchant-data))) ERR_INVALID_MERCHANT)
            
            ;; Update reward status
            (map-set rewards reward-id (merge reward-data {active: active}))
            
            (ok active))
          ERR_INVALID_MERCHANT))
      ERR_REWARD_NOT_FOUND)))

;; Deactivate/reactivate merchant
(define-public (set-merchant-status (merchant-id uint) (active bool))
  (begin
    ;; Check if caller is owner
    (asserts! (is-contract-owner) ERR_OWNER_ONLY)
    
    (match (map-get? merchants merchant-id)
      merchant-data
      (begin
        ;; Update merchant status
        (map-set merchants merchant-id (merge merchant-data {active: active}))
        (ok active))
      ERR_INVALID_MERCHANT)))

;; Emergency functions - only contract owner

;; Pause/unpause contract
(define-public (set-contract-status (active bool))
  (begin
    ;; Check if caller is owner
    (asserts! (is-contract-owner) ERR_OWNER_ONLY)
    (var-set contract-active active)
    (ok active)))

;; Emergency refund - only contract owner
(define-public (emergency-refund (user principal) (points uint))
  (begin
    ;; Check if caller is owner
    (asserts! (is-contract-owner) ERR_OWNER_ONLY)
    ;; Check if points amount is valid
    (asserts! (> points u0) ERR_INVALID_AMOUNT)
    
    (let
      ((current-points (get-user-points-balance user))
       (new-points (+ current-points points)))
      
      ;; Add points to user
      (set-user-points user new-points)
      
      (ok new-points))))

