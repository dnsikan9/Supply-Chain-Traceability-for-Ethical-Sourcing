;; Consumer Verification Contract
;; Allows end users to confirm ethical claims

(define-data-var admin principal tx-sender)

;; Product data structure
(define-map products
  { product-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    materials: (list 10 (string-ascii 64)),
    facility-id: (string-ascii 64),
    ethical-score: uint,
    verified: bool
  }
)

;; Product verification history
(define-map verification-history
  { product-id: (string-ascii 64), timestamp: uint }
  {
    verifier: principal,
    ethical-score: uint
  }
)

;; Register a new product
(define-public (register-product
    (product-id (string-ascii 64))
    (name (string-ascii 100))
    (materials (list 10 (string-ascii 64)))
    (facility-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? products { product-id: product-id })) (err u100))

    (map-set products
      { product-id: product-id }
      {
        name: name,
        materials: materials,
        facility-id: facility-id,
        ethical-score: u0,
        verified: false
      }
    )
    (ok true)
  )
)

;; Verify a product
(define-public (verify-product (product-id (string-ascii 64)) (ethical-score uint))
  (let ((product (unwrap! (map-get? products { product-id: product-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    ;; Update product verification status
    (map-set products
      { product-id: product-id }
      (merge product {
        ethical-score: ethical-score,
        verified: true
      })
    )

    ;; Record verification history
    (map-set verification-history
      { product-id: product-id, timestamp: block-height }
      {
        verifier: tx-sender,
        ethical-score: ethical-score
      }
    )

    (ok true)
  )
)

;; Get product details for consumer verification
(define-read-only (get-product (product-id (string-ascii 64)))
  (map-get? products { product-id: product-id })
)

;; Check if product is verified
(define-read-only (is-product-verified (product-id (string-ascii 64)))
  (default-to false (get verified (map-get? products { product-id: product-id })))
)

;; Get product ethical score
(define-read-only (get-product-ethical-score (product-id (string-ascii 64)))
  (default-to u0 (get ethical-score (map-get? products { product-id: product-id })))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)

