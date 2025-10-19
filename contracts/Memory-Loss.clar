;; title: Memory-Loss DAO
;; version: 1.0.0
;; summary: A DAO with anti-hoarding governance - proposals auto-erase weekly
;; description: Simple DAO contract where old proposals are permanently erased every week to prevent governance hoarding

;; constants
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u404))
(define-constant ERR_PROPOSAL_EXPIRED (err u410))
(define-constant ERR_INVALID_VOTES (err u400))
(define-constant BLOCKS_PER_WEEK u1008) ;; ~7 days worth of blocks

;; data vars
(define-data-var next-proposal-id uint u1)
(define-data-var dao-treasury uint u0)

;; data maps
(define-map proposals
  uint
  {
    title: (string-ascii 50),
    description: (string-ascii 200),
    proposer: principal,
    created-at: uint,
    votes-for: uint,
    votes-against: uint,
    executed: bool
  }
)

(define-map member-votes
  { proposal-id: uint, voter: principal }
  { vote: bool, amount: uint }
)

(define-map dao-members principal uint)

;; public functions
(define-public (join-dao (stake-amount uint))
  (begin
    (asserts! (> stake-amount u0) ERR_INVALID_VOTES)
    (map-set dao-members tx-sender stake-amount)
    (var-set dao-treasury (+ (var-get dao-treasury) stake-amount))
    (ok true)
  )
)

(define-public (create-proposal (title (string-ascii 50)) (description (string-ascii 200)))
  (let 
    (
      (proposal-id (var-get next-proposal-id))
      (current-block block-height)
    )
    (asserts! (is-some (map-get? dao-members tx-sender)) ERR_UNAUTHORIZED)
    (asserts! (> (len title) u0) ERR_INVALID_VOTES)
    (asserts! (> (len description) u0) ERR_INVALID_VOTES)
    (map-set proposals proposal-id
      {
        title: title,
        description: description,
        proposer: tx-sender,
        created-at: current-block,
        votes-for: u0,
        votes-against: u0,
        executed: false
      }
    )
    (var-set next-proposal-id (+ proposal-id u1))
    (ok proposal-id)
  )
)

(define-public (vote-proposal (proposal-id uint) (vote-for bool))
  (let
    (
      (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
      (member-stake (unwrap! (map-get? dao-members tx-sender) ERR_UNAUTHORIZED))
      (proposal-age (- block-height (get created-at proposal)))
    )
    (asserts! (< proposal-age BLOCKS_PER_WEEK) ERR_PROPOSAL_EXPIRED)
    (asserts! (> member-stake u0) ERR_INVALID_VOTES)
    (asserts! (> proposal-id u0) ERR_PROPOSAL_NOT_FOUND)

    (map-set member-votes { proposal-id: proposal-id, voter: tx-sender }
      { vote: vote-for, amount: member-stake })

    (if vote-for
      (let ((current-votes (get votes-for proposal)))
        (asserts! (<= member-stake (- u340282366920938463463374607431768211455 current-votes)) ERR_INVALID_VOTES)
        (map-set proposals proposal-id
          (merge proposal { votes-for: (+ current-votes member-stake) })))
      (let ((current-votes (get votes-against proposal)))
        (asserts! (<= member-stake (- u340282366920938463463374607431768211455 current-votes)) ERR_INVALID_VOTES)
        (map-set proposals proposal-id
          (merge proposal { votes-against: (+ current-votes member-stake) })))
    )
    (ok true)
  )
)

(define-public (erase-old-proposals)
  (let
    (
      (max-id (var-get next-proposal-id))
    )
    (fold erase-proposal-if-old (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) (ok u0))
  )
)

;; read only functions
(define-read-only (get-proposal (proposal-id uint))
  (let
    (
      (proposal (map-get? proposals proposal-id))
    )
    (match proposal
      some-proposal 
        (let ((proposal-age (- block-height (get created-at some-proposal))))
          (if (>= proposal-age BLOCKS_PER_WEEK)
            none
            (some some-proposal)
          )
        )
      none
    )
  )
)

(define-read-only (get-dao-member (member principal))
  (map-get? dao-members member)
)

(define-read-only (get-treasury-balance)
  (var-get dao-treasury)
)

(define-read-only (get-next-proposal-id)
  (var-get next-proposal-id)
)

;; private functions
(define-private (erase-proposal-if-old (proposal-id uint) (acc (response uint uint)))
  (let
    (
      (proposal (map-get? proposals proposal-id))
    )
    (match proposal
      some-proposal
        (let ((proposal-age (- block-height (get created-at some-proposal))))
          (if (>= proposal-age BLOCKS_PER_WEEK)
            (begin
              (map-delete proposals proposal-id)
              acc
            )
            acc
          )
        )
      acc
    )
  )
)

