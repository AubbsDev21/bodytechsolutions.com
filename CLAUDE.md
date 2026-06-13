# CLAUDE.md

## What this project is

This repo is the source for **bodytechsolutions.com**, the main website for Body Technology Solutions LLC. It is a static site built with HTML, CSS, and JavaScript, with SEO built in through meta tags, structured data, a sitemap, and robots.txt.

This is a monorepo. The site code and the infrastructure code that deploys and runs it live in the same repository.

The site doubles as a live case study. How it is built, deployed, and secured on AWS is something we can show clients directly as a vendor. The infrastructure choices here should reflect what we would recommend to a client.

## File structure

```
.
├── index.html                  → main site
├── favicon.svg                  → site favicon
├── sitemap.xml                  → search engine sitemap
├── robots.txt                   → crawler rules
├── README.md                    → repo overview
├── .gitignore
├── assets/
│   └── photo.png                → profile image
├── .github/
│   └── workflows/
│       ├── terraform.yml        → validate, plan, apply for infra/
│       ├── deploy-site.yml      → test, sync to S3, invalidate CloudFront
│       └── deploy-email.yml     → email DNS only, admin gated
└── infra/
    ├── iam/                      → GitHub Actions OIDC role, bootstrap manually
    │   ├── backend.tf
    │   ├── providers.tf
    │   ├── variables.tf
    │   ├── main.tf
    │   └── outputs.tf
    ├── cdn/                      → S3, CloudFront, WAF, ACM, logging, headers
    │   ├── backend.tf
    │   ├── providers.tf
    │   ├── variables.tf
    │   ├── main.tf
    │   ├── logs.tf
    │   ├── headers.tf
    │   └── outputs.tf
    └── dns/                      → Route 53 records for site and email
        ├── backend.tf
        ├── providers.tf
        ├── variables.tf
        ├── email.tf
        ├── site.tf
        └── outputs.tf
```

State buckets and lock tables (`bodytechsolutions-tfstate-iam`, `-cdn`, `-dns`) are bootstrapped once via CLI, outside of OpenTofu. See README for the commands.

## AWS architecture

The site runs entirely on serverless, managed AWS services. No EC2, no servers to patch or maintain.

```
Route 53                    → DNS for bodytechsolutions.com
  ↓
CloudFront                   → CDN, HTTPS termination, caching
  ↓ (Origin Access Control)
S3 (private bucket)          → stores index.html, css, js, assets
```

**Route 53** holds the hosted zone and all DNS records. Site records (A, www) point to CloudFront. Email records (MX, SPF, DKIM, DMARC) point to Google Workspace. Managed in `infra/dns`.

**CloudFront** is the only public entry point. It serves cached content over HTTPS, enforces TLS 1.2 minimum, and applies the WAF web ACL and security headers policy to every response. Managed in `infra/cdn`.

**S3** stores the site files but is fully private. Public access is blocked at the bucket level. Only CloudFront, through Origin Access Control, can read objects. Versioning and encryption are enabled.

**ACM** issues and renews the TLS certificate for the domain and www subdomain. Must live in us-east-1 because CloudFront requires it there regardless of where other resources are.

**WAF** sits in front of CloudFront with AWS managed rule sets for common exploits and known bad inputs, plus a rate limit rule to slow down abusive traffic.

**CloudFront access logs** write to a separate private S3 bucket, transition to cheaper storage after 30 days, and expire after 90 days.

**IAM** provides a single OIDC role that GitHub Actions assumes to deploy. No long lived AWS keys are stored anywhere. The role's permissions are scoped to only the resources this project touches.

This setup mirrors what we recommend to small business clients: a private origin, a CDN in front of it, a managed certificate, a web application firewall, and short lived credentials for deployments. It costs close to nothing at low traffic and scales automatically if traffic grows.

## Tech stack

- HTML, CSS, JavaScript for the site
- OpenTofu for infrastructure
- GitHub Actions for CI/CD
- AWS: S3, CloudFront, Route 53, ACM, WAF, IAM, DynamoDB
- Checkov and Trivy for infrastructure scanning
- Gitleaks for secret scanning
- HTML5 validator and lychee for site testing
- Google Workspace for email

## Pattern matching before changes

Before suggesting a code change or fix, look through the existing files in the relevant part of the repo first. Match the patterns already in use for that part of the stack, including naming, formatting, comment style, and structure. The goal is for changes to look like they were written by the same person who wrote the surrounding code.

## Core principles

**Best practices first.** Every change to code or infrastructure should follow current cloud native security and reliability practices. If something is the standard recommended approach for AWS, OpenTofu, or web development, default to it.

**Use existing libraries and tools.** Do not write custom code for problems that a well established library or dependency already solves. Check for an existing solution before writing new logic.

**Less code is better.** Favor the smallest amount of code that solves the problem cleanly. Avoid unnecessary abstraction or extra files.

**Small changes.** Code changes should be two to three lines whenever possible. Smaller diffs are easier to review, easier to debug, and easier to roll back. Avoid large rewrites unless explicitly requested.

## Writing style for code and comments

Avoid common AI writing patterns. Do not overuse em dashes or commas to stack ideas together. Write plain, direct sentences.

GitHub Actions workflow steps should each have a short comment explaining what the step does and why.

Comments should be professional and informative, but get to the point. Avoid overly technical or jargon heavy language where a plain explanation works just as well. Long comments should be trimmed to the essential point.

## After making changes

After any change, list out in the chat:

- Any errors found
- Any bottlenecks identified
- Any syntax issues found

This applies even if the requested change was small. Flag issues proactively rather than waiting to be asked.

## Deployment

GitHub Actions workflows are the central point of deployment. We do not deploy locally, except for the one time bootstrap of `infra/iam` and the state buckets and lock tables described in the README. Every other change goes through `terraform.yml`, `deploy-site.yml`, or `deploy-email.yml`.

## How to approach fixes

When fixing an issue, start with the least destructive option to limit the blast radius. Prefer the smallest change that resolves the problem over a broader rewrite.

Do not introduce new coding patterns or standards unless every reasonable option within the existing pattern has been considered first and none of them work. If a new pattern is genuinely the best path, explain why the existing pattern does not work before proposing it.

When proposing a fix, briefly cover the trade offs of the chosen approach. Note what is gained, what is given up, and any other approaches that were considered.

## When an error is reported

If an error is pasted into the chat, write a short plan before making any changes. Use this format, one to two sentences per section:

- **Root cause**: what is causing the error
- **Fix**: what will be changed
- **What the fix does**: the result of making that change

Then ask: "Do you want me to make changes? Yes or no"

Wait for a yes before editing any files.