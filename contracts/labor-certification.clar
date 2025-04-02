;; Labor Certification Contract
;; Verifies fair labor practices

(define-data-var admin principal tx-sender)

;; Labor certification data structure
(define-map labor-certifications
  { facility-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    location: (string-ascii 100),
    certified: bool,
    labor-score: uint,
    certification-date: uint,
    certifier: principal
  }
)

;; Certification history
(define-map certification-history
  { facility-id: (string-ascii 64), timestamp: uint }
  {
    certifier: principal,
    labor-score: uint,
    notes: (string-ascii 256)
  }
)

;; Register a new facility
(define-public (register-facility
    (facility-id (string-ascii 64))
    (name (string-ascii 100))
    (location (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? labor-certifications { facility-id: facility-id })) (err u100))

    (map-set labor-certifications
      { facility-id: facility-id }
      {
        name: name,
        location: location,
        certified: false,
        labor-score: u0,
        certification-date: u0,
        certifier: tx-sender
      }
    )
    (ok true)
  )
)

;; Certify a facility
(define-public (certify-facility
    (facility-id (string-ascii 64))
    (labor-score uint)
    (notes (string-ascii 256)))
  (let ((facility (unwrap! (map-get? labor-certifications { facility-id: facility-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    ;; Update facility certification status
    (map-set labor-certifications
      { facility-id: facility-id }
      (merge facility {
        certified: true,
        labor-score: labor-score,
        certification-date: block-height,
        certifier: tx-sender
      })
    )

    ;; Record certification history
    (map-set certification-history
      { facility-id: facility-id, timestamp: block-height }
      {
        certifier: tx-sender,
        labor-score: labor-score,
        notes: notes
      }
    )

    (ok true)
  )
)

;; Get facility certification details
(define-read-only (get-facility (facility-id (string-ascii 64)))
  (map-get? labor-certifications { facility-id: facility-id })
)

;; Check if facility is certified
(define-read-only (is-facility-certified (facility-id (string-ascii 64)))
  (default-to false (get certified (map-get? labor-certifications { facility-id: facility-id })))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)

