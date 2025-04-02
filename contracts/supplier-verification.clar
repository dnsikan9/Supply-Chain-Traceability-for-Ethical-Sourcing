;; Supplier Verification Contract
;; Validates compliance with ethical standards

(define-data-var admin principal tx-sender)

;; Supplier data structure
(define-map suppliers
  { supplier-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    verified: bool,
    ethical-score: uint,
    verification-date: uint,
    verifier: principal
  }
)

;; Verification events
(define-map verification-history
  { supplier-id: (string-ascii 64), timestamp: uint }
  {
    verifier: principal,
    ethical-score: uint,
    notes: (string-ascii 256)
  }
)

;; Register a new supplier
(define-public (register-supplier (supplier-id (string-ascii 64)) (name (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? suppliers { supplier-id: supplier-id })) (err u100))

    (map-set suppliers
      { supplier-id: supplier-id }
      {
        name: name,
        verified: false,
        ethical-score: u0,
        verification-date: u0,
        verifier: tx-sender
      }
    )
    (ok true)
  )
)

;; Verify a supplier
(define-public (verify-supplier
    (supplier-id (string-ascii 64))
    (ethical-score uint)
    (notes (string-ascii 256)))
  (let ((supplier (unwrap! (map-get? suppliers { supplier-id: supplier-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    ;; Update supplier verification status
    (map-set suppliers
      { supplier-id: supplier-id }
      (merge supplier {
        verified: true,
        ethical-score: ethical-score,
        verification-date: block-height,
        verifier: tx-sender
      })
    )

    ;; Record verification history
    (map-set verification-history
      { supplier-id: supplier-id, timestamp: block-height }
      {
        verifier: tx-sender,
        ethical-score: ethical-score,
        notes: notes
      }
    )

    (ok true)
  )
)

;; Get supplier details
(define-read-only (get-supplier (supplier-id (string-ascii 64)))
  (map-get? suppliers { supplier-id: supplier-id })
)

;; Check if supplier is verified
(define-read-only (is-supplier-verified (supplier-id (string-ascii 64)))
  (default-to false (get verified (map-get? suppliers { supplier-id: supplier-id })))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)

