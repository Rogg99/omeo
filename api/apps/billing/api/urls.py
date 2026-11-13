"""Routes de billing (préfixe /api/v1)."""

from __future__ import annotations

from django.urls import path

from apps.billing.api import views

urlpatterns = [
    path("billing/plans", views.PlansView.as_view()),
    path("me/subscription", views.SubscriptionView.as_view()),
    path("me/subscription/verify", views.VerifyPurchaseView.as_view()),
    path("me/subscription/restore", views.RestoreView.as_view()),
    path("me/payments", views.PaymentsView.as_view()),
    path("me/billing/checkout", views.CheckoutView.as_view()),
    path("me/billing/promo-check", views.PromoCheckView.as_view()),
    path("me/billing/portal", views.PortalView.as_view()),
    path("me/referral", views.ReferralView.as_view()),
    path("webhooks/google-play", views.GooglePlayWebhookView.as_view()),
    path("webhooks/app-store", views.AppStoreWebhookView.as_view()),
    path("webhooks/payments", views.PaymentsWebhookView.as_view()),
]
