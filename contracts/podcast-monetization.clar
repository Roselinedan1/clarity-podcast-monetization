;; Podcast Monetization Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101)) 
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-already-reviewed (err u104))
(define-constant err-payment-failed (err u105))
(define-constant err-arithmetic-overflow (err u106))
(define-constant err-invalid-shares (err u107))

;; Data Variables
(define-data-var min-subscription-amount uint u1000000)
(define-data-var platform-fee-percent uint u5) ;; 5% platform fee

;; Safe Math Helpers
(define-private (safe-multiply (a uint) (b uint))
    (match (to-uint (* a b))
        success success
        err-arithmetic-overflow))

(define-private (safe-divide (a uint) (b uint))
    (match (to-uint (/ a b))
        success success
        err-arithmetic-overflow))

;; Updated subscribe-to-podcast function
(define-public (subscribe-to-podcast (podcast-owner principal))
    (let (
        (podcast (unwrap! (map-get? podcasts podcast-owner) err-not-found))
        (price (get subscription-price podcast))
        (current-block-height block-height)
        (platform-fee (unwrap! (safe-divide (unwrap! (safe-multiply price (var-get platform-fee-percent)) err-arithmetic-overflow) u100) err-arithmetic-overflow))
        (creator-amount (- price platform-fee))
    )
        (begin
            ;; Validate total shares equal 100%
            (asserts! (is-valid-shares (get collaborators podcast)) err-invalid-shares)
            
            ;; Transfer platform fee first
            (try! (stx-transfer? platform-fee tx-sender contract-owner))
            
            ;; Transfer remaining amount to creator
            (try! (stx-transfer? creator-amount tx-sender podcast-owner))
            
            ;; Update podcast earnings
            (map-set podcasts podcast-owner
                (merge podcast {
                    earnings: (+ (get earnings podcast) creator-amount)
                }))
            
            ;; Distribute earnings to collaborators
            (map (lambda (collab) 
                (try! (distribute-earnings collab creator-amount))) 
                (get collaborators podcast))
            
            ;; Set subscription
            (ok (map-set subscriptions
                { podcast: podcast-owner, subscriber: tx-sender }
                {
                    active: true,
                    expiry: (+ current-block-height u8640)
                }
            ))
        )
    )
)

;; New helper to validate collaborator shares
(define-private (is-valid-shares (collaborators (list 10 { address: principal, share: uint })))
    (let ((total-share (fold + (map get-share collaborators) u0)))
        (is-eq total-share u100))
)

(define-private (get-share (collaborator { address: principal, share: uint }))
    (get share collaborator))

;; Updated distribute-earnings function with safe math
(define-private (distribute-earnings (collaborator { address: principal, share: uint }) (total-amount uint))
    (let ((share-amount (unwrap! (safe-divide (unwrap! (safe-multiply total-amount (get share collaborator)) err-arithmetic-overflow) u100) err-arithmetic-overflow)))
        (stx-transfer? share-amount tx-sender (get address collaborator))
    )
)
