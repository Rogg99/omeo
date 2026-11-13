"""Routes admin de billing (préfixe /api/v1)."""

from __future__ import annotations

from django.urls import path

from apps.billing.admin_api import views

urlpatterns = [
    path("admin/plans", views.PlansView.as_view()),
    path("admin/plans/<str:code>", views.PlanDetailView.as_view()),
    path("admin/quotas", views.QuotasView.as_view()),
    path("admin/subscriptions", views.SubscriptionsView.as_view()),
    path("admin/payments", views.PaymentsView.as_view()),
    path("admin/payments/<uuid:id>/refund", views.RefundView.as_view()),
    path("admin/promo-codes", views.PromoCodesView.as_view()),
    path("admin/promo-codes/<uuid:id>", views.PromoCodeDetailView.as_view()),
]
