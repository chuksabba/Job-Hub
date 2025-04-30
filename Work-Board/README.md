# Job Marketplace Smart Contract

A decentralized job marketplace built on Stacks blockchain that enables employers to post job listings, job seekers to submit applications, and employers to manage the application process - all in a trustless, transparent environment.

## Overview

This smart contract facilitates a decentralized job marketplace where employers and job seekers can interact directly without intermediaries. The contract manages job listings, tracks applications, and provides functionality for the entire job posting and application lifecycle.

## Features

- **Job Listing Management**: Create, update, and deactivate job listings
- **Application Submission**: Submit applications with cover letters to job listings
- **Application Processing**: Review and update application statuses
- **Data Transparency**: All job and application data is stored on-chain
- **Access Controls**: Only authorized users can modify listings and applications

## Data Structures

### Job Listings

Each job listing contains:
- Employer address (principal)
- Job title (string)
- Job description (string)
- Annual salary (uint)
- Active status (boolean)
- Creation timestamp (uint)
- Last update timestamp (uint)

### Job Applications

Each application contains:
- Applicant cover letter (string)
- Application status (string: "pending", "accepted", or "rejected")
- Application timestamp (uint)

## Function Reference

### Job Listing Functions

#### `create-job-listing`

Creates a new job listing.

**Parameters:**
- `job-title`: String (max 100 chars)
- `job-description`: String (max 1000 chars)
- `annual-salary`: Unsigned integer (must be > 0)

**Returns:**
- The ID of the newly created job listing

**Example:**
```clarity
(contract-call? .job-marketplace create-job-listing "Senior Blockchain Developer" "Looking for an experienced developer..." u120000)
```

#### `update-job-listing`

Updates an existing job listing.

**Parameters:**
- `job-listing-id`: Unsigned integer
- `job-title`: String (max 100 chars)
- `job-description`: String (max 1000 chars)
- `annual-salary`: Unsigned integer (must be > 0)

**Returns:**
- Boolean success value

**Example:**
```clarity
(contract-call? .job-marketplace update-job-listing u1 "Senior Blockchain Developer" "Updated job description..." u125000)
```

#### `deactivate-job-listing`

Deactivates a job listing.

**Parameters:**
- `job-listing-id`: Unsigned integer

**Returns:**
- Boolean success value

**Example:**
```clarity
(contract-call? .job-marketplace deactivate-job-listing u1)
```

### Application Functions

#### `submit-job-application`

Submits an application to a job listing.

**Parameters:**
- `job-listing-id`: Unsigned integer
- `applicant-cover-letter`: String (max 1000 chars)

**Returns:**
- Boolean success value

**Example:**
```clarity
(contract-call? .job-marketplace submit-job-application u1 "I am interested in this position because...")
```

#### `update-application-status`

Updates the status of a job application.

**Parameters:**
- `job-listing-id`: Unsigned integer
- `applicant-address`: Principal
- `new-application-status`: String (must be "pending", "accepted", or "rejected")

**Returns:**
- Boolean success value

**Example:**
```clarity
(contract-call? .job-marketplace update-application-status u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM "accepted")
```

### Read-Only Functions

#### `get-job-listing-details`

Retrieves details for a specific job listing.

**Parameters:**
- `job-listing-id`: Unsigned integer

**Returns:**
- Job listing data or none

**Example:**
```clarity
(contract-call? .job-marketplace get-job-listing-details u1)
```

#### `get-application-details`

Retrieves details for a specific application.

**Parameters:**
- `job-listing-id`: Unsigned integer
- `applicant-address`: Principal

**Returns:**
- Application data or none

**Example:**
```clarity
(contract-call? .job-marketplace get-application-details u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

#### `get-total-job-listings`

Gets the total number of job listings.

**Parameters:**
- None

**Returns:**
- Unsigned integer representing total job listings

**Example:**
```clarity
(contract-call? .job-marketplace get-total-job-listings)
```

#### `get-application-count-for-job`

Gets the number of applications for a specific job listing.

**Parameters:**
- `job-listing-id`: Unsigned integer

**Returns:**
- Unsigned integer representing application count or error

**Example:**
```clarity
(contract-call? .job-marketplace get-application-count-for-job u1)
```

## Error Codes

| Code | Description |
|------|-------------|
| u1 | Invalid salary amount (must be > 0) |
| u2 | Job listing not found |
| u3 | Job listing is inactive |
| u4 | Unauthorized access |
| u5 | Duplicate application |
| u6 | Invalid job ID |
| u7 | Invalid status value (must be "pending", "accepted", or "rejected") |
| u8 | Invalid input data |

## Usage Flow

### Employer Flow

1. Employer creates a job listing
2. Employer can update the job listing if needed
3. Employer reviews applications as they arrive
4. Employer updates application statuses to "accepted" or "rejected"
5. When the position is filled, employer deactivates the job listing

### Job Seeker Flow

1. Job seeker browses available job listings
2. Job seeker submits application with a cover letter
3. Job seeker can check the status of their application

## Security Considerations

- Only the employer who created a job listing can update or deactivate it
- Only the employer can update application statuses
- Job seekers can only submit one application per job listing
- Input validation is performed on all function parameters

## Development and Deployment

### Prerequisites

- [Clarity language](https://docs.stacks.co/docs/clarity/) knowledge
- [Stacks blockchain](https://www.stacks.co/) wallet with STX tokens
- [Clarinet](https://github.com/hirosystems/clarinet) for local development

### Deployment

1. Clone this repository
2. Use Clarinet to test the contract locally
3. Deploy to testnet or mainnet using Clarinet or the Stacks Explorer