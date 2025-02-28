;; Podcast Monetization Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101)) 
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-already-reviewed (err u104))
(define-constant err-payment-failed (err u105))

;; Data Variables
(define-data-var min-subscription-amount uint u1000000)
(define-data-var platform-fee-percent uint u5) ;; 5% platform fee

;; Data Maps
[Previous maps remain unchanged...]

;; Public Functions
[Previous register-podcast function remains unchanged...]

(define-public (subscribe-to-podcast (podcast-owner principal))
    (let (
        (podcast (unwrap! (map-get? podcasts podcast-owner) err-not-found))
        (price (get subscription-price podcast))
        (current-block-height block-height)
        (platform-fee (/ (* price (var-get platform-fee-percent)) u100))
        (creator-amount (- price platform-fee))
    )
        (begin
            ;; Transfer full subscription amount
            (try! (stx-transfer? price tx-sender podcast-owner))
            
            ;; Transfer platform fee
            (try! (stx-transfer? platform-fee podcast-owner contract-owner))
            
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

[Previous review-podcast function with safe math added...]

(define-private (distribute-earnings (collaborator { address: principal, share: uint }) (total-amount uint))
    (stx-transfer? 
        (/ (* total-amount (get share collaborator)) u100)
        tx-sender
        (get address collaborator)
    )
)

;; Added new helper function
(define-read-only (is-subscription-active (podcast-owner principal) (subscriber principal))
    (let (
        (sub (map-get? subscriptions { podcast: podcast-owner, subscriber: subscriber }))
    )
        (and 
            (is-some sub)
            (get active (unwrap-panic sub))
            (< block-height (get expiry (unwrap-panic sub)))
        )
    )
)

[Previous read-only functions remain unchanged...]
