import 'package:omeo_api/src/model/activity.dart';
import 'package:omeo_api/src/model/activity_input.dart';
import 'package:omeo_api/src/model/activity_overview.dart';
import 'package:omeo_api/src/model/activity_overview_balance_week_inner.dart';
import 'package:omeo_api/src/model/activity_write_result.dart';
import 'package:omeo_api/src/model/add_water201_response.dart';
import 'package:omeo_api/src/model/add_water_request.dart';
import 'package:omeo_api/src/model/add_weight201_response.dart';
import 'package:omeo_api/src/model/add_weight_request.dart';
import 'package:omeo_api/src/model/admin_badge.dart';
import 'package:omeo_api/src/model/admin_challenge.dart';
import 'package:omeo_api/src/model/admin_city.dart';
import 'package:omeo_api/src/model/admin_content_item.dart';
import 'package:omeo_api/src/model/admin_content_payload.dart';
import 'package:omeo_api/src/model/admin_content_payload_data.dart';
import 'package:omeo_api/src/model/admin_content_row.dart';
import 'package:omeo_api/src/model/admin_create_media_upload_request.dart';
import 'package:omeo_api/src/model/admin_dashboard.dart';
import 'package:omeo_api/src/model/admin_dashboard_active_users.dart';
import 'package:omeo_api/src/model/admin_dashboard_retention.dart';
import 'package:omeo_api/src/model/admin_dashboard_revenue_by_channel_inner.dart';
import 'package:omeo_api/src/model/admin_decide_approval_request.dart';
import 'package:omeo_api/src/model/admin_dish.dart';
import 'package:omeo_api/src/model/admin_estimate_audience200_response.dart';
import 'package:omeo_api/src/model/admin_exercise.dart';
import 'package:omeo_api/src/model/admin_faq.dart';
import 'package:omeo_api/src/model/admin_feedback_detail.dart';
import 'package:omeo_api/src/model/admin_feedback_row.dart';
import 'package:omeo_api/src/model/admin_feedback_stats.dart';
import 'package:omeo_api/src/model/admin_feedback_stats_by_country_inner.dart';
import 'package:omeo_api/src/model/admin_feedback_stats_by_dish_inner.dart';
import 'package:omeo_api/src/model/admin_feedback_stats_top_contested_inner.dart';
import 'package:omeo_api/src/model/admin_food.dart';
import 'package:omeo_api/src/model/admin_invite_staff_request.dart';
import 'package:omeo_api/src/model/admin_legal.dart';
import 'package:omeo_api/src/model/admin_level.dart';
import 'package:omeo_api/src/model/admin_list_approvals200_response.dart';
import 'package:omeo_api/src/model/admin_list_audit200_response.dart';
import 'package:omeo_api/src/model/admin_list_campaigns200_response.dart';
import 'package:omeo_api/src/model/admin_list_content200_response.dart';
import 'package:omeo_api/src/model/admin_list_feedback200_response.dart';
import 'package:omeo_api/src/model/admin_list_payments200_response.dart';
import 'package:omeo_api/src/model/admin_list_promo_codes200_response.dart';
import 'package:omeo_api/src/model/admin_list_reply_templates200_response_inner.dart';
import 'package:omeo_api/src/model/admin_list_revisions200_response_inner.dart';
import 'package:omeo_api/src/model/admin_list_subscriptions200_response.dart';
import 'package:omeo_api/src/model/admin_list_tickets200_response.dart';
import 'package:omeo_api/src/model/admin_list_users200_response.dart';
import 'package:omeo_api/src/model/admin_machine_translate_request.dart';
import 'package:omeo_api/src/model/admin_payment_row.dart';
import 'package:omeo_api/src/model/admin_plan.dart';
import 'package:omeo_api/src/model/admin_plant.dart';
import 'package:omeo_api/src/model/admin_point_rule.dart';
import 'package:omeo_api/src/model/admin_prevention_tip.dart';
import 'package:omeo_api/src/model/admin_program.dart';
import 'package:omeo_api/src/model/admin_program_days_inner.dart';
import 'package:omeo_api/src/model/admin_program_days_inner_tasks_inner.dart';
import 'package:omeo_api/src/model/admin_recipe.dart';
import 'package:omeo_api/src/model/admin_recipe_ingredients_inner.dart';
import 'package:omeo_api/src/model/admin_recipe_steps_inner.dart';
import 'package:omeo_api/src/model/admin_refund_payment_request.dart';
import 'package:omeo_api/src/model/admin_reply_ticket_request.dart';
import 'package:omeo_api/src/model/admin_resolve_feedback200_response.dart';
import 'package:omeo_api/src/model/admin_resolve_feedback_request.dart';
import 'package:omeo_api/src/model/admin_setup_mfa200_response.dart';
import 'package:omeo_api/src/model/admin_setup_mfa_request.dart';
import 'package:omeo_api/src/model/admin_subscription_row.dart';
import 'package:omeo_api/src/model/admin_ticket_row.dart';
import 'package:omeo_api/src/model/admin_transition_content_request.dart';
import 'package:omeo_api/src/model/admin_translation_coverage200_response_inner.dart';
import 'package:omeo_api/src/model/admin_update_staff_request.dart';
import 'package:omeo_api/src/model/admin_update_ticket_request.dart';
import 'package:omeo_api/src/model/admin_user_action_input.dart';
import 'package:omeo_api/src/model/admin_user_detail.dart';
import 'package:omeo_api/src/model/admin_user_detail_all_of_stats.dart';
import 'package:omeo_api/src/model/admin_user_health.dart';
import 'package:omeo_api/src/model/admin_user_row.dart';
import 'package:omeo_api/src/model/admin_workout.dart';
import 'package:omeo_api/src/model/admin_workout_steps_inner.dart';
import 'package:omeo_api/src/model/analysis.dart';
import 'package:omeo_api/src/model/analysis_alternative.dart';
import 'package:omeo_api/src/model/analysis_item.dart';
import 'package:omeo_api/src/model/app_config.dart';
import 'package:omeo_api/src/model/app_config_min_version.dart';
import 'package:omeo_api/src/model/app_config_store_urls.dart';
import 'package:omeo_api/src/model/app_config_trial_days.dart';
import 'package:omeo_api/src/model/app_store_notification_request.dart';
import 'package:omeo_api/src/model/app_store_purchase_input.dart';
import 'package:omeo_api/src/model/approval_request.dart';
import 'package:omeo_api/src/model/audit_entry.dart';
import 'package:omeo_api/src/model/auth_result.dart';
import 'package:omeo_api/src/model/badge_ref.dart';
import 'package:omeo_api/src/model/balance.dart';
import 'package:omeo_api/src/model/campaign.dart';
import 'package:omeo_api/src/model/campaign_input.dart';
import 'package:omeo_api/src/model/challenge_summary.dart';
import 'package:omeo_api/src/model/challenge_today.dart';
import 'package:omeo_api/src/model/change_email_request.dart';
import 'package:omeo_api/src/model/change_password_request.dart';
import 'package:omeo_api/src/model/check_challenge_day200_response.dart';
import 'package:omeo_api/src/model/check_challenge_day_request.dart';
import 'package:omeo_api/src/model/check_invite_code200_response.dart';
import 'package:omeo_api/src/model/check_invite_code_request.dart';
import 'package:omeo_api/src/model/check_program_task200_response.dart';
import 'package:omeo_api/src/model/check_program_task_request.dart';
import 'package:omeo_api/src/model/check_promo_code200_response.dart';
import 'package:omeo_api/src/model/check_promo_code_request.dart';
import 'package:omeo_api/src/model/city.dart';
import 'package:omeo_api/src/model/complete_workout_session201_response.dart';
import 'package:omeo_api/src/model/complete_workout_session_request.dart';
import 'package:omeo_api/src/model/consent_input.dart';
import 'package:omeo_api/src/model/consent_state.dart';
import 'package:omeo_api/src/model/create_analysis_request.dart';
import 'package:omeo_api/src/model/create_billing_portal201_response.dart';
import 'package:omeo_api/src/model/create_billing_portal_request.dart';
import 'package:omeo_api/src/model/create_ticket201_response.dart';
import 'package:omeo_api/src/model/create_upload_request.dart';
import 'package:omeo_api/src/model/create_web_checkout201_response.dart';
import 'package:omeo_api/src/model/create_web_checkout_request.dart';
import 'package:omeo_api/src/model/cursor_page.dart';
import 'package:omeo_api/src/model/data_export.dart';
import 'package:omeo_api/src/model/day_detail.dart';
import 'package:omeo_api/src/model/day_detail_meals_by_type_inner.dart';
import 'package:omeo_api/src/model/day_summary.dart';
import 'package:omeo_api/src/model/delete_meal200_response.dart';
import 'package:omeo_api/src/model/device_info.dart';
import 'package:omeo_api/src/model/dish_detail.dart';
import 'package:omeo_api/src/model/dish_summary.dart';
import 'package:omeo_api/src/model/duplicate_meal_request.dart';
import 'package:omeo_api/src/model/enroll_program_request.dart';
import 'package:omeo_api/src/model/enrollment.dart';
import 'package:omeo_api/src/model/entitlements.dart';
import 'package:omeo_api/src/model/exercise_detail.dart';
import 'package:omeo_api/src/model/exercise_summary.dart';
import 'package:omeo_api/src/model/feedback_input.dart';
import 'package:omeo_api/src/model/food_summary.dart';
import 'package:omeo_api/src/model/forgot_password_request.dart';
import 'package:omeo_api/src/model/gauge.dart';
import 'package:omeo_api/src/model/get_calendar200_response_inner.dart';
import 'package:omeo_api/src/model/get_workout_download200_response.dart';
import 'package:omeo_api/src/model/get_workout_download200_response_files_inner.dart';
import 'package:omeo_api/src/model/google_play_purchase_input.dart';
import 'package:omeo_api/src/model/health_connection.dart';
import 'package:omeo_api/src/model/health_sync_input.dart';
import 'package:omeo_api/src/model/health_sync_input_days_inner.dart';
import 'package:omeo_api/src/model/health_sync_input_weights_inner.dart';
import 'package:omeo_api/src/model/health_sync_input_workouts_inner.dart';
import 'package:omeo_api/src/model/home.dart';
import 'package:omeo_api/src/model/home_banners_inner.dart';
import 'package:omeo_api/src/model/home_quick_actions_inner.dart';
import 'package:omeo_api/src/model/image.dart';
import 'package:omeo_api/src/model/insight.dart';
import 'package:omeo_api/src/model/kpi_series.dart';
import 'package:omeo_api/src/model/kpi_series_series_inner.dart';
import 'package:omeo_api/src/model/legal_document.dart';
import 'package:omeo_api/src/model/legal_document_ref.dart';
import 'package:omeo_api/src/model/level_info.dart';
import 'package:omeo_api/src/model/list_activities200_response.dart';
import 'package:omeo_api/src/model/list_consents200_response.dart';
import 'package:omeo_api/src/model/list_exercises200_response.dart';
import 'package:omeo_api/src/model/list_faq200_response_inner.dart';
import 'package:omeo_api/src/model/list_faq200_response_inner_items_inner.dart';
import 'package:omeo_api/src/model/list_insights200_response.dart';
import 'package:omeo_api/src/model/list_meals200_response.dart';
import 'package:omeo_api/src/model/list_notifications200_response.dart';
import 'package:omeo_api/src/model/list_payments200_response.dart';
import 'package:omeo_api/src/model/list_plants200_response.dart';
import 'package:omeo_api/src/model/list_point_events200_response.dart';
import 'package:omeo_api/src/model/list_recipes200_response.dart';
import 'package:omeo_api/src/model/list_social_accounts200_response_inner.dart';
import 'package:omeo_api/src/model/list_workouts200_response.dart';
import 'package:omeo_api/src/model/login_request.dart';
import 'package:omeo_api/src/model/logout_request.dart';
import 'package:omeo_api/src/model/mark_notifications_read200_response.dart';
import 'package:omeo_api/src/model/mark_notifications_read_request.dart';
import 'package:omeo_api/src/model/me.dart';
import 'package:omeo_api/src/model/me_preferences.dart';
import 'package:omeo_api/src/model/me_profile.dart';
import 'package:omeo_api/src/model/meal.dart';
import 'package:omeo_api/src/model/meal_input.dart';
import 'package:omeo_api/src/model/meal_item_input.dart';
import 'package:omeo_api/src/model/meal_update.dart';
import 'package:omeo_api/src/model/meal_write_result.dart';
import 'package:omeo_api/src/model/media.dart';
import 'package:omeo_api/src/model/media_subtitles_inner.dart';
import 'package:omeo_api/src/model/merge_activity_request.dart';
import 'package:omeo_api/src/model/merge_suggestion.dart';
import 'package:omeo_api/src/model/money.dart';
import 'package:omeo_api/src/model/notification.dart';
import 'package:omeo_api/src/model/notification_preferences.dart';
import 'package:omeo_api/src/model/notification_preferences_categories.dart';
import 'package:omeo_api/src/model/notification_preferences_meal_reminder_times.dart';
import 'package:omeo_api/src/model/nutrients.dart';
import 'package:omeo_api/src/model/onboarding_profile.dart';
import 'package:omeo_api/src/model/page_meta.dart';
import 'package:omeo_api/src/model/participation.dart';
import 'package:omeo_api/src/model/participation_days_inner.dart';
import 'package:omeo_api/src/model/payment.dart';
import 'package:omeo_api/src/model/photo_analysis_input.dart';
import 'package:omeo_api/src/model/plan_catalog.dart';
import 'package:omeo_api/src/model/plan_catalog_comparison_inner.dart';
import 'package:omeo_api/src/model/plan_catalog_plans_inner.dart';
import 'package:omeo_api/src/model/plan_catalog_plans_inner_store_product_ids.dart';
import 'package:omeo_api/src/model/plant_detail.dart';
import 'package:omeo_api/src/model/plant_detail_all_of_contraindications.dart';
import 'package:omeo_api/src/model/plant_summary.dart';
import 'package:omeo_api/src/model/point_event.dart';
import 'package:omeo_api/src/model/prevention_overview.dart';
import 'package:omeo_api/src/model/problem.dart';
import 'package:omeo_api/src/model/problem_errors_value_inner.dart';
import 'package:omeo_api/src/model/profile_update.dart';
import 'package:omeo_api/src/model/program_day_view.dart';
import 'package:omeo_api/src/model/program_day_view_tasks_inner.dart';
import 'package:omeo_api/src/model/program_detail.dart';
import 'package:omeo_api/src/model/program_detail_all_of_rewards.dart';
import 'package:omeo_api/src/model/program_summary.dart';
import 'package:omeo_api/src/model/program_today.dart';
import 'package:omeo_api/src/model/progress.dart';
import 'package:omeo_api/src/model/progress_series_inner.dart';
import 'package:omeo_api/src/model/progress_summary_last7_inner.dart';
import 'package:omeo_api/src/model/promo_code.dart';
import 'package:omeo_api/src/model/put_analysis_feedback200_response.dart';
import 'package:omeo_api/src/model/quota.dart';
import 'package:omeo_api/src/model/quota_rule.dart';
import 'package:omeo_api/src/model/recipe_detail.dart';
import 'package:omeo_api/src/model/recipe_detail_all_of_ingredients.dart';
import 'package:omeo_api/src/model/recipe_detail_all_of_steps.dart';
import 'package:omeo_api/src/model/recipe_summary.dart';
import 'package:omeo_api/src/model/referral_overview.dart';
import 'package:omeo_api/src/model/referral_overview_referees_inner.dart';
import 'package:omeo_api/src/model/refresh_token_request.dart';
import 'package:omeo_api/src/model/register_push_device_request.dart';
import 'package:omeo_api/src/model/register_request.dart';
import 'package:omeo_api/src/model/request_account_deletion200_response.dart';
import 'package:omeo_api/src/model/request_account_deletion_request.dart';
import 'package:omeo_api/src/model/request_deletion_by_email_request.dart';
import 'package:omeo_api/src/model/reset_password_request.dart';
import 'package:omeo_api/src/model/restore_purchases_request.dart';
import 'package:omeo_api/src/model/reward_delta.dart';
import 'package:omeo_api/src/model/rewards_overview.dart';
import 'package:omeo_api/src/model/rewards_summary.dart';
import 'package:omeo_api/src/model/rule_def.dart';
import 'package:omeo_api/src/model/search_cities200_response.dart';
import 'package:omeo_api/src/model/search_dishes200_response.dart';
import 'package:omeo_api/src/model/search_foods200_response.dart';
import 'package:omeo_api/src/model/segment.dart';
import 'package:omeo_api/src/model/select_analysis_dish_request.dart';
import 'package:omeo_api/src/model/session.dart';
import 'package:omeo_api/src/model/set_avatar_request.dart';
import 'package:omeo_api/src/model/set_health_connection_request.dart';
import 'package:omeo_api/src/model/settings.dart';
import 'package:omeo_api/src/model/settings_ai.dart';
import 'package:omeo_api/src/model/settings_app.dart';
import 'package:omeo_api/src/model/settings_billing.dart';
import 'package:omeo_api/src/model/settings_challenges.dart';
import 'package:omeo_api/src/model/settings_four_eyes.dart';
import 'package:omeo_api/src/model/settings_notifications.dart';
import 'package:omeo_api/src/model/settings_nutrition.dart';
import 'package:omeo_api/src/model/settings_nutrition_min_kcal.dart';
import 'package:omeo_api/src/model/settings_referral.dart';
import 'package:omeo_api/src/model/settings_trial.dart';
import 'package:omeo_api/src/model/social_auth_request.dart';
import 'package:omeo_api/src/model/staff_member.dart';
import 'package:omeo_api/src/model/step_up_mfa200_response.dart';
import 'package:omeo_api/src/model/step_up_mfa_request.dart';
import 'package:omeo_api/src/model/subscription_state.dart';
import 'package:omeo_api/src/model/subscription_state_subscription.dart';
import 'package:omeo_api/src/model/sync_health200_response.dart';
import 'package:omeo_api/src/model/targets.dart';
import 'package:omeo_api/src/model/text_analysis_input.dart';
import 'package:omeo_api/src/model/ticket_detail.dart';
import 'package:omeo_api/src/model/ticket_detail_all_of_messages.dart';
import 'package:omeo_api/src/model/ticket_input.dart';
import 'package:omeo_api/src/model/ticket_input_meta.dart';
import 'package:omeo_api/src/model/ticket_summary.dart';
import 'package:omeo_api/src/model/tokens.dart';
import 'package:omeo_api/src/model/update_consents_request.dart';
import 'package:omeo_api/src/model/update_user_tip_request.dart';
import 'package:omeo_api/src/model/upload_ticket.dart';
import 'package:omeo_api/src/model/user_badge.dart';
import 'package:omeo_api/src/model/user_tip.dart';
import 'package:omeo_api/src/model/verify_email_request.dart';
import 'package:omeo_api/src/model/verify_mfa_request.dart';
import 'package:omeo_api/src/model/verify_store_purchase_request.dart';
import 'package:omeo_api/src/model/water.dart';
import 'package:omeo_api/src/model/week_day.dart';
import 'package:omeo_api/src/model/weight_overview.dart';
import 'package:omeo_api/src/model/weight_overview_series_inner.dart';
import 'package:omeo_api/src/model/workout_detail.dart';
import 'package:omeo_api/src/model/workout_detail_all_of_steps.dart';
import 'package:omeo_api/src/model/workout_summary.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

ReturnType deserialize<ReturnType, BaseType>(
  dynamic value,
  String targetType, {
  bool growable = true,
}) {
  switch (targetType) {
    case 'String':
      return '$value' as ReturnType;
    case 'int':
      return (value is int ? value : int.parse('$value')) as ReturnType;
    case 'bool':
      if (value is bool) {
        return value as ReturnType;
      }
      final valueString = '$value'.toLowerCase();
      return (valueString == 'true' || valueString == '1') as ReturnType;
    case 'double':
      return (value is double ? value : double.parse('$value')) as ReturnType;
    case 'Activity':
      return Activity.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ActivityInput':
      return ActivityInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ActivityOverview':
      return ActivityOverview.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ActivityOverviewBalanceWeekInner':
      return ActivityOverviewBalanceWeekInner.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'ActivityWriteResult':
      return ActivityWriteResult.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AddWater201Response':
      return AddWater201Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AddWaterRequest':
      return AddWaterRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AddWeight201Response':
      return AddWeight201Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AddWeightRequest':
      return AddWeightRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminBadge':
      return AdminBadge.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AdminChallenge':
      return AdminChallenge.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminCity':
      return AdminCity.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AdminContentItem':
      return AdminContentItem.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminContentPayload':
      return AdminContentPayload.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminContentPayloadData':
      return AdminContentPayloadData.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminContentRow':
      return AdminContentRow.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminCreateMediaUploadRequest':
      return AdminCreateMediaUploadRequest.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminDashboard':
      return AdminDashboard.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminDashboardActiveUsers':
      return AdminDashboardActiveUsers.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminDashboardRetention':
      return AdminDashboardRetention.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminDashboardRevenueByChannelInner':
      return AdminDashboardRevenueByChannelInner.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminDecideApprovalRequest':
      return AdminDecideApprovalRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminDish':
      return AdminDish.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AdminEstimateAudience200Response':
      return AdminEstimateAudience200Response.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminExercise':
      return AdminExercise.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminFaq':
      return AdminFaq.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AdminFeedbackDetail':
      return AdminFeedbackDetail.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminFeedbackRow':
      return AdminFeedbackRow.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminFeedbackStats':
      return AdminFeedbackStats.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminFeedbackStatsByCountryInner':
      return AdminFeedbackStatsByCountryInner.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminFeedbackStatsByDishInner':
      return AdminFeedbackStatsByDishInner.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminFeedbackStatsTopContestedInner':
      return AdminFeedbackStatsTopContestedInner.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminFood':
      return AdminFood.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AdminInviteStaffRequest':
      return AdminInviteStaffRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminLegal':
      return AdminLegal.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AdminLevel':
      return AdminLevel.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AdminListApprovals200Response':
      return AdminListApprovals200Response.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminListAudit200Response':
      return AdminListAudit200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminListCampaigns200Response':
      return AdminListCampaigns200Response.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminListContent200Response':
      return AdminListContent200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminListFeedback200Response':
      return AdminListFeedback200Response.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminListPayments200Response':
      return AdminListPayments200Response.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminListPromoCodes200Response':
      return AdminListPromoCodes200Response.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminListReplyTemplates200ResponseInner':
      return AdminListReplyTemplates200ResponseInner.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminListRevisions200ResponseInner':
      return AdminListRevisions200ResponseInner.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminListSubscriptions200Response':
      return AdminListSubscriptions200Response.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminListTickets200Response':
      return AdminListTickets200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminListUsers200Response':
      return AdminListUsers200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminMachineTranslateRequest':
      return AdminMachineTranslateRequest.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminPaymentRow':
      return AdminPaymentRow.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminPlan':
      return AdminPlan.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AdminPlant':
      return AdminPlant.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AdminPointRule':
      return AdminPointRule.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminPreventionTip':
      return AdminPreventionTip.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminProgram':
      return AdminProgram.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AdminProgramDaysInner':
      return AdminProgramDaysInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminProgramDaysInnerTasksInner':
      return AdminProgramDaysInnerTasksInner.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminRecipe':
      return AdminRecipe.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AdminRecipeIngredientsInner':
      return AdminRecipeIngredientsInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminRecipeStepsInner':
      return AdminRecipeStepsInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminRefundPaymentRequest':
      return AdminRefundPaymentRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminReplyTicketRequest':
      return AdminReplyTicketRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminResolveFeedback200Response':
      return AdminResolveFeedback200Response.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminResolveFeedbackRequest':
      return AdminResolveFeedbackRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminSetupMfa200Response':
      return AdminSetupMfa200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminSetupMfaRequest':
      return AdminSetupMfaRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminSubscriptionRow':
      return AdminSubscriptionRow.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminTicketRow':
      return AdminTicketRow.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminTransitionContentRequest':
      return AdminTransitionContentRequest.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminTranslationCoverage200ResponseInner':
      return AdminTranslationCoverage200ResponseInner.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdminUpdateStaffRequest':
      return AdminUpdateStaffRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminUpdateTicketRequest':
      return AdminUpdateTicketRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminUserActionInput':
      return AdminUserActionInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminUserDetail':
      return AdminUserDetail.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminUserDetailAllOfStats':
      return AdminUserDetailAllOfStats.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminUserHealth':
      return AdminUserHealth.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminUserRow':
      return AdminUserRow.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AdminWorkout':
      return AdminWorkout.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AdminWorkoutStepsInner':
      return AdminWorkoutStepsInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Analysis':
      return Analysis.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AnalysisAlternative':
      return AnalysisAlternative.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AnalysisItem':
      return AnalysisItem.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AppConfig':
      return AppConfig.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AppConfigMinVersion':
      return AppConfigMinVersion.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AppConfigStoreUrls':
      return AppConfigStoreUrls.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AppConfigTrialDays':
      return AppConfigTrialDays.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AppStoreNotificationRequest':
      return AppStoreNotificationRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AppStorePurchaseInput':
      return AppStorePurchaseInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ApprovalRequest':
      return ApprovalRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AuditEntry':
      return AuditEntry.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AuthResult':
      return AuthResult.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'BadgeRef':
      return BadgeRef.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Balance':
      return Balance.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Campaign':
      return Campaign.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CampaignInput':
      return CampaignInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ChallengeSummary':
      return ChallengeSummary.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ChallengeToday':
      return ChallengeToday.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ChangeEmailRequest':
      return ChangeEmailRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ChangePasswordRequest':
      return ChangePasswordRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Channel':
    case 'CheckChallengeDay200Response':
      return CheckChallengeDay200Response.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'CheckChallengeDayRequest':
      return CheckChallengeDayRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CheckInviteCode200Response':
      return CheckInviteCode200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CheckInviteCodeRequest':
      return CheckInviteCodeRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CheckProgramTask200Response':
      return CheckProgramTask200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CheckProgramTaskRequest':
      return CheckProgramTaskRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CheckPromoCode200Response':
      return CheckPromoCode200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CheckPromoCodeRequest':
      return CheckPromoCodeRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'City':
      return City.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'CompleteWorkoutSession201Response':
      return CompleteWorkoutSession201Response.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'CompleteWorkoutSessionRequest':
      return CompleteWorkoutSessionRequest.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'ConsentInput':
      return ConsentInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ConsentKind':
    case 'ConsentState':
      return ConsentState.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ContentStatus':
    case 'ContentTypeName':
    case 'CreateAnalysisRequest':
      return CreateAnalysisRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CreateBillingPortal201Response':
      return CreateBillingPortal201Response.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'CreateBillingPortalRequest':
      return CreateBillingPortalRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CreateTicket201Response':
      return CreateTicket201Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CreateUploadRequest':
      return CreateUploadRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CreateWebCheckout201Response':
      return CreateWebCheckout201Response.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'CreateWebCheckoutRequest':
      return CreateWebCheckoutRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CursorPage':
      return CursorPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'DataExport':
      return DataExport.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'DayDetail':
      return DayDetail.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'DayDetailMealsByTypeInner':
      return DayDetailMealsByTypeInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'DaySummary':
      return DaySummary.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'DeleteMeal200Response':
      return DeleteMeal200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'DeviceInfo':
      return DeviceInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'DishDetail':
      return DishDetail.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'DishSummary':
      return DishSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'DuplicateMealRequest':
      return DuplicateMealRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'EnrollProgramRequest':
      return EnrollProgramRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Enrollment':
      return Enrollment.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Entitlements':
      return Entitlements.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ExerciseDetail':
      return ExerciseDetail.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ExerciseSummary':
      return ExerciseSummary.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'FeedbackInput':
      return FeedbackInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'FeedbackReason':
    case 'FoodSummary':
      return FoodSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ForgotPasswordRequest':
      return ForgotPasswordRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Gauge':
      return Gauge.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'GetCalendar200ResponseInner':
      return GetCalendar200ResponseInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'GetWorkoutDownload200Response':
      return GetWorkoutDownload200Response.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'GetWorkoutDownload200ResponseFilesInner':
      return GetWorkoutDownload200ResponseFilesInner.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'Goal':
    case 'GooglePlayPurchaseInput':
      return GooglePlayPurchaseInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HealthConnection':
      return HealthConnection.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HealthSyncInput':
      return HealthSyncInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HealthSyncInputDaysInner':
      return HealthSyncInputDaysInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HealthSyncInputWeightsInner':
      return HealthSyncInputWeightsInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HealthSyncInputWorkoutsInner':
      return HealthSyncInputWorkoutsInner.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'Home':
      return Home.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'HomeBannersInner':
      return HomeBannersInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HomeQuickActionsInner':
      return HomeQuickActionsInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Image':
      return Image.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Insight':
      return Insight.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'KpiSeries':
      return KpiSeries.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'KpiSeriesSeriesInner':
      return KpiSeriesSeriesInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LegalDocument':
      return LegalDocument.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LegalDocumentRef':
      return LegalDocumentRef.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LegalKind':
    case 'Level':
    case 'LevelInfo':
      return LevelInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ListActivities200Response':
      return ListActivities200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ListConsents200Response':
      return ListConsents200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ListExercises200Response':
      return ListExercises200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ListFaq200ResponseInner':
      return ListFaq200ResponseInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ListFaq200ResponseInnerItemsInner':
      return ListFaq200ResponseInnerItemsInner.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'ListInsights200Response':
      return ListInsights200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ListMeals200Response':
      return ListMeals200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ListNotifications200Response':
      return ListNotifications200Response.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'ListPayments200Response':
      return ListPayments200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ListPlants200Response':
      return ListPlants200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ListPointEvents200Response':
      return ListPointEvents200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ListRecipes200Response':
      return ListRecipes200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ListSocialAccounts200ResponseInner':
      return ListSocialAccounts200ResponseInner.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'ListWorkouts200Response':
      return ListWorkouts200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Locale':
    case 'LoginRequest':
      return LoginRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'LogoutRequest':
      return LogoutRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'MarkNotificationsRead200Response':
      return MarkNotificationsRead200Response.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'MarkNotificationsReadRequest':
      return MarkNotificationsReadRequest.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'Me':
      return Me.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'MePreferences':
      return MePreferences.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'MeProfile':
      return MeProfile.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Meal':
      return Meal.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'MealInput':
      return MealInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'MealItemInput':
      return MealItemInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'MealType':
    case 'MealUpdate':
      return MealUpdate.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'MealWriteResult':
      return MealWriteResult.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Media':
      return Media.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'MediaSubtitlesInner':
      return MediaSubtitlesInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'MergeActivityRequest':
      return MergeActivityRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'MergeSuggestion':
      return MergeSuggestion.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Money':
      return Money.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Notification':
      return Notification.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'NotificationPreferences':
      return NotificationPreferences.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'NotificationPreferencesCategories':
      return NotificationPreferencesCategories.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'NotificationPreferencesMealReminderTimes':
      return NotificationPreferencesMealReminderTimes.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'Nutrients':
      return Nutrients.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'OnboardingProfile':
      return OnboardingProfile.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PageMeta':
      return PageMeta.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Participation':
      return Participation.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ParticipationDaysInner':
      return ParticipationDaysInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Payment':
      return Payment.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PhotoAnalysisInput':
      return PhotoAnalysisInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PlanCatalog':
      return PlanCatalog.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PlanCatalogComparisonInner':
      return PlanCatalogComparisonInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PlanCatalogPlansInner':
      return PlanCatalogPlansInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PlanCatalogPlansInnerStoreProductIds':
      return PlanCatalogPlansInnerStoreProductIds.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'PlanTier':
    case 'PlantDetail':
      return PlantDetail.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PlantDetailAllOfContraindications':
      return PlantDetailAllOfContraindications.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'PlantSummary':
      return PlantSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PointEvent':
      return PointEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PreventionOverview':
      return PreventionOverview.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Problem':
      return Problem.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ProblemErrorsValueInner':
      return ProblemErrorsValueInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProfileUpdate':
      return ProfileUpdate.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProgramDayView':
      return ProgramDayView.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProgramDayViewTasksInner':
      return ProgramDayViewTasksInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProgramDetail':
      return ProgramDetail.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProgramDetailAllOfRewards':
      return ProgramDetailAllOfRewards.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProgramSummary':
      return ProgramSummary.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProgramToday':
      return ProgramToday.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'Progress':
      return Progress.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ProgressSeriesInner':
      return ProgressSeriesInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProgressSummaryLast7Inner':
      return ProgressSummaryLast7Inner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PromoCode':
      return PromoCode.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PutAnalysisFeedback200Response':
      return PutAnalysisFeedback200Response.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'Quota':
      return Quota.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'QuotaRule':
      return QuotaRule.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'RecipeDetail':
      return RecipeDetail.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'RecipeDetailAllOfIngredients':
      return RecipeDetailAllOfIngredients.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'RecipeDetailAllOfSteps':
      return RecipeDetailAllOfSteps.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RecipeSummary':
      return RecipeSummary.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReferralOverview':
      return ReferralOverview.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReferralOverviewRefereesInner':
      return ReferralOverviewRefereesInner.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'RefreshTokenRequest':
      return RefreshTokenRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RegisterPushDeviceRequest':
      return RegisterPushDeviceRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RegisterRequest':
      return RegisterRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RequestAccountDeletion200Response':
      return RequestAccountDeletion200Response.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'RequestAccountDeletionRequest':
      return RequestAccountDeletionRequest.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'RequestDeletionByEmailRequest':
      return RequestDeletionByEmailRequest.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'ResetPasswordRequest':
      return ResetPasswordRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RestorePurchasesRequest':
      return RestorePurchasesRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RewardDelta':
      return RewardDelta.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'RewardsOverview':
      return RewardsOverview.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RewardsSummary':
      return RewardsSummary.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RuleDef':
      return RuleDef.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SearchCities200Response':
      return SearchCities200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SearchDishes200Response':
      return SearchDishes200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SearchFoods200Response':
      return SearchFoods200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Segment':
      return Segment.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SelectAnalysisDishRequest':
      return SelectAnalysisDishRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Session':
      return Session.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SetAvatarRequest':
      return SetAvatarRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SetHealthConnectionRequest':
      return SetHealthConnectionRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Settings':
      return Settings.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SettingsAi':
      return SettingsAi.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SettingsApp':
      return SettingsApp.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SettingsBilling':
      return SettingsBilling.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SettingsChallenges':
      return SettingsChallenges.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SettingsFourEyes':
      return SettingsFourEyes.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SettingsNotifications':
      return SettingsNotifications.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SettingsNutrition':
      return SettingsNutrition.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SettingsNutritionMinKcal':
      return SettingsNutritionMinKcal.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SettingsReferral':
      return SettingsReferral.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SettingsTrial':
      return SettingsTrial.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Sex':
    case 'SocialAuthRequest':
      return SocialAuthRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'StaffMember':
      return StaffMember.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'StaffRole':
    case 'StepUpMfa200Response':
      return StepUpMfa200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'StepUpMfaRequest':
      return StepUpMfaRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionState':
      return SubscriptionState.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubscriptionStateSubscription':
      return SubscriptionStateSubscription.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'SubscriptionStatus':
    case 'SyncHealth200Response':
      return SyncHealth200Response.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Targets':
      return Targets.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TextAnalysisInput':
      return TextAnalysisInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TicketCategory':
    case 'TicketDetail':
      return TicketDetail.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TicketDetailAllOfMessages':
      return TicketDetailAllOfMessages.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TicketInput':
      return TicketInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TicketInputMeta':
      return TicketInputMeta.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TicketStatus':
    case 'TicketSummary':
      return TicketSummary.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Tokens':
      return Tokens.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'UpdateConsentsRequest':
      return UpdateConsentsRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'UpdateUserTipRequest':
      return UpdateUserTipRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'UploadTicket':
      return UploadTicket.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'UserBadge':
      return UserBadge.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'UserTip':
      return UserTip.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'VerifyEmailRequest':
      return VerifyEmailRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VerifyMfaRequest':
      return VerifyMfaRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VerifyStorePurchaseRequest':
      return VerifyStorePurchaseRequest.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'Water':
      return Water.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'WeekDay':
      return WeekDay.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'WeightOverview':
      return WeightOverview.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'WeightOverviewSeriesInner':
      return WeightOverviewSeriesInner.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'WorkoutDetail':
      return WorkoutDetail.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'WorkoutDetailAllOfSteps':
      return WorkoutDetailAllOfSteps.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'WorkoutSummary':
      return WorkoutSummary.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    default:
      RegExpMatch? match;

      if (value is List && (match = _regList.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
                .map<BaseType>(
                  (dynamic v) => deserialize<BaseType, BaseType>(
                    v,
                    targetType,
                    growable: growable,
                  ),
                )
                .toList(growable: growable)
            as ReturnType;
      }
      if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
                .map<BaseType>(
                  (dynamic v) => deserialize<BaseType, BaseType>(
                    v,
                    targetType,
                    growable: growable,
                  ),
                )
                .toSet()
            as ReturnType;
      }
      if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
        targetType = match![1]!.trim(); // ignore: parameter_assignments
        return Map<String, BaseType>.fromIterables(
              value.keys as Iterable<String>,
              value.values.map(
                (dynamic v) => deserialize<BaseType, BaseType>(
                  v,
                  targetType,
                  growable: growable,
                ),
              ),
            )
            as ReturnType;
      }
      break;
  }
  throw Exception('Cannot deserialize');
}
