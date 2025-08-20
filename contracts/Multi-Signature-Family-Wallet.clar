(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_TRANSACTION_NOT_FOUND (err u103))
(define-constant ERR_ALREADY_VOTED (err u104))
(define-constant ERR_TRANSACTION_EXECUTED (err u105))
(define-constant ERR_INVALID_THRESHOLD (err u106))
(define-constant ERR_MEMBER_EXISTS (err u107))
(define-constant ERR_MEMBER_NOT_FOUND (err u108))

(define-data-var next-tx-id uint u1)
(define-data-var spending-threshold uint u1000000)

(define-map family-members principal bool)
(define-map member-roles principal (string-ascii 10))
(define-map transactions
  uint
  {
    recipient: principal,
    amount: uint,
    executed: bool,
    votes: uint,
    proposer: principal,
    block-height: uint
  }
)
(define-map transaction-votes {tx-id: uint, voter: principal} bool)

(define-read-only (get-balance)
  (stx-get-balance (as-contract tx-sender))
)

(define-read-only (get-threshold)
  (var-get spending-threshold)
)

(define-read-only (is-family-member (member principal))
  (default-to false (map-get? family-members member))
)

(define-read-only (get-member-role (member principal))
  (map-get? member-roles member)
)

(define-read-only (get-transaction (tx-id uint))
  (map-get? transactions tx-id)
)

(define-read-only (has-voted (tx-id uint) (voter principal))
  (default-to false (map-get? transaction-votes {tx-id: tx-id, voter: voter}))
)

(define-read-only (get-required-votes)
  u2
)

(define-private (is-parent (member principal))
  (match (get-member-role member)
    role (is-eq role "parent")
    false
  )
)

(define-public (initialize (initial-members (list 10 principal)) (roles (list 10 (string-ascii 10))))
  (begin
    (asserts! (is-eq tx-sender (as-contract tx-sender)) ERR_NOT_AUTHORIZED)
    (map add-initial-member initial-members roles)
    (ok true)
  )
)

(define-private (add-initial-member (member principal) (role (string-ascii 10)))
  (begin
    (map-set family-members member true)
    (map-set member-roles member role)
  )
)

(define-public (add-family-member (new-member principal) (role (string-ascii 10)))
  (begin
    (asserts! (is-parent tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (not (is-family-member new-member)) ERR_MEMBER_EXISTS)
    (map-set family-members new-member true)
    (map-set member-roles new-member role)
    (ok true)
  )
)

(define-public (remove-family-member (member principal))
  (begin
    (asserts! (is-parent tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (is-family-member member) ERR_MEMBER_NOT_FOUND)
    (asserts! (not (is-eq tx-sender member)) ERR_NOT_AUTHORIZED)
    (map-delete family-members member)
    (map-delete member-roles member)
    (ok true)
  )
)

(define-public (set-spending-threshold (new-threshold uint))
  (begin
    (asserts! (is-parent tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (> new-threshold u0) ERR_INVALID_THRESHOLD)
    (var-set spending-threshold new-threshold)
    (ok true)
  )
)

(define-public (deposit)
  (begin
    (asserts! (is-family-member tx-sender) ERR_NOT_AUTHORIZED)
    (stx-transfer? (stx-get-balance tx-sender) tx-sender (as-contract tx-sender))
  )
)

(define-public (propose-transaction (recipient principal) (amount uint))
  (let ((tx-id (var-get next-tx-id)))
    (begin
      (asserts! (is-family-member tx-sender) ERR_NOT_AUTHORIZED)
      (asserts! (> amount u0) ERR_INVALID_AMOUNT)
      (asserts! (<= amount (get-balance)) ERR_INSUFFICIENT_BALANCE)
      (map-set transactions tx-id {
        recipient: recipient,
        amount: amount,
        executed: false,
        votes: u0,
        proposer: tx-sender,
        block-height: stacks-block-height
      })
      (var-set next-tx-id (+ tx-id u1))
      (if (< amount (var-get spending-threshold))
          (begin (try! (execute-transaction tx-id)) (ok tx-id))
          (ok tx-id))
    )
  )
)

(define-public (vote-transaction (tx-id uint))
  (let ((tx-data (unwrap! (get-transaction tx-id) ERR_TRANSACTION_NOT_FOUND))
        (voter-key {tx-id: tx-id, voter: tx-sender}))
    (begin
      (asserts! (is-family-member tx-sender) ERR_NOT_AUTHORIZED)
      (asserts! (not (get executed tx-data)) ERR_TRANSACTION_EXECUTED)
      (asserts! (not (has-voted tx-id tx-sender)) ERR_ALREADY_VOTED)
      (map-set transaction-votes voter-key true)
      (map-set transactions tx-id (merge tx-data {votes: (+ (get votes tx-data) u1)}))
      (if (>= (+ (get votes tx-data) u1) (get-required-votes))
          (execute-transaction tx-id)
          (ok true))
    )
  )
)

(define-private (execute-transaction (tx-id uint))
  (let ((tx-data (unwrap! (get-transaction tx-id) ERR_TRANSACTION_NOT_FOUND)))
    (begin
      (asserts! (not (get executed tx-data)) ERR_TRANSACTION_EXECUTED)
      (map-set transactions tx-id (merge tx-data {executed: true}))
      (as-contract (stx-transfer? (get amount tx-data) tx-sender (get recipient tx-data)))
    )
  )
)

(define-public (emergency-withdraw (recipient principal) (amount uint))
  (begin
    (asserts! (is-parent tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (<= amount (get-balance)) ERR_INSUFFICIENT_BALANCE)
    (let ((emergency-threshold (/ (get-balance) u10)))
      (asserts! (<= amount emergency-threshold) ERR_INVALID_AMOUNT)
      (as-contract (stx-transfer? amount tx-sender recipient))
    )
  )
)

(define-public (get-transaction-status (tx-id uint))
  (match (get-transaction tx-id)
    tx-data (ok {
      executed: (get executed tx-data),
      votes: (get votes tx-data),
      required: (get-required-votes),
      amount: (get amount tx-data),
      recipient: (get recipient tx-data)
    })
    ERR_TRANSACTION_NOT_FOUND
  )
)
