;; Job Marketplace Smart Contract
;; This contract facilitates a decentralized job marketplace where employers can post job listings,
;; job seekers can submit applications, and employers can manage the application process.
;; The contract supports job posting, editing, application submission, and status updates.

;; Data Structures

;; Job listing data structure
(define-map job-listings
  { job-listing-id: uint }
  { employer-address: principal,
    job-title: (string-ascii 100),
    job-description: (string-ascii 1000),
    annual-salary: uint,
    listing-active: bool,
    listing-created-at: uint,
    listing-updated-at: uint })

;; Job application data structure
(define-map job-applications
  { job-listing-id: uint, applicant-address: principal }
  { applicant-cover-letter: (string-ascii 1000),
    application-status: (string-ascii 20),
    application-timestamp: uint })

;; Track total number of job listings
(define-data-var total-job-listings uint u0)

;; Track application count per job listing
(define-map application-counts { job-listing-id: uint } { application-total: uint })

;; Error Constants
(define-constant ERR-INVALID-SALARY-AMOUNT u1)
(define-constant ERR-JOB-LISTING-NOT-FOUND u2)
(define-constant ERR-JOB-LISTING-INACTIVE u3)
(define-constant ERR-UNAUTHORIZED-ACCESS u4)
(define-constant ERR-DUPLICATE-APPLICATION u5)
(define-constant ERR-INVALID-JOB-ID u6)
(define-constant ERR-INVALID-STATUS-VALUE u7)
(define-constant ERR-INVALID-INPUT-DATA u8)

;; Helper Functions

;; Validate string input
(define-private (is-valid-string-input (input (string-ascii 1000)))
  (and (> (len input) u0) (<= (len input) u1000)))

;; Validate job listing ID
(define-private (is-valid-listing-id (job-listing-id uint))
  (and (> job-listing-id u0) (<= job-listing-id (var-get total-job-listings))))

;; Job Listing Functions

;; Create a new job listing
(define-public (create-job-listing (job-title (string-ascii 100)) (job-description (string-ascii 1000)) (annual-salary uint))
  (begin
    ;; Input validation
    (asserts! (is-valid-string-input job-title) (err ERR-INVALID-INPUT-DATA))
    (asserts! (is-valid-string-input job-description) (err ERR-INVALID-INPUT-DATA))
    (asserts! (> annual-salary u0) (err ERR-INVALID-SALARY-AMOUNT))
    
    (let 
      ((new-listing-id (+ (var-get total-job-listings) u1)))
      (map-set job-listings
        { job-listing-id: new-listing-id }
        { employer-address: tx-sender,
          job-title: job-title,
          job-description: job-description,
          annual-salary: annual-salary,
          listing-active: true,
          listing-created-at: block-height,
          listing-updated-at: block-height })
      (map-set application-counts { job-listing-id: new-listing-id } { application-total: u0 })
      (var-set total-job-listings new-listing-id)
      (ok new-listing-id))))

;; Update an existing job listing
(define-public (update-job-listing (job-listing-id uint) (job-title (string-ascii 100)) (job-description (string-ascii 1000)) (annual-salary uint))
  (begin
    ;; Input validation
    (asserts! (is-valid-listing-id job-listing-id) (err ERR-INVALID-JOB-ID))
    (asserts! (is-valid-string-input job-title) (err ERR-INVALID-INPUT-DATA))
    (asserts! (is-valid-string-input job-description) (err ERR-INVALID-INPUT-DATA))
    
    (let ((job-listing (map-get? job-listings { job-listing-id: job-listing-id })))
      (asserts! (is-some job-listing) (err ERR-JOB-LISTING-NOT-FOUND))
      (let ((listing-data (unwrap-panic job-listing)))
        (asserts! (is-eq (get employer-address listing-data) tx-sender) (err ERR-UNAUTHORIZED-ACCESS))
        (asserts! (get listing-active listing-data) (err ERR-JOB-LISTING-INACTIVE))
        (asserts! (> annual-salary u0) (err ERR-INVALID-SALARY-AMOUNT))
        (map-set job-listings
          { job-listing-id: job-listing-id }
          (merge listing-data { 
            job-title: job-title,
            job-description: job-description,
            annual-salary: annual-salary,
            listing-updated-at: block-height
          }))
        (ok true)))))

;; Deactivate a job listing
(define-public (deactivate-job-listing (job-listing-id uint))
  (begin
    ;; Input validation
    (asserts! (is-valid-listing-id job-listing-id) (err ERR-INVALID-JOB-ID))
    
    (let ((job-listing (map-get? job-listings { job-listing-id: job-listing-id })))
      (asserts! (is-some job-listing) (err ERR-JOB-LISTING-NOT-FOUND))
      (asserts! (is-eq (get employer-address (unwrap-panic job-listing)) tx-sender) (err ERR-UNAUTHORIZED-ACCESS))
      (map-set job-listings
        { job-listing-id: job-listing-id }
        (merge (unwrap-panic job-listing) { listing-active: false }))
      (ok true))))

;; Application Functions

;; Submit a job application
(define-public (submit-job-application (job-listing-id uint) (applicant-cover-letter (string-ascii 1000)))
  (begin
    ;; Input validation
    (asserts! (is-valid-listing-id job-listing-id) (err ERR-INVALID-JOB-ID))
    (asserts! (is-valid-string-input applicant-cover-letter) (err ERR-INVALID-INPUT-DATA))
    
    (let ((job-listing (map-get? job-listings { job-listing-id: job-listing-id })))
      (asserts! (is-some job-listing) (err ERR-JOB-LISTING-NOT-FOUND))
      (asserts! (get listing-active (unwrap-panic job-listing)) (err ERR-JOB-LISTING-INACTIVE))
      (asserts! (is-none (map-get? job-applications { job-listing-id: job-listing-id, applicant-address: tx-sender })) (err ERR-DUPLICATE-APPLICATION))
      
      ;; Create application
      (map-set job-applications
        { job-listing-id: job-listing-id, applicant-address: tx-sender }
        { applicant-cover-letter: applicant-cover-letter,
          application-status: "pending",
          application-timestamp: block-height })
      
      ;; Update application count
      (match (map-get? application-counts { job-listing-id: job-listing-id })
        count-data (map-set application-counts
                      { job-listing-id: job-listing-id }
                      { application-total: (+ (get application-total count-data) u1) })
        (map-set application-counts { job-listing-id: job-listing-id } { application-total: u1 }))
      
      (ok true))))

;; Update application status
(define-public (update-application-status (job-listing-id uint) (applicant-address principal) (new-application-status (string-ascii 20)))
  (begin
    ;; Input validation
    (asserts! (is-valid-listing-id job-listing-id) (err ERR-INVALID-JOB-ID))
    (asserts! (not (is-eq applicant-address tx-sender)) (err ERR-INVALID-INPUT-DATA))
    (asserts! (is-valid-string-input new-application-status) (err ERR-INVALID-INPUT-DATA))
    
    (let ((job-listing (map-get? job-listings { job-listing-id: job-listing-id }))
          (application (map-get? job-applications { job-listing-id: job-listing-id, applicant-address: applicant-address })))
      
      (asserts! (is-some job-listing) (err ERR-JOB-LISTING-NOT-FOUND))
      (asserts! (is-eq (get employer-address (unwrap-panic job-listing)) tx-sender) (err ERR-UNAUTHORIZED-ACCESS))
      (asserts! (is-some application) (err ERR-JOB-LISTING-NOT-FOUND))
      
      ;; Validate status value
      (asserts! (or 
                  (is-eq new-application-status "accepted") 
                  (is-eq new-application-status "rejected") 
                  (is-eq new-application-status "pending")) 
                (err ERR-INVALID-STATUS-VALUE))
      
      ;; Update application status
      (map-set job-applications
        { job-listing-id: job-listing-id, applicant-address: applicant-address }
        (merge (unwrap-panic application) { application-status: new-application-status }))
      
      (ok true))))

;; Read-Only Functions

;; Get job listing details
(define-read-only (get-job-listing-details (job-listing-id uint))
  (map-get? job-listings { job-listing-id: job-listing-id }))

;; Get application details
(define-read-only (get-application-details (job-listing-id uint) (applicant-address principal))
  (map-get? job-applications { job-listing-id: job-listing-id, applicant-address: applicant-address }))

;; Get total number of job listings
(define-read-only (get-total-job-listings)
  (var-get total-job-listings))

;; Get the number of applications for a job
(define-read-only (get-application-count-for-job (job-listing-id uint))
  (match (map-get? application-counts { job-listing-id: job-listing-id })
    count-data (ok (get application-total count-data))
    (err ERR-JOB-LISTING-NOT-FOUND)))