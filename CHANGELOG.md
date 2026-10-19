# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-10-04

### Added
- **Customer Web & Mobile Portals**: Online service booking, slot selection, vehicle management, and promotional code application.
- **Admin Dashboard**: Secure dual-port workshop management (port 8081) with service bay tracking, mechanic assignments, walk-in customer support, and billing invoice generation.
- **Real-Time Communication**: In-app live chat between vehicle owners and assigned service technicians using Supabase Realtime and WebSockets.
- **Push Notifications**: Firebase Cloud Messaging (FCM) integration for mobile and web appointment alerts and status updates.
- **Payment Processing**: Integrated PayHere checkout for secure online service payments.
- **Database Migrations**: Flyway migration pipeline supporting Supabase PostgreSQL with idempotent schema management.
- **Cloud Infrastructure**: Zero-downtime Docker container deployment on AWS EC2, distributed globally via AWS CloudFront with HTTPS/TLS encryption.
- **CI/CD Automation**: GitHub Actions workflow for automated test execution, Docker image publishing to GHCR, and server deployment.
