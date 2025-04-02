;; Material Tracking Contract
;; Monitors components through production

(define-data-var admin principal tx-sender)

;; Material data structure
(define-map materials
  { material-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    supplier-id: (string-ascii 64),
    batch-number: (string-ascii 64),
    production-date: uint,
    ethical-status: bool
  }
)

;; Material tracking through supply chain
(define-map material-tracking
  { material-id: (string-ascii 64), stage-id: uint }
  {
    timestamp: uint,
    location: (string-ascii 100),
    handler: principal,
    notes: (string-ascii 256)
  }
)

;; Register a new material
(define-public (register-material
    (material-id (string-ascii 64))
    (name (string-ascii 100))
    (supplier-id (string-ascii 64))
    (batch-number (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? materials { material-id: material-id })) (err u100))

    (map-set materials
      { material-id: material-id }
      {
        name: name,
        supplier-id: supplier-id,
        batch-number: batch-number,
        production-date: block-height,
        ethical-status: false
      }
    )
    (ok true)
  )
)

;; Update material ethical status
(define-public (update-ethical-status (material-id (string-ascii 64)) (status bool))
  (let ((material (unwrap! (map-get? materials { material-id: material-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set materials
      { material-id: material-id }
      (merge material { ethical-status: status })
    )

    (ok true)
  )
)

;; Track material through supply chain
(define-public (track-material
    (material-id (string-ascii 64))
    (stage-id uint)
    (location (string-ascii 100))
    (notes (string-ascii 256)))
  (begin
    (asserts! (is-some (map-get? materials { material-id: material-id })) (err u404))

    (map-set material-tracking
      { material-id: material-id, stage-id: stage-id }
      {
        timestamp: block-height,
        location: location,
        handler: tx-sender,
        notes: notes
      }
    )

    (ok true)
  )
)

;; Get material details
(define-read-only (get-material (material-id (string-ascii 64)))
  (map-get? materials { material-id: material-id })
)

;; Get material tracking information for a specific stage
(define-read-only (get-material-tracking (material-id (string-ascii 64)) (stage-id uint))
  (map-get? material-tracking { material-id: material-id, stage-id: stage-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)

