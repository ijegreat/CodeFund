;; CodeFund Savings Contract
;; A decentralized platform for pooled contributions and scheduled withdrawals

(define-constant CONTRACT-ADMIN tx-sender)
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-INSUFFICIENT-BALANCE (err u2))
(define-constant ERR-MEMBER-EXISTS (err u3))
(define-constant ERR-MEMBER-NOT-FOUND (err u4))
(define-constant ERR-CYCLE-INCOMPLETE (err u5))
(define-constant ERR-WITHDRAWAL-INVALID (err u6))
(define-constant ERR-INVALID-PARTICIPANT-LIMIT (err u7))
(define-constant ERR-INVALID-CONTRIBUTION-AMOUNT (err u8))

;; Storage for pool parameters and state
(define-data-var max-participants uint u0)
(define-data-var contribution-amount uint u0)
(define-data-var current-round uint u0)
(define-data-var total-funds uint u0)
(define-data-var participant-count uint u0)

;; Map to track members
(define-map participants 
  principal 
  {
    is-active: bool,
    total-contributed: uint,
    last-round-contributed: uint
  }
)

;; Map to track cycle details
(define-map round-distributions 
  uint  ;; round number
  {
    beneficiary: principal,
    is-distributed: bool
  }
)

;; Initialize the savings pool
(define-public (initialize-pool (participant-limit uint) (required-amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-ADMIN) ERR-UNAUTHORIZED)
    ;; Validate participant limit (ensure it's at least 2 and not too large)
    (asserts! (and (>= participant-limit u2) (<= participant-limit u100)) ERR-INVALID-PARTICIPANT-LIMIT)
    ;; Validate contribution amount (ensure it's not zero and not too large)
    (asserts! (and (> required-amount u0) (<= required-amount u1000000000)) ERR-INVALID-CONTRIBUTION-AMOUNT)
    
    (var-set max-participants participant-limit)
    (var-set contribution-amount required-amount)
    (var-set participant-count u0)
    (ok true)
  )
)

;; Join the savings pool
(define-public (join-pool)
  (let 
    ((participant-data 
      (default-to 
        {is-active: false, total-contributed: u0, last-round-contributed: u0}
        (map-get? participants tx-sender)
      ))
     (current-count (var-get participant-count)))
    
    ;; Check if already a member
    (asserts! (not (get is-active participant-data)) ERR-MEMBER-EXISTS)
    ;; Check if pool is full
    (asserts! (< current-count (var-get max-participants)) ERR-INVALID-PARTICIPANT-LIMIT)
    
    ;; Add member to the pool
    (map-set participants tx-sender 
      {
        is-active: true, 
        total-contributed: u0, 
        last-round-contributed: u0
      }
    )
    
    ;; Increment participant count
    (var-set participant-count (+ current-count u1))
    (ok true)
  )
)

;; Contribute to the pool
(define-public (contribute)
  (let 
    ((current-round-num (var-get current-round))
     (required-contribution (var-get contribution-amount))
     (participant-data 
      (unwrap! 
        (map-get? participants tx-sender) 
        ERR-MEMBER-NOT-FOUND
      )))
    
    ;; Verify member is active and hasn't already contributed this round
    (asserts! (get is-active participant-data) ERR-MEMBER-NOT-FOUND)
    (asserts! 
      (not (is-eq (get last-round-contributed participant-data) current-round-num)) 
      ERR-MEMBER-EXISTS
    )
    
    ;; Transfer contribution
    (try! (stx-transfer? required-contribution tx-sender (as-contract tx-sender)))
    
    ;; Update member and pool state
    (map-set participants tx-sender 
      {
        is-active: true,
        total-contributed: (+ (get total-contributed participant-data) required-contribution),
        last-round-contributed: current-round-num
      }
    )
    
    ;; Update total pool balance
    (var-set total-funds 
      (+ (var-get total-funds) required-contribution)
    )
    
    (ok true)
  )
)

;; Select next withdrawal recipient (simplified randomness)
(define-public (select-distribution-recipient)
  (let 
    ((current-round-num (var-get current-round))
     (total-participants (var-get participant-count)))
    
    (asserts! (is-eq tx-sender CONTRACT-ADMIN) ERR-UNAUTHORIZED)
    
    ;; In a real-world scenario, use a more robust randomness mechanism
    (map-set round-distributions current-round-num 
      {
        beneficiary: CONTRACT-ADMIN,  ;; Placeholder - replace with actual selection logic
        is-distributed: false
      }
    )
    
    ;; Increment round
    (var-set current-round (+ current-round-num u1))
    
    (ok true)
  )
)

;; Withdraw pool funds
(define-public (withdraw)
  (let 
    ((current-round-num (var-get current-round))
     (distribution-data 
      (unwrap! 
        (map-get? round-distributions (- current-round-num u1)) 
        ERR-CYCLE-INCOMPLETE
      ))
     (current-balance (var-get total-funds)))
    
    ;; Verify withdrawal eligibility
    (asserts! 
      (is-eq (get beneficiary distribution-data) tx-sender) 
      ERR-WITHDRAWAL-INVALID
    )
    (asserts! (not (get is-distributed distribution-data)) ERR-WITHDRAWAL-INVALID)
    
    ;; Transfer pool funds
    (try! (as-contract (stx-transfer? current-balance (as-contract tx-sender) tx-sender)))
    
    ;; Update distribution status
    (map-set round-distributions (- current-round-num u1)
      {
        beneficiary: tx-sender,
        is-distributed: true
      }
    )
    
    ;; Reset pool balance
    (var-set total-funds u0)
    
    (ok true)
  )
)

;; Read-only function to check participant details
(define-read-only (get-participant-info (participant principal))
  (map-get? participants participant)
)

;; Read-only function to get current pool status
(define-read-only (get-pool-status)
  {
    current-round: (var-get current-round),
    total-balance: (var-get total-funds),
    participant-limit: (var-get max-participants),
    required-amount: (var-get contribution-amount),
    current-participants: (var-get participant-count)
  }
)