# bodytechsolutions.com

Public website for [Body Technology Solutions](https://bodytechsolutions.com) — a cloud and Kubernetes technical consultancy based in Charlotte, NC.

Built and self-hosted on AWS as a working example of the infrastructure we deliver for clients.

## Stack

- HTML / CSS — static site, no framework
- AWS S3 — file storage
- AWS CloudFront — CDN and HTTPS
- AWS Route 53 — DNS
- AWS ACM — SSL certificate
- OpenTofu — infrastructure as code

## Structure

```
index.html                        → main site
sitemap.xml                       → search engine sitemap
robots.txt                        → crawler rules
README.md                         → this file
assets/
  photo.png                       → profile image
infra/
  main.tf                         → S3, CloudFront, Route 53, ACM
  variables.tf                    → input variables
  outputs.tf                      → stack outputs
  providers.tf                    → AWS provider config
.github/
  workflows/
    deploy.yml                    → GitHub Actions deploy to S3 + CloudFront invalidation
```

---

© 2026 Body Technology Solutions LLC. All rights reserved.