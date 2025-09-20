
;; title: ClimateChoice
;; version: 1.0.0
;; summary: Community-driven environmental project prioritization and impact assessment
;; description: A smart contract system that allows communities to submit, vote on, and track environmental projects

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-voted (err u103))
(define-constant err-invalid-status (err u104))
(define-constant err-project-not-active (err u105))

;; Project status constants
(define-constant status-pending u0)
(define-constant status-active u1)
(define-constant status-completed u2)
(define-constant status-cancelled u3)

;; Data Variables
(define-data-var next-project-id uint u1)
(define-data-var total-projects uint u0)

;; Data Maps
(define-map projects
  { project-id: uint }
  {
    title: (string-ascii 100),
    description: (string-utf8 500),
    creator: principal,
    category: (string-ascii 50),
    target-impact: uint,
    current-impact: uint,
    votes-for: uint,
    votes-against: uint,
    total-voters: uint,
    status: uint,
    created-at: uint,
    updated-at: uint,
    funding-goal: uint,
    current-funding: uint
  }
)

(define-map project-votes
  { project-id: uint, voter: principal }
  { vote: bool, timestamp: uint }
)

(define-map user-contributions
  { project-id: uint, contributor: principal }
  { amount: uint, timestamp: uint }
)

(define-map project-categories
  { category: (string-ascii 50) }
  { total-projects: uint, active-projects: uint }
)

;; Public Functions

;; Submit a new environmental project
(define-public (submit-project
  (title (string-ascii 100))
  (description (string-utf8 500))
  (category (string-ascii 50))
  (target-impact uint)
  (funding-goal uint))
  (let
    (
      (project-id (var-get next-project-id))
      (current-block-height block-height)
    )
    (map-set projects
      { project-id: project-id }
      {
        title: title,
        description: description,
        creator: tx-sender,
        category: category,
        target-impact: target-impact,
        current-impact: u0,
        votes-for: u0,
        votes-against: u0,
        total-voters: u0,
        status: status-pending,
        created-at: current-block-height,
        updated-at: current-block-height,
        funding-goal: funding-goal,
        current-funding: u0
      }
    )

    ;; Update category stats
    (map-set project-categories
      { category: category }
      {
        total-projects: (+ (get total-projects (default-to { total-projects: u0, active-projects: u0 }
                                                (map-get? project-categories { category: category }))) u1),
        active-projects: (get active-projects (default-to { total-projects: u0, active-projects: u0 }
                                               (map-get? project-categories { category: category })))
      }
    )

    ;; Update counters
    (var-set next-project-id (+ project-id u1))
    (var-set total-projects (+ (var-get total-projects) u1))

    (ok project-id)
  )
)

;; Vote on a project (true for support, false for against)
(define-public (vote-on-project (project-id uint) (vote bool))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
      (existing-vote (map-get? project-votes { project-id: project-id, voter: tx-sender }))
    )
    ;; Check if user already voted
    (asserts! (is-none existing-vote) err-already-voted)

    ;; Check if project is in pending status (can only vote on pending projects)
    (asserts! (is-eq (get status project) status-pending) err-project-not-active)

    ;; Record the vote
    (map-set project-votes
      { project-id: project-id, voter: tx-sender }
      { vote: vote, timestamp: block-height }
    )

    ;; Update project vote counts
    (map-set projects
      { project-id: project-id }
      (merge project {
        votes-for: (if vote (+ (get votes-for project) u1) (get votes-for project)),
        votes-against: (if vote (get votes-against project) (+ (get votes-against project) u1)),
        total-voters: (+ (get total-voters project) u1),
        updated-at: block-height
      })
    )

    (ok true)
  )
)

;; Activate a project (only contract owner can do this)
(define-public (activate-project (project-id uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq (get status project) status-pending) err-invalid-status)

    (map-set projects
      { project-id: project-id }
      (merge project {
        status: status-active,
        updated-at: block-height
      })
    )

    ;; Update category active projects count
    (let
      (
        (category-data (default-to { total-projects: u0, active-projects: u0 }
                                   (map-get? project-categories { category: (get category project) })))
      )
      (map-set project-categories
        { category: (get category project) }
        (merge category-data {
          active-projects: (+ (get active-projects category-data) u1)
        })
      )
    )

    (ok true)
  )
)

;; Update project impact (only project creator can do this)
(define-public (update-impact (project-id uint) (new-impact uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get creator project)) err-unauthorized)
    (asserts! (is-eq (get status project) status-active) err-project-not-active)

    (map-set projects
      { project-id: project-id }
      (merge project {
        current-impact: new-impact,
        updated-at: block-height
      })
    )

    (ok true)
  )
)

;; Contribute funding to a project
(define-public (contribute-funding (project-id uint) (amount uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
      (existing-contribution (default-to { amount: u0, timestamp: u0 }
                                         (map-get? user-contributions { project-id: project-id, contributor: tx-sender })))
    )
    (asserts! (is-eq (get status project) status-active) err-project-not-active)

    ;; Record/update contribution
    (map-set user-contributions
      { project-id: project-id, contributor: tx-sender }
      {
        amount: (+ (get amount existing-contribution) amount),
        timestamp: block-height
      }
    )

    ;; Update project funding
    (map-set projects
      { project-id: project-id }
      (merge project {
        current-funding: (+ (get current-funding project) amount),
        updated-at: block-height
      })
    )

    (ok true)
  )
)

;; Complete a project (only project creator can do this)
(define-public (complete-project (project-id uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get creator project)) err-unauthorized)
    (asserts! (is-eq (get status project) status-active) err-project-not-active)

    (map-set projects
      { project-id: project-id }
      (merge project {
        status: status-completed,
        updated-at: block-height
      })
    )

    ;; Update category active projects count
    (let
      (
        (category-data (default-to { total-projects: u0, active-projects: u0 }
                                   (map-get? project-categories { category: (get category project) })))
      )
      (map-set project-categories
        { category: (get category project) }
        (merge category-data {
          active-projects: (- (get active-projects category-data) u1)
        })
      )
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get project details
(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

;; Get user's vote on a project
(define-read-only (get-user-vote (project-id uint) (voter principal))
  (map-get? project-votes { project-id: project-id, voter: voter })
)

;; Get user's contribution to a project
(define-read-only (get-user-contribution (project-id uint) (contributor principal))
  (map-get? user-contributions { project-id: project-id, contributor: contributor })
)

;; Get category statistics
(define-read-only (get-category-stats (category (string-ascii 50)))
  (map-get? project-categories { category: category })
)

;; Get total number of projects
(define-read-only (get-total-projects)
  (var-get total-projects)
)

;; Get next project ID
(define-read-only (get-next-project-id)
  (var-get next-project-id)
)

;; Check if project has reached funding goal
(define-read-only (is-funding-goal-reached (project-id uint))
  (match (map-get? projects { project-id: project-id })
    project (>= (get current-funding project) (get funding-goal project))
    false
  )
)

;; Calculate project completion percentage
(define-read-only (get-impact-completion-percentage (project-id uint))
  (match (map-get? projects { project-id: project-id })
    project
    (if (> (get target-impact project) u0)
        (/ (* (get current-impact project) u100) (get target-impact project))
        u0)
    u0
  )
)

;; Get project vote ratio (votes-for / total-voters * 100)
(define-read-only (get-project-support-percentage (project-id uint))
  (match (map-get? projects { project-id: project-id })
    project
    (if (> (get total-voters project) u0)
        (/ (* (get votes-for project) u100) (get total-voters project))
        u0)
    u0
  )
)
