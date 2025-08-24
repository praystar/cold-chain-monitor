;; ColdChain Monitor Smart Contract
;; Tracks temperature-sensitive goods from origin to consumer
;; Ensures quality maintenance throughout the supply chain

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_SHIPMENT_NOT_FOUND (err u404))
(define-constant ERR_INVALID_TEMPERATURE (err u400))
(define-constant ERR_SHIPMENT_ALREADY_EXISTS (err u409))
(define-constant ERR_SHIPMENT_COMPLETED (err u410))
(define-constant ERR_TEMPERATURE_BREACH (err u411))
(define-constant ERR_NOT_AUTHORIZED (err u403))

;; Data structures
(define-map shipments 
  { shipment-id: (string-ascii 64) }
  {
    origin: principal,
    destination: principal,
    current-handler: principal,
    product-type: (string-ascii 100),
    min-temp: int,
    max-temp: int,
    current-temp: int,
    status: (string-ascii 20),
    created-at: uint,
    updated-at: uint,
    temperature-breaches: uint,
    quality-score: uint
  }
)

(define-map temperature-logs
  { shipment-id: (string-ascii 64), log-id: uint }
  {
    temperature: int,
    timestamp: uint,
    location: (string-ascii 100),
    handler: principal,
    sensor-id: (string-ascii 50)
  }
)

(define-map authorized-handlers principal bool)

;; Data variables
(define-data-var next-log-id uint u1)

;; Authorization functions
(define-public (add-authorized-handler (handler principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-set authorized-handlers handler true)
    (ok true)
  )
)

(define-public (remove-authorized-handler (handler principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-delete authorized-handlers handler)
    (ok true)
  )
)

(define-read-only (is-authorized-handler (handler principal))
  (default-to false (map-get? authorized-handlers handler))
)

;; Core shipment functions
(define-public (create-shipment 
  (shipment-id (string-ascii 64))
  (destination principal)
  (product-type (string-ascii 100))
  (min-temp int)
  (max-temp int)
  (initial-temp int))
  (begin
    (asserts! (is-none (map-get? shipments {shipment-id: shipment-id})) ERR_SHIPMENT_ALREADY_EXISTS)
    (asserts! (<= min-temp max-temp) ERR_INVALID_TEMPERATURE)
    (asserts! (and (<= min-temp initial-temp) (<= initial-temp max-temp)) ERR_INVALID_TEMPERATURE)
    
    (map-set shipments 
      {shipment-id: shipment-id}
      {
        origin: tx-sender,
        destination: destination,
        current-handler: tx-sender,
        product-type: product-type,
        min-temp: min-temp,
        max-temp: max-temp,
        current-temp: initial-temp,
        status: "created",
        created-at: stacks-block-height,
        updated-at: stacks-block-height,
        temperature-breaches: u0,
        quality-score: u100
      }
    )
    
    ;; Log initial temperature
    (try! (log-temperature shipment-id initial-temp "Origin" "ORIGIN_SENSOR"))
    
    (ok shipment-id)
  )
)

(define-public (transfer-custody 
  (shipment-id (string-ascii 64))
  (new-handler principal))
  (let ((shipment (unwrap! (map-get? shipments {shipment-id: shipment-id}) ERR_SHIPMENT_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get current-handler shipment)) ERR_NOT_AUTHORIZED)
    (asserts! (not (is-eq (get status shipment) "completed")) ERR_SHIPMENT_COMPLETED)
    
    (map-set shipments 
      {shipment-id: shipment-id}
      (merge shipment {
        current-handler: new-handler,
        status: "in-transit",
        updated-at: stacks-block-height
      })
    )
    
    (ok true)
  )
)

(define-public (log-temperature 
  (shipment-id (string-ascii 64))
  (temperature int)
  (location (string-ascii 100))
  (sensor-id (string-ascii 50)))
  (let (
    (shipment (unwrap! (map-get? shipments {shipment-id: shipment-id}) ERR_SHIPMENT_NOT_FOUND))
    (log-id (var-get next-log-id))
    (is-breach (or (< temperature (get min-temp shipment)) (> temperature (get max-temp shipment))))
    (new-breaches (if is-breach (+ (get temperature-breaches shipment) u1) (get temperature-breaches shipment)))
    (quality-reduction (if is-breach u10 u0))
    (new-quality (if (>= (get quality-score shipment) quality-reduction) 
                     (- (get quality-score shipment) quality-reduction) 
                     u0))
  )
    (asserts! (or (is-eq tx-sender (get current-handler shipment)) 
                  (is-authorized-handler tx-sender)) ERR_NOT_AUTHORIZED)
    (asserts! (not (is-eq (get status shipment) "completed")) ERR_SHIPMENT_COMPLETED)
    
    ;; Create temperature log entry
    (map-set temperature-logs
      {shipment-id: shipment-id, log-id: log-id}
      {
        temperature: temperature,
        timestamp: stacks-block-height,
        location: location,
        handler: tx-sender,
        sensor-id: sensor-id
      }
    )
    
    ;; Update shipment with new temperature and quality data
    (map-set shipments
      {shipment-id: shipment-id}
      (merge shipment {
        current-temp: temperature,
        updated-at: stacks-block-height,
        temperature-breaches: new-breaches,
        quality-score: new-quality
      })
    )
    
    (var-set next-log-id (+ log-id u1))
    
    ;; Return error if temperature breach occurred
    (if is-breach
      ERR_TEMPERATURE_BREACH
      (ok log-id)
    )
  )
)

(define-public (complete-delivery (shipment-id (string-ascii 64)))
  (let ((shipment (unwrap! (map-get? shipments {shipment-id: shipment-id}) ERR_SHIPMENT_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get destination shipment)) ERR_NOT_AUTHORIZED)
    (asserts! (not (is-eq (get status shipment) "completed")) ERR_SHIPMENT_COMPLETED)
    
    (map-set shipments
      {shipment-id: shipment-id}
      (merge shipment {
        status: "completed",
        updated-at: stacks-block-height
      })
    )
    
    (ok (get quality-score shipment))
  )
)

;; Quality assessment functions
(define-read-only (get-quality-assessment (shipment-id (string-ascii 64)))
  (let ((shipment (unwrap! (map-get? shipments {shipment-id: shipment-id}) ERR_SHIPMENT_NOT_FOUND)))
    (ok {
      quality-score: (get quality-score shipment),
      temperature-breaches: (get temperature-breaches shipment),
      status: (get status shipment),
      assessment: (if (>= (get quality-score shipment) u80)
                     "excellent"
                     (if (>= (get quality-score shipment) u60)
                         "good"
                         (if (>= (get quality-score shipment) u40)
                             "fair"
                             "poor")))
    })
  )
)

;; Read-only functions
(define-read-only (get-shipment (shipment-id (string-ascii 64)))
  (map-get? shipments {shipment-id: shipment-id})
)

(define-read-only (get-temperature-log (shipment-id (string-ascii 64)) (log-id uint))
  (map-get? temperature-logs {shipment-id: shipment-id, log-id: log-id})
)

(define-read-only (get-shipment-status (shipment-id (string-ascii 64)))
  (match (map-get? shipments {shipment-id: shipment-id})
    shipment (ok {
      status: (get status shipment),
      current-handler: (get current-handler shipment),
      current-temp: (get current-temp shipment),
      quality-score: (get quality-score shipment),
      last-updated: (get updated-at shipment)
    })
    ERR_SHIPMENT_NOT_FOUND
  )
)

(define-read-only (is-temperature-compliant (shipment-id (string-ascii 64)))
  (match (map-get? shipments {shipment-id: shipment-id})
    shipment (let ((current-temp (get current-temp shipment)))
               (ok (and (>= current-temp (get min-temp shipment))
                       (<= current-temp (get max-temp shipment)))))
    ERR_SHIPMENT_NOT_FOUND
  )
)

;; Emergency functions
(define-public (report-emergency 
  (shipment-id (string-ascii 64))
  (emergency-type (string-ascii 50))
  (description (string-ascii 200)))
  (let ((shipment (unwrap! (map-get? shipments {shipment-id: shipment-id}) ERR_SHIPMENT_NOT_FOUND)))
    (asserts! (or (is-eq tx-sender (get current-handler shipment))
                  (is-authorized-handler tx-sender)) ERR_NOT_AUTHORIZED)
    
    (map-set shipments
      {shipment-id: shipment-id}
      (merge shipment {
        status: "emergency",
        updated-at: stacks-block-height
      })
    )
    
    ;; In a real implementation, this could trigger alerts or notifications
    (ok true)
  )
)

;; Initialize contract
(begin
  (map-set authorized-handlers CONTRACT_OWNER true)
)