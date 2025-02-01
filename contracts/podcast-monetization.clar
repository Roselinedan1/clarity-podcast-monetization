;; Podcast Monetization Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101)) 
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-already-reviewed (err u104))

;; Data Variables
(define-data-var min-subscription-amount uint u1000000)
(define-data-var platform-fee-percent uint u5) ;; 5% platform fee

;; Data Maps
(define-map podcasts principal
    {
        title: (string-ascii 100),
        description: (string-ascii 500),
        subscription-price: uint,
        earnings: uint,
        total-reviews: uint,
        avg-rating: uint,
        collaborators: (list 10 { address: principal, share: uint })
    }
)

(define-map subscriptions { podcast: principal, subscriber: principal }
    {
        active: bool,
        expiry: uint
    }
)

(define-map reviews { podcast: principal, reviewer: principal }
    {
        rating: uint,
        comment: (string-ascii 500),
        timestamp: uint
    }
)

;; Public Functions
(define-public (register-podcast (title (string-ascii 100)) (description (string-ascii 500)) (price uint) (collaborators (list 10 { address: principal, share: uint })))
    (begin
        (asserts! (>= price (var-get min-subscription-amount)) err-invalid-amount)
        ;; Validate collaborator shares sum to 100%
        (asserts! (is-eq (fold + (map get share collaborators) u0) u100) err-invalid-amount)
        (ok (map-set podcasts tx-sender {
            title: title,
            description: description,
            subscription-price: price,
            earnings: u0,
            total-reviews: u0,
            avg-rating: u0,
            collaborators: collaborators
        }))
    )
)

(define-public (subscribe-to-podcast (podcast-owner principal))
    (let (
        (podcast (unwrap! (map-get? podcasts podcast-owner) err-not-found))
        (price (get subscription-price podcast))
        (current-block-height block-height)
        (platform-fee (/ (* price (var-get platform-fee-percent)) u100))
    )
        (begin
            ;; Transfer platform fee
            (try! (stx-transfer? platform-fee tx-sender contract-owner))
            
            ;; Distribute remaining amount to collaborators
            (map-set podcasts podcast-owner
                (merge podcast {
                    earnings: (+ (get earnings podcast) (- price platform-fee))
                }))
            
            ;; Distribute earnings to collaborators
            (map distribute-earnings (get collaborators podcast))
            
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

(define-public (review-podcast (podcast-owner principal) (rating uint) (comment (string-ascii 500)))
    (let (
        (podcast (unwrap! (map-get? podcasts podcast-owner) err-not-found))
        (existing-review (map-get? reviews { podcast: podcast-owner, reviewer: tx-sender }))
    )
        (begin
            (asserts! (is-none existing-review) err-already-reviewed)
            (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-amount)
            
            (map-set reviews
                { podcast: podcast-owner, reviewer: tx-sender }
                {
                    rating: rating,
                    comment: comment,
                    timestamp: block-height
                }
            )
            
            (map-set podcasts podcast-owner
                (merge podcast {
                    total-reviews: (+ (get total-reviews podcast) u1),
                    avg-rating: (/ (+ (* (get avg-rating podcast) (get total-reviews podcast)) rating)
                                 (+ (get total-reviews podcast) u1))
                }))
            
            (ok true)
        )
    )
)

(define-private (distribute-earnings (collaborator { address: principal, share: uint }))
    (stx-transfer? 
        (/ (* (- price platform-fee) (get share collaborator)) u100)
        tx-sender
        (get address collaborator)
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

(define-read-only (get-podcast-reviews (podcast-owner principal))
    (map-get? reviews { podcast: podcast-owner, reviewer: tx-sender })
)
