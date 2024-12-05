;; Podcast Monetization Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))

;; Data Variables
(define-data-var min-subscription-amount uint u1000000)

;; Data Maps
(define-map podcasts principal
    {
        title: (string-ascii 100),
        description: (string-ascii 500),
        subscription-price: uint,
        earnings: uint
    }
)

(define-map subscriptions { podcast: principal, subscriber: principal }
    {
        active: bool,
        expiry: uint
    }
)

;; Public Functions
(define-public (register-podcast (title (string-ascii 100)) (description (string-ascii 500)) (price uint))
    (begin
        (asserts! (>= price (var-get min-subscription-amount)) err-invalid-amount)
        (ok (map-set podcasts tx-sender {
            title: title,
            description: description,
            subscription-price: price,
            earnings: u0
        }))
    )
)

(define-public (subscribe-to-podcast (podcast-owner principal))
    (let (
        (podcast (unwrap! (map-get? podcasts podcast-owner) err-not-found))
        (price (get subscription-price podcast))
        (current-block-height block-height)
    )
        (begin
            ;; Transfer subscription amount
            (try! (stx-transfer? price tx-sender podcast-owner))
            
            ;; Update podcast earnings
            (map-set podcasts podcast-owner 
                (merge podcast { earnings: (+ (get earnings podcast) price) }))
            
            ;; Set subscription
            (ok (map-set subscriptions 
                { podcast: podcast-owner, subscriber: tx-sender }
                { 
                    active: true,
                    expiry: (+ current-block-height u8640) ;; ~30 days in blocks
                }
            ))
        )
    )
)

(define-public (update-subscription-price (new-price uint))
    (let (
        (podcast (unwrap! (map-get? podcasts tx-sender) err-not-found))
    )
        (begin
            (asserts! (>= new-price (var-get min-subscription-amount)) err-invalid-amount)
            (ok (map-set podcasts tx-sender 
                (merge podcast { subscription-price: new-price })))
        )
    )
)

;; Read Only Functions
(define-read-only (get-podcast-details (podcast-owner principal))
    (map-get? podcasts podcast-owner)
)

(define-read-only (get-subscription-status (podcast-owner principal) (subscriber principal))
    (let (
        (sub (map-get? subscriptions { podcast: podcast-owner, subscriber: subscriber }))
    )
        (if (is-some sub)
            (some (get active (unwrap-panic sub)))
            none
        )
    )
)

(define-read-only (get-podcast-earnings (podcast-owner principal))
    (let (
        (podcast (map-get? podcasts podcast-owner))
    )
        (if (is-some podcast)
            (some (get earnings (unwrap-panic podcast)))
            none
        )
    )
)
