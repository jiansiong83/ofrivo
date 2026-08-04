# UI Specification

## Direction

Reliable, clear, professional, local, safe, and simple. Use a mobile-first card layout with comfortable spacing, readable text, and restrained motion. Avoid excessive gradients, game-like patterns, dense tiny type, and financial-trading visual language.

## Tokens

| Token | Value | Use |
|---|---|---|
| Primary | `#0B4F55` | Brand actions, app bar, active navigation |
| Secondary | `#2563EB` | Supporting actions and links |
| Background | `#F5F7F8` | App canvas |
| Surface | `#FFFFFF` | Cards and forms |
| Success | `#15803D` | Open/verified/completed feedback |
| Warning | `#C2410C` | Pending/urgent feedback |
| Danger | `#B42318` | Cancelled/rejected/destructive actions |
| Text primary | `#172126` | Main copy |
| Text secondary | `#5B6870` | Supporting copy |

## Layout

- 8 px spacing base; common sections use 16–24 px.
- Cards use 16 px radius and a 1 px low-contrast border.
- Primary tap targets are at least 48 px high.
- Use Material 3 typography and platform-safe contrast.

## Shared components

`AppScaffold`, `PrimaryButton`, `SecondaryButton`, `DangerButton`, `JobCard`, `BidCard`, `ProviderCard`, `StatusBadge`, `VerifiedBadge`, `CategoryChip`, `AreaChip`, `BudgetInput`, `DateTimeSelector`, `PhotoUploader`, `ProfileAvatar`, `RatingSummary`, `EmptyState`, `ErrorState`, `LoadingSkeleton`, `ConfirmationDialog`, `ReportDialog`, and `FilterBottomSheet`.

## Required states

Loading, empty, error, offline, permission denied, account suspended, verification pending/rejected, no bids, expired job, withdrawn bid, already-assigned job, upload failure, and retry must be expressible without changing the visual language.

