-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Mar 30, 2026 at 05:35 AM
-- Server version: 10.6.22-MariaDB-0ubuntu0.22.04.1
-- PHP Version: 8.1.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `appsocial`
--

-- --------------------------------------------------------

--
-- Table structure for table `admin_roles`
--

CREATE TABLE `admin_roles` (
  `id` int(11) NOT NULL,
  `admin_type` enum('admin','member') NOT NULL,
  `routes` longtext NOT NULL COMMENT 'ACCESS_DENIED_MODULES'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `agent_llm_config`
--

CREATE TABLE `agent_llm_config` (
  `id` int(11) NOT NULL,
  `agent_name` varchar(100) NOT NULL,
  `provider` varchar(50) DEFAULT NULL,
  `model_name` varchar(100) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `bot_setting`
--

CREATE TABLE `bot_setting` (
  `id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `quick_reply_buttons` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`quick_reply_buttons`)),
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `welcome_heading` varchar(255) DEFAULT NULL,
  `show_exact_prices` tinyint(1) NOT NULL DEFAULT 1,
  `show_stock_levels` tinyint(1) NOT NULL DEFAULT 0,
  `product_recommendations` tinyint(1) NOT NULL DEFAULT 1,
  `proactive_discount_sharing` tinyint(1) NOT NULL DEFAULT 1,
  `discount_exclusions` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`discount_exclusions`)),
  `include_new_discounts` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `brands`
--

CREATE TABLE `brands` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(191) NOT NULL,
  `status` tinyint(4) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `broadcasts`
--

CREATE TABLE `broadcasts` (
  `id` varchar(36) NOT NULL,
  `campaign_name` varchar(200) NOT NULL,
  `template_name` varchar(200) DEFAULT NULL,
  `template_language` varchar(10) DEFAULT 'en',
  `template_category` varchar(20) DEFAULT NULL COMMENT 'Marketing, Utility, Authentication',
  `status` varchar(20) NOT NULL DEFAULT 'draft' COMMENT 'draft, scheduled, sending, sent, failed, cancelled',
  `audience_type` varchar(20) NOT NULL DEFAULT 'all' COMMENT 'all, segment, csv',
  `segment_id` varchar(36) DEFAULT NULL,
  `csv_file_id` varchar(36) DEFAULT NULL,
  `audience_label` varchar(200) DEFAULT NULL COMMENT 'Human-readable audience description',
  `recipient_count` int(11) DEFAULT 0,
  `schedule_type` varchar(20) DEFAULT 'now' COMMENT 'now, schedule',
  `scheduled_at` datetime DEFAULT NULL,
  `timezone` varchar(50) DEFAULT NULL,
  `sent_at` datetime DEFAULT NULL,
  `template_variables` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Key-value map for template {{variables}}' CHECK (json_valid(`template_variables`)),
  `estimated_cost` decimal(10,2) DEFAULT NULL,
  `actual_cost` decimal(10,2) DEFAULT NULL,
  `message_preview` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Cached preview data for detail page' CHECK (json_valid(`message_preview`)),
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='WhatsApp broadcast campaigns';

-- --------------------------------------------------------

--
-- Table structure for table `broadcast_recipients`
--

CREATE TABLE `broadcast_recipients` (
  `id` varchar(36) NOT NULL,
  `broadcast_id` varchar(36) NOT NULL,
  `contact_id` varchar(36) DEFAULT NULL COMMENT 'NULL for CSV-uploaded contacts not in contacts table',
  `phone` varchar(20) NOT NULL,
  `meta_message_id` varchar(100) DEFAULT NULL COMMENT 'WhatsApp message ID from Meta API',
  `status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT 'pending, sent, delivered, read, replied, failed',
  `error_code` varchar(50) DEFAULT NULL,
  `error_message` text DEFAULT NULL,
  `sent_at` datetime DEFAULT NULL,
  `delivered_at` datetime DEFAULT NULL,
  `read_at` datetime DEFAULT NULL,
  `replied_at` datetime DEFAULT NULL,
  `failed_at` datetime DEFAULT NULL,
  `country_code` varchar(5) DEFAULT NULL COMMENT 'ISO 3166-1 alpha-2 for cost calculation',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Per-recipient delivery tracking for broadcasts';

-- --------------------------------------------------------

--
-- Table structure for table `channel_settings`
--

CREATE TABLE `channel_settings` (
  `id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `channel_id` int(11) DEFAULT NULL,
  `channel_type` int(11) NOT NULL,
  `messenger_reply_enabled` tinyint(1) DEFAULT NULL,
  `comment_reply_enabled` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `chat_categories`
--

CREATE TABLE `chat_categories` (
  `id` int(11) NOT NULL,
  `category_name` varchar(255) DEFAULT NULL,
  `message` text DEFAULT NULL,
  `company_id` int(12) DEFAULT NULL,
  `user_id` int(12) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `company_addons`
--

CREATE TABLE `company_addons` (
  `id` int(11) NOT NULL,
  `company_id` bigint(20) NOT NULL,
  `addon_id` varchar(50) NOT NULL,
  `status` varchar(20) DEFAULT 'active',
  `stripe_item_id` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `company_billing_info`
--

CREATE TABLE `company_billing_info` (
  `id` int(11) NOT NULL,
  `company_id` bigint(20) NOT NULL,
  `company_name` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `tax_id` varchar(100) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `company_credits`
--

CREATE TABLE `company_credits` (
  `id` int(11) NOT NULL,
  `company_id` bigint(20) NOT NULL,
  `credit_type` varchar(50) NOT NULL DEFAULT 'ai_responses',
  `credit_pack_id` int(11) DEFAULT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `balance` int(11) NOT NULL DEFAULT 0,
  `mode` varchar(20) DEFAULT 'onetime',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `company_onboarding`
--

CREATE TABLE `company_onboarding` (
  `id` int(10) UNSIGNED NOT NULL,
  `company_id` int(10) UNSIGNED NOT NULL,
  `pageblog` tinyint(3) UNSIGNED NOT NULL DEFAULT 1,
  `settings` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `testai` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `widget` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `active` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `shopify_initial_sync` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `company_roles`
--

CREATE TABLE `company_roles` (
  `id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT '',
  `hierarchy_level` int(11) NOT NULL DEFAULT 50,
  `is_system` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `company_subscriptions`
--

CREATE TABLE `company_subscriptions` (
  `id` int(11) NOT NULL,
  `company_id` bigint(20) NOT NULL,
  `plan_id` varchar(50) NOT NULL,
  `intended_plan_id` varchar(50) DEFAULT NULL,
  `billing_cycle` varchar(20) DEFAULT 'monthly',
  `status` enum('active','cancelled','past_due','frozen','declined','expired','pending') DEFAULT 'active',
  `billing_provider` varchar(20) DEFAULT NULL,
  `stripe_subscription_id` varchar(255) DEFAULT NULL,
  `stripe_customer_id` varchar(255) DEFAULT NULL,
  `shopify_charge_id` varchar(255) DEFAULT NULL,
  `plan_credits_limit` int(11) DEFAULT 0,
  `plan_credits_used` int(11) DEFAULT 0,
  `current_period_start` datetime DEFAULT NULL,
  `current_period_end` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_trial` tinyint(1) DEFAULT 0,
  `trial_ends_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `company_type`
--

CREATE TABLE `company_type` (
  `id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `company_type` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `chat_tone` varchar(255) DEFAULT 'Friendly',
  `chat_style` varchar(255) DEFAULT 'Neutral',
  `intent_json_path` varchar(255) DEFAULT NULL,
  `custom_instructions` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `contacts`
--

CREATE TABLE `contacts` (
  `id` int(11) NOT NULL,
  `sender_id` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `unique_key` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `last_login` datetime DEFAULT NULL,
  `company_id` bigint(20) DEFAULT NULL,
  `last_message` varchar(255) DEFAULT NULL,
  `response_enabled` tinyint(1) DEFAULT 1,
  `conversation_type` int(11) NOT NULL DEFAULT 0 COMMENT 'web=0\r\nfb=1\r\nTel = 2\r\ninsta = 3\r\nwaba = 4\r\nGmail = 5',
  `alert` int(11) DEFAULT 0,
  `profile_pic` varchar(1024) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `self_learn_alert` int(11) DEFAULT NULL,
  `cost` decimal(10,4) DEFAULT 0.0000,
  `phone` varchar(150) DEFAULT NULL,
  `source_page_url` varchar(255) DEFAULT NULL,
  `ask_operator` tinyint(1) NOT NULL DEFAULT 0,
  `chat_category_id` int(11) DEFAULT 0,
  `member_id` int(11) DEFAULT NULL,
  `is_ticket` tinyint(1) DEFAULT 0 COMMENT '0=No, 1=Yes',
  `avg_agent_time` float DEFAULT NULL,
  `user_rating` int(11) DEFAULT 0 COMMENT '0=No rating, 1=Bad, 5=Excellent',
  `has_replied` tinyint(1) DEFAULT 0 COMMENT '0=No, 1=Yes',
  `data_collected` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT json_object() CHECK (json_valid(`data_collected`)),
  `active_expiry` datetime DEFAULT NULL,
  `channel_id` int(11) DEFAULT NULL,
  `contract` text DEFAULT NULL,
  `channels` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`channels`)),
  `tags` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`tags`)),
  `country_code` varchar(10) DEFAULT NULL,
  `source` varchar(255) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `contacts_geo`
--

CREATE TABLE `contacts_geo` (
  `id` int(11) NOT NULL,
  `city` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `ip_address` varchar(255) DEFAULT NULL,
  `device` varchar(255) DEFAULT NULL,
  `browser` varchar(255) DEFAULT NULL,
  `contact_id` int(11) NOT NULL,
  `latitude` varchar(255) DEFAULT '',
  `longitude` varchar(255) DEFAULT '',
  `os` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `contact_channels`
--

CREATE TABLE `contact_channels` (
  `id` varchar(36) NOT NULL,
  `contact_id` varchar(36) NOT NULL,
  `company_id` bigint(20) NOT NULL DEFAULT 0,
  `channel` varchar(50) NOT NULL,
  `identifier` varchar(255) DEFAULT NULL,
  `opted_in` tinyint(1) DEFAULT 0,
  `opted_in_at` datetime DEFAULT NULL,
  `opted_out_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `contact_company_data`
--

CREATE TABLE `contact_company_data` (
  `id` int(11) NOT NULL,
  `contact_id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`data`)),
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `contact_messages`
--

CREATE TABLE `contact_messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(191) NOT NULL,
  `email` varchar(191) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `subject` varchar(191) DEFAULT NULL,
  `message` tinytext DEFAULT NULL,
  `status` tinyint(4) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `contact_tags`
--

CREATE TABLE `contact_tags` (
  `id` int(11) NOT NULL,
  `contact_id` int(11) NOT NULL,
  `company_id` bigint(20) NOT NULL,
  `tag_id` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `crawlai_extracted_data`
--

CREATE TABLE `crawlai_extracted_data` (
  `session_id` varchar(100) NOT NULL,
  `skey` varchar(255) DEFAULT NULL,
  `chunk_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`chunk_ids`)),
  `created_at` datetime NOT NULL,
  `store_url` varchar(255) DEFAULT NULL,
  `urls` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`urls`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `crawl_ai_extracted_data`
--

CREATE TABLE `crawl_ai_extracted_data` (
  `session_id` varchar(100) NOT NULL,
  `skey` varchar(255) DEFAULT NULL,
  `chunk_ids` text DEFAULT NULL,
  `store_url` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `credit_packs`
--

CREATE TABLE `credit_packs` (
  `id` int(11) NOT NULL,
  `credit_type` varchar(50) NOT NULL DEFAULT 'ai_responses',
  `amount` int(11) NOT NULL,
  `label` varchar(100) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `sort_order` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `credit_tiers`
--

CREATE TABLE `credit_tiers` (
  `id` int(11) NOT NULL,
  `credit_type` varchar(50) NOT NULL DEFAULT 'ai_responses',
  `range_label` varchar(50) NOT NULL,
  `per_1k_price` decimal(10,2) DEFAULT NULL,
  `sort_order` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `credit_usage_log`
--

CREATE TABLE `credit_usage_log` (
  `id` bigint(20) NOT NULL,
  `company_id` int(11) NOT NULL,
  `usage_type` varchar(50) NOT NULL,
  `credits_used` int(11) NOT NULL DEFAULT 1,
  `reference_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `csv_uploads`
--

CREATE TABLE `csv_uploads` (
  `id` varchar(36) NOT NULL,
  `filename` varchar(255) NOT NULL,
  `total_rows` int(11) DEFAULT 0,
  `valid_phones` int(11) DEFAULT 0,
  `invalid_phones` int(11) DEFAULT 0,
  `duplicate_phones` int(11) DEFAULT 0,
  `phones` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Array of validated phone numbers' CHECK (json_valid(`phones`)),
  `errors` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Array of human-readable error messages' CHECK (json_valid(`errors`)),
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Parsed CSV uploads for broadcast audience';

-- --------------------------------------------------------

--
-- Table structure for table `currencies`
--

CREATE TABLE `currencies` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `currency_code` varchar(191) NOT NULL,
  `symbol` varchar(191) NOT NULL,
  `currency_placement` varchar(191) NOT NULL DEFAULT 'before' COMMENT 'before, after',
  `current_currency` varchar(191) NOT NULL DEFAULT 'on' COMMENT 'on, off',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `daily_click_counts`
--

CREATE TABLE `daily_click_counts` (
  `id` int(11) NOT NULL,
  `url_id` int(11) NOT NULL,
  `click_date` date NOT NULL,
  `click_count` int(11) DEFAULT NULL,
  `referrer` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `dashboard_settings`
--

CREATE TABLE `dashboard_settings` (
  `id` int(12) NOT NULL,
  `company_id` int(11) DEFAULT NULL,
  `customer_satisfaction` enum('0','1') NOT NULL DEFAULT '0',
  `pending_human_response` enum('0','1') NOT NULL DEFAULT '0',
  `engagement` enum('0','1') NOT NULL DEFAULT '0',
  `leads_generation` enum('0','1') NOT NULL DEFAULT '0',
  `ai_productivity_boost` enum('0','1') NOT NULL DEFAULT '0',
  `conversions_from_links` enum('0','1') NOT NULL DEFAULT '0',
  `average_response_time_by_human_agent` enum('0','1') NOT NULL DEFAULT '0',
  `messages_closed_by_human_agent` enum('0','1') NOT NULL DEFAULT '0',
  `unassigned_task` enum('0','1') NOT NULL DEFAULT '0',
  `average_closed_time_by_ai` enum('0','1') NOT NULL DEFAULT '0',
  `average_closed_time_by_human_agent` enum('0','1') NOT NULL DEFAULT '0',
  `messages_closed_by_ai` enum('0','1') NOT NULL DEFAULT '0',
  `avg_response_time_by_ai_and_teams` enum('0','1') NOT NULL DEFAULT '0',
  `chatbot_usage_time` enum('0','1') NOT NULL DEFAULT '0',
  `most_common_topics` enum('0','1') NOT NULL DEFAULT '0',
  `most_common_topics_by_agent` enum('0','1') NOT NULL DEFAULT '0',
  `channel_insights` enum('0','1') NOT NULL DEFAULT '0',
  `locations` enum('0','1') NOT NULL DEFAULT '0',
  `device_insights` enum('0','1') NOT NULL DEFAULT '0',
  `languages_used_in_queries` enum('0','1') DEFAULT '0',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `demo_session_details`
--

CREATE TABLE `demo_session_details` (
  `session_id` varchar(100) NOT NULL,
  `snapshot` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `store_url` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `emails`
--

CREATE TABLE `emails` (
  `id` int(11) NOT NULL,
  `user_email` varchar(255) DEFAULT NULL,
  `subject` text DEFAULT NULL,
  `sender` text DEFAULT NULL,
  `preview` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `email_accounts`
--

CREATE TABLE `email_accounts` (
  `company_id` varchar(64) NOT NULL,
  `email` varchar(255) NOT NULL,
  `encrypted_password` text NOT NULL,
  `smtp_server` varchar(255) NOT NULL,
  `smtp_port` int(11) NOT NULL,
  `imap_server` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `email_channels`
--

CREATE TABLE `email_channels` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` int(11) NOT NULL,
  `account_name` varchar(255) DEFAULT NULL,
  `email_address` varchar(255) NOT NULL,
  `platform` enum('Gmail','Outlook','Other') NOT NULL DEFAULT 'Gmail',
  `access_token` text DEFAULT NULL,
  `refresh_token` text DEFAULT NULL,
  `token_expires_at` timestamp NULL DEFAULT NULL,
  `avatar` varchar(500) DEFAULT NULL,
  `status` enum('active','inactive','pending') NOT NULL DEFAULT 'active',
  `connected_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `engine_version`
--

CREATE TABLE `engine_version` (
  `id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `engine_name` varchar(100) DEFAULT NULL,
  `version` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `self_learn` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `events`
--

CREATE TABLE `events` (
  `id` int(11) NOT NULL,
  `event_id` varchar(36) NOT NULL,
  `event_type` varchar(100) NOT NULL,
  `company_id` bigint(20) NOT NULL,
  `is_public` tinyint(1) DEFAULT 0,
  `payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`payload`)),
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `facebook_channels`
--

CREATE TABLE `facebook_channels` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` int(11) NOT NULL,
  `page_name` varchar(255) DEFAULT NULL,
  `page_id` varchar(100) DEFAULT NULL,
  `page_identifier` varchar(255) DEFAULT NULL,
  `page_access_token` text DEFAULT NULL,
  `user_access_token` text DEFAULT NULL,
  `auto_reply` tinyint(1) NOT NULL DEFAULT 1,
  `status` enum('active','inactive','pending') NOT NULL DEFAULT 'active',
  `connected_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(191) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `faqs`
--

CREATE TABLE `faqs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `question` varchar(191) NOT NULL,
  `answer` tinytext NOT NULL,
  `status` tinyint(4) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `file_managers`
--

CREATE TABLE `file_managers` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `folder_name` varchar(191) DEFAULT NULL,
  `file_name` varchar(191) DEFAULT NULL,
  `file_size` varchar(191) DEFAULT NULL,
  `origin_type` varchar(191) DEFAULT NULL,
  `origin_id` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `gateways`
--

CREATE TABLE `gateways` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(191) NOT NULL,
  `slug` varchar(191) NOT NULL,
  `image` varchar(191) DEFAULT NULL,
  `status` tinyint(4) NOT NULL DEFAULT 0 COMMENT '1=Active,0=Disable',
  `mode` tinyint(4) NOT NULL DEFAULT 2 COMMENT '1=live,2=sandbox',
  `url` varchar(191) DEFAULT NULL,
  `key` varchar(191) DEFAULT NULL COMMENT 'client id, public key, key, store id, api key',
  `secret` varchar(191) DEFAULT NULL COMMENT 'client secret, secret, store password, auth token',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `gateway_currencies`
--

CREATE TABLE `gateway_currencies` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `gateway_id` bigint(20) UNSIGNED NOT NULL,
  `currency` varchar(191) NOT NULL DEFAULT 'USD',
  `conversion_rate` decimal(8,2) NOT NULL DEFAULT 1.00,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `generated_tokens`
--

CREATE TABLE `generated_tokens` (
  `id` int(11) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `token` text NOT NULL,
  `company_id` int(11) DEFAULT NULL,
  `creation_date` datetime DEFAULT NULL,
  `expiry_date` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `gmail_tokens`
--

CREATE TABLE `gmail_tokens` (
  `id` int(11) NOT NULL,
  `company_id` bigint(20) DEFAULT NULL,
  `user_email` varchar(255) DEFAULT NULL,
  `token` text DEFAULT NULL,
  `refresh_token` text DEFAULT NULL,
  `token_uri` text DEFAULT NULL,
  `client_id` text DEFAULT NULL,
  `client_secret` text DEFAULT NULL,
  `scopes` text DEFAULT NULL,
  `history_id` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `how_it_works`
--

CREATE TABLE `how_it_works` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(191) NOT NULL,
  `summery` tinytext DEFAULT NULL,
  `content` tinytext DEFAULT NULL,
  `status` tinyint(4) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `instagram_channels`
--

CREATE TABLE `instagram_channels` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` int(11) NOT NULL,
  `username` varchar(255) DEFAULT NULL,
  `ig_user_id` varchar(100) DEFAULT NULL,
  `identifier` varchar(255) DEFAULT NULL,
  `page_access_token` text DEFAULT NULL,
  `connected_fb_page_id` varchar(100) DEFAULT NULL,
  `auto_reply` tinyint(1) NOT NULL DEFAULT 1,
  `status` enum('active','inactive','pending') NOT NULL DEFAULT 'active',
  `connected_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `invoices`
--

CREATE TABLE `invoices` (
  `id` int(11) NOT NULL,
  `company_id` bigint(20) NOT NULL,
  `invoice_id` varchar(100) NOT NULL,
  `date` datetime DEFAULT NULL,
  `plan_name` varchar(100) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT 0.00,
  `subtotal` decimal(10,2) DEFAULT 0.00,
  `tax_amount` decimal(10,2) DEFAULT 0.00,
  `discount_amount` decimal(10,2) DEFAULT 0.00,
  `currency` varchar(3) DEFAULT 'USD',
  `transaction_type` varchar(50) DEFAULT 'subscription',
  `billing_cycle` varchar(10) DEFAULT NULL,
  `billing_snapshot` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`billing_snapshot`)),
  `status` varchar(20) DEFAULT 'paid',
  `provider` varchar(20) DEFAULT 'shopify',
  `provider_invoice_id` varchar(255) DEFAULT NULL,
  `pdf_url` varchar(1024) DEFAULT NULL,
  `internal_pdf_key` varchar(512) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `invoice_line_items`
--

CREATE TABLE `invoice_line_items` (
  `id` int(11) NOT NULL,
  `invoice_id` int(11) NOT NULL,
  `description` varchar(500) NOT NULL,
  `quantity` int(11) DEFAULT 1,
  `unit_price` decimal(10,2) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `item_type` enum('plan','addon','credit_pack','proration','discount') NOT NULL,
  `item_ref_id` varchar(100) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `knowledge_base`
--

CREATE TABLE `knowledge_base` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` int(11) NOT NULL,
  `name` varchar(500) NOT NULL COMMENT 'Display title of the source',
  `type` enum('Upload','Editor') NOT NULL DEFAULT 'Upload' COMMENT 'Upload = file, Editor = rich-text doc',
  `status` enum('trained','training','excluded') NOT NULL DEFAULT 'training',
  `content` longtext DEFAULT NULL COMMENT 'HTML content for Editor type docs',
  `file_path` varchar(500) DEFAULT NULL COMMENT 'Stored filename for Upload type (in public/knowledge_base/)',
  `file_original_name` varchar(500) DEFAULT NULL COMMENT 'Original uploaded filename',
  `file_size` int(11) DEFAULT NULL COMMENT 'File size in bytes',
  `url` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL COMMENT 'Soft delete'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `knowledge_base_sources`
--

CREATE TABLE `knowledge_base_sources` (
  `id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `name` varchar(500) NOT NULL,
  `url` varchar(1024) DEFAULT NULL,
  `source_type` varchar(50) NOT NULL,
  `category` varchar(50) NOT NULL,
  `status` varchar(20) DEFAULT 'trained',
  `shopify_id` varchar(255) DEFAULT NULL,
  `wordpress_id` varchar(255) DEFAULT NULL,
  `content` text DEFAULT NULL,
  `file_path` varchar(1024) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `languages`
--

CREATE TABLE `languages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(191) NOT NULL,
  `code` varchar(191) NOT NULL,
  `icon` varchar(191) DEFAULT NULL,
  `rtl` tinyint(4) NOT NULL DEFAULT 0,
  `status` tinyint(4) NOT NULL DEFAULT 1 COMMENT '1=Active,0=Disable',
  `default` tinyint(4) NOT NULL DEFAULT 0 COMMENT '1=yes,0=no',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `language_list`
--

CREATE TABLE `language_list` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` char(49) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `iso_639-1` char(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_bin;

-- --------------------------------------------------------

--
-- Table structure for table `llm_config`
--

CREATE TABLE `llm_config` (
  `id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `provider` varchar(50) NOT NULL DEFAULT 'bedrock',
  `model_name` varchar(100) DEFAULT NULL,
  `temperature` float DEFAULT 0.7,
  `api_key` varchar(500) DEFAULT NULL,
  `base_url` varchar(500) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `media_settings`
--

CREATE TABLE `media_settings` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `brand_id` int(11) DEFAULT 0,
  `name` varchar(191) NOT NULL,
  `email` varchar(191) NOT NULL,
  `designation` varchar(191) DEFAULT NULL,
  `contact_no` varchar(191) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `id` int(11) NOT NULL,
  `message` text DEFAULT NULL,
  `contact_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `source_id` int(11) DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT NULL,
  `message_id` varchar(512) DEFAULT NULL,
  `category` int(11) DEFAULT NULL,
  `attachment` varchar(2048) DEFAULT NULL,
  `attachment_type` varchar(255) DEFAULT NULL,
  `sentiment` int(11) DEFAULT 2 COMMENT '0=Negative, 1=Positive, 2=Neutral',
  `language` varchar(100) DEFAULT NULL,
  `source_name` varchar(255) DEFAULT NULL,
  `translated_message` text DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `intentions` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `message_translations`
--

CREATE TABLE `message_translations` (
  `id` int(11) NOT NULL,
  `message_id` int(11) NOT NULL,
  `target_language` varchar(10) NOT NULL,
  `translated_text` text NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `metas`
--

CREATE TABLE `metas` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `url` varchar(191) DEFAULT NULL,
  `page_name` varchar(191) DEFAULT NULL,
  `meta_title` mediumtext DEFAULT NULL,
  `meta_description` mediumtext DEFAULT NULL,
  `meta_keyword` mediumtext DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(191) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(191) NOT NULL,
  `body` text DEFAULT NULL,
  `url` varchar(191) DEFAULT NULL,
  `image` varchar(191) DEFAULT NULL,
  `is_seen` tinyint(4) NOT NULL DEFAULT 0,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `sender_id` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notification_rules`
--

CREATE TABLE `notification_rules` (
  `id` int(11) NOT NULL,
  `company_id` bigint(20) DEFAULT NULL,
  `event_type` varchar(100) NOT NULL,
  `channel_email` tinyint(1) DEFAULT 0,
  `channel_toast` tinyint(1) DEFAULT 0,
  `channel_push` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `payment_id` varchar(191) DEFAULT NULL,
  `transaction_id` varchar(191) DEFAULT NULL,
  `trans_details` longtext DEFAULT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `package_id` bigint(20) UNSIGNED DEFAULT NULL,
  `amount` double(8,2) DEFAULT 0.00,
  `tax_amount` double(8,2) DEFAULT NULL,
  `tax_percentage` double(8,2) DEFAULT NULL,
  `system_currency` varchar(191) DEFAULT NULL,
  `gateway_id` bigint(20) UNSIGNED NOT NULL,
  `gateway_currency` varchar(191) DEFAULT NULL,
  `conversion_rate` double(8,2) DEFAULT 1.00,
  `duration_type` tinyint(4) NOT NULL DEFAULT 1,
  `subtotal` double(8,2) NOT NULL DEFAULT 0.00,
  `total` double(8,2) DEFAULT 0.00,
  `transaction_amount` double(8,2) DEFAULT 0.00,
  `payment_status` tinyint(4) DEFAULT 0 COMMENT '0=pending, 1=paid, 2=cancelled',
  `bank_id` tinyint(4) DEFAULT NULL,
  `bank_name` varchar(191) DEFAULT NULL,
  `bank_account_number` varchar(191) DEFAULT NULL,
  `deposit_by` varchar(191) DEFAULT NULL,
  `deposit_slip_id` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `order_type` varchar(191) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `outlook_connections`
--

CREATE TABLE `outlook_connections` (
  `id` int(11) NOT NULL,
  `user_email` varchar(255) NOT NULL,
  `access_token` text NOT NULL,
  `refresh_token` text DEFAULT NULL,
  `subscription_id` varchar(255) DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  `company_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `packages`
--

CREATE TABLE `packages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(191) NOT NULL,
  `package_name` varchar(255) DEFAULT NULL,
  `slug` varchar(191) NOT NULL,
  `no_articles` int(11) NOT NULL DEFAULT 0,
  `no_trail_period_articles` int(11) NOT NULL DEFAULT 0,
  `access_use_cases` text DEFAULT NULL,
  `write_languages` int(11) NOT NULL DEFAULT 0,
  `access_tones` int(11) NOT NULL DEFAULT 0,
  `generate_characters` text DEFAULT NULL,
  `generate_images` int(11) NOT NULL DEFAULT 0,
  `plagiarism_checker` varchar(191) DEFAULT NULL,
  `access_community` varchar(191) DEFAULT NULL,
  `custom_use_cases` varchar(191) DEFAULT NULL,
  `dedicated_account` varchar(191) DEFAULT NULL,
  `support` varchar(191) DEFAULT NULL,
  `monthly_price` decimal(8,2) NOT NULL DEFAULT 0.00,
  `yearly_price` decimal(8,2) NOT NULL DEFAULT 0.00,
  `device_limit` int(11) NOT NULL DEFAULT 1,
  `status` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'active for 1 , deactivate for 0',
  `is_default` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'default for 1 , not default for 0',
  `is_trail` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'default for 1 , not default for 0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `monthly_id` varchar(255) DEFAULT NULL,
  `yearly_id` varchar(255) DEFAULT NULL,
  `media_distributions` text DEFAULT NULL,
  `description` text DEFAULT NULL,
  `sub_title` text DEFAULT NULL,
  `features_lists` longtext DEFAULT NULL,
  `contact_limits` text DEFAULT NULL,
  `ai_response_limits` int(11) NOT NULL DEFAULT 0,
  `knowledgebase_limits` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `partners`
--

CREATE TABLE `partners` (
  `id` int(11) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `company_name` varchar(255) DEFAULT NULL,
  `admin_id` int(12) DEFAULT 1,
  `url` text DEFAULT NULL,
  `status` enum('0','1') NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp(),
  `deleted_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `email` varchar(191) NOT NULL,
  `token` varchar(191) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pdf_documents`
--

CREATE TABLE `pdf_documents` (
  `id` int(11) NOT NULL,
  `uid` varchar(50) NOT NULL,
  `filename` varchar(255) NOT NULL,
  `file_path` varchar(512) NOT NULL,
  `file_size` bigint(20) NOT NULL,
  `skey` varchar(100) DEFAULT NULL,
  `is_editor` tinyint(1) DEFAULT 0,
  `self_learn` tinyint(1) DEFAULT 0,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`ids`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `permission_definitions`
--

CREATE TABLE `permission_definitions` (
  `id` int(11) NOT NULL,
  `category` varchar(50) NOT NULL,
  `action` varchar(50) NOT NULL,
  `permission_key` varchar(100) NOT NULL,
  `label` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT '',
  `sort_order` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(191) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(191) NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `plan_comparison`
--

CREATE TABLE `plan_comparison` (
  `id` int(11) NOT NULL,
  `category` varchar(100) NOT NULL,
  `feature_name` varchar(255) NOT NULL,
  `free_value` varchar(100) DEFAULT NULL,
  `basic_value` varchar(100) DEFAULT NULL,
  `growth_value` varchar(100) DEFAULT NULL,
  `advanced_value` varchar(100) DEFAULT NULL,
  `enterprise_value` varchar(100) DEFAULT NULL,
  `sort_order` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `plan_entitlements`
--

CREATE TABLE `plan_entitlements` (
  `id` int(11) NOT NULL,
  `plan_id` varchar(50) NOT NULL,
  `feature` varchar(100) NOT NULL,
  `allowed` tinyint(1) DEFAULT 0,
  `value` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `private_plan_assignments`
--

CREATE TABLE `private_plan_assignments` (
  `id` int(11) NOT NULL,
  `plan_id` varchar(50) NOT NULL,
  `company_id` int(11) NOT NULL,
  `assigned_by` varchar(100) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `price` float NOT NULL,
  `quantity` int(11) DEFAULT NULL,
  `link` varchar(255) DEFAULT NULL,
  `product_id` varchar(255) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `tags` varchar(255) DEFAULT NULL,
  `category` varchar(100) DEFAULT NULL,
  `chunk_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`chunk_ids`)),
  `session_id` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `promo_codes`
--

CREATE TABLE `promo_codes` (
  `id` int(11) NOT NULL,
  `code` varchar(50) NOT NULL,
  `description` text DEFAULT NULL,
  `discount_type` enum('percentage','fixed') NOT NULL,
  `discount_value` decimal(10,2) NOT NULL,
  `duration` enum('once','repeating','forever') NOT NULL DEFAULT 'once',
  `duration_months` int(11) DEFAULT NULL,
  `applies_to` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`applies_to`)),
  `max_redemptions` int(11) DEFAULT NULL,
  `times_redeemed` int(11) NOT NULL DEFAULT 0,
  `starts_at` datetime DEFAULT current_timestamp(),
  `expires_at` datetime DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `stripe_coupon_id` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `promo_code_redemptions`
--

CREATE TABLE `promo_code_redemptions` (
  `id` int(11) NOT NULL,
  `promo_code_id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `discount_amount` decimal(10,2) NOT NULL,
  `applied_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `qa_pairs`
--

CREATE TABLE `qa_pairs` (
  `id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `question` text NOT NULL COMMENT 'Original user question (or representative if grouped)',
  `answer` text NOT NULL COMMENT 'Bot reply (merchant can edit before training)',
  `context` text DEFAULT NULL COMMENT 'AI-summarized conversation context',
  `status` varchar(20) NOT NULL DEFAULT 'pending_review' COMMENT 'pending_review | trained | ignored',
  `asked_count` int(11) NOT NULL DEFAULT 1 COMMENT 'Number of times this question was asked',
  `highest_score` float DEFAULT NULL COMMENT 'Best RAG similarity score when captured',
  `last_asked_at` datetime DEFAULT current_timestamp(),
  `trained_at` datetime DEFAULT NULL COMMENT 'When merchant approved this pair',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `qa_pair_conversations`
--

CREATE TABLE `qa_pair_conversations` (
  `id` int(11) NOT NULL,
  `qa_pair_id` int(11) NOT NULL,
  `contact_id` int(11) NOT NULL COMMENT 'FK to contacts.id (the customer who asked)',
  `user_message` text DEFAULT NULL COMMENT 'Exact message the user sent',
  `bot_reply` text DEFAULT NULL COMMENT 'Exact reply the bot gave',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `rag_config`
--

CREATE TABLE `rag_config` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `company_id` int(11) NOT NULL,
  `k_value` int(11) DEFAULT NULL,
  `additional_prompt` text DEFAULT NULL,
  `temperature` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `response_source`
--

CREATE TABLE `response_source` (
  `id` int(11) NOT NULL,
  `name` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `roles`
--

CREATE TABLE `roles` (
  `id` int(11) NOT NULL,
  `rolename` text NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `role_permissions`
--

CREATE TABLE `role_permissions` (
  `id` int(11) NOT NULL,
  `role_id` int(11) NOT NULL,
  `permission_key` varchar(100) NOT NULL,
  `allowed` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `search_results`
--

CREATE TABLE `search_results` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `category_id` bigint(20) UNSIGNED NOT NULL,
  `sub_category_id` bigint(20) UNSIGNED NOT NULL,
  `prompt` text DEFAULT NULL,
  `description` tinytext DEFAULT NULL,
  `product` varchar(191) DEFAULT NULL,
  `creativity_level` varchar(191) DEFAULT NULL,
  `tone_of_voice` varchar(191) DEFAULT NULL,
  `target_action` varchar(191) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `search_result_items`
--

CREATE TABLE `search_result_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `search_result_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `output` longtext NOT NULL,
  `react` tinyint(4) DEFAULT NULL,
  `is_favorite` tinyint(4) NOT NULL DEFAULT 0,
  `total_word` int(11) NOT NULL DEFAULT 0,
  `total_characters` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `segments`
--

CREATE TABLE `segments` (
  `id` varchar(36) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `rules` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`rules`)),
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `segment_members`
--

CREATE TABLE `segment_members` (
  `id` int(11) NOT NULL,
  `segment_id` varchar(36) NOT NULL,
  `contact_id` varchar(36) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `settings`
--

CREATE TABLE `settings` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `option_key` varchar(191) NOT NULL,
  `option_value` text DEFAULT NULL,
  `label` varchar(191) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `shopify`
--

CREATE TABLE `shopify` (
  `id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `access_token` varchar(255) NOT NULL,
  `shop_name` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `last_sync` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `shopify_connections`
--

CREATE TABLE `shopify_connections` (
  `id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `shopify_url` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `access_token` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `shopify_webhook_log`
--

CREATE TABLE `shopify_webhook_log` (
  `id` int(11) NOT NULL,
  `webhook_id` varchar(100) NOT NULL,
  `topic` varchar(100) NOT NULL,
  `shop_domain` varchar(255) NOT NULL,
  `payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`payload`)),
  `processed_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sma_members`
--

CREATE TABLE `sma_members` (
  `account_no` varchar(20) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `membership_type` varchar(50) DEFAULT NULL,
  `email` varchar(120) DEFAULT NULL,
  `mobile` varchar(20) DEFAULT NULL,
  `outstanding_balance` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `social_channel`
--

CREATE TABLE `social_channel` (
  `id` int(11) NOT NULL,
  `Telegram_token` varchar(255) DEFAULT NULL,
  `Telegram_id` varchar(255) DEFAULT NULL,
  `Company_id` bigint(20) DEFAULT NULL,
  `Insta_page_id` varchar(255) DEFAULT NULL,
  `Insta_page_token` varchar(255) DEFAULT NULL,
  `Ins_fb_page` varchar(255) DEFAULT NULL,
  `waba_access` text DEFAULT NULL,
  `waba_id` varchar(255) DEFAULT NULL,
  `phone_number_id` varchar(255) DEFAULT NULL,
  `insta_username` varchar(255) DEFAULT NULL,
  `tel_username` varchar(255) DEFAULT NULL,
  `waba_username` varchar(255) DEFAULT NULL,
  `shopify_url` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL,
  `company_email` varchar(255) DEFAULT NULL,
  `wp_url` varchar(255) DEFAULT NULL,
  `waba_phone_number` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `social_channels`
--

CREATE TABLE `social_channels` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` int(11) NOT NULL,
  `channel_type` enum('webchat','whatsapp','facebook','instagram','email','telegram','wordpress') NOT NULL,
  `account_count` int(11) NOT NULL DEFAULT 0,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `standard_onboarding`
--

CREATE TABLE `standard_onboarding` (
  `id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `knowledgebase` int(11) NOT NULL DEFAULT 0,
  `settings` int(11) NOT NULL DEFAULT 0,
  `channel` int(11) NOT NULL DEFAULT 0,
  `widget` int(11) NOT NULL DEFAULT 0,
  `testai` int(11) NOT NULL DEFAULT 0,
  `verify` int(11) NOT NULL DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `subscription_addons`
--

CREATE TABLE `subscription_addons` (
  `id` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `monthly_price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `period` varchar(20) DEFAULT '/mo',
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `subscription_plans`
--

CREATE TABLE `subscription_plans` (
  `id` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `monthly_price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `annual_price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `plan_credits` int(11) NOT NULL DEFAULT 0,
  `agent_seats` int(11) NOT NULL DEFAULT 1,
  `channels` int(11) NOT NULL DEFAULT 1,
  `features` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`features`)),
  `is_active` tinyint(1) DEFAULT 1,
  `sort_order` int(11) DEFAULT 0,
  `is_public` tinyint(1) DEFAULT 1,
  `is_custom` tinyint(1) DEFAULT 0,
  `kb_capacity_gb` decimal(10,2) DEFAULT 1.00,
  `best_for` text DEFAULT NULL,
  `summary` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`summary`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sub_categories`
--

CREATE TABLE `sub_categories` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `category_id` int(10) UNSIGNED NOT NULL,
  `name` varchar(191) NOT NULL,
  `summery` mediumtext DEFAULT NULL,
  `is_favorite` tinyint(4) NOT NULL DEFAULT 0,
  `content` text DEFAULT NULL,
  `prompt` text DEFAULT NULL,
  `long_form_prompt` tinytext DEFAULT NULL,
  `icon` varchar(191) DEFAULT 'default.svg',
  `status` tinyint(4) NOT NULL DEFAULT 1,
  `is_long_form` tinyint(4) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `suggested_questions`
--

CREATE TABLE `suggested_questions` (
  `id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `questions` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`questions`)),
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `system_settings`
--

CREATE TABLE `system_settings` (
  `setting_key` varchar(100) NOT NULL,
  `setting_value` varchar(500) NOT NULL,
  `description` text DEFAULT NULL,
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tags`
--

CREATE TABLE `tags` (
  `id` int(11) NOT NULL,
  `company_id` bigint(20) NOT NULL,
  `tag_name` varchar(50) NOT NULL,
  `created_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `team_management`
--

CREATE TABLE `team_management` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `team_name` varchar(255) NOT NULL,
  `category_id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `member_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`member_ids`)),
  `member_ids_value` varchar(255) DEFAULT NULL,
  `message` text DEFAULT NULL,
  `user_id` int(12) DEFAULT NULL,
  `team_sort` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `max_ticket_allowed` int(11) DEFAULT 5
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `telegram_channels`
--

CREATE TABLE `telegram_channels` (
  `id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `bot_token` varchar(255) NOT NULL,
  `telegram_id` varchar(50) NOT NULL,
  `tel_username` varchar(150) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `testimonials`
--

CREATE TABLE `testimonials` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(191) NOT NULL,
  `designation` varchar(191) DEFAULT NULL,
  `comment` tinytext DEFAULT NULL,
  `star` tinyint(4) NOT NULL DEFAULT 5,
  `status` tinyint(4) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tickets`
--

CREATE TABLE `tickets` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(191) NOT NULL,
  `details` text NOT NULL,
  `topic_id` bigint(20) UNSIGNED NOT NULL,
  `status` tinyint(4) NOT NULL DEFAULT 1,
  `ticket_no` varchar(191) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ticket_replies`
--

CREATE TABLE `ticket_replies` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ticket_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `reply` text NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ticket_topics`
--

CREATE TABLE `ticket_topics` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(191) NOT NULL,
  `status` tinyint(4) DEFAULT 1 COMMENT '0=deactivate,1=active',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `top_ups`
--

CREATE TABLE `top_ups` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(191) NOT NULL,
  `slug` varchar(191) NOT NULL,
  `no_articles` int(11) NOT NULL DEFAULT 0,
  `price` decimal(8,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `total_amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `txn_id` varchar(100) DEFAULT NULL,
  `payment_method` varchar(100) DEFAULT NULL,
  `currency` varchar(100) NOT NULL,
  `payment_details` longtext DEFAULT NULL,
  `payment_time` datetime DEFAULT NULL,
  `status` enum('initiate','pending','completed','cancelled') NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `sub_status` varchar(191) DEFAULT NULL,
  `sub_id` varchar(191) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `transaction_log`
--

CREATE TABLE `transaction_log` (
  `id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `invoice_id` int(11) DEFAULT NULL,
  `event_type` enum('payment_succeeded','payment_failed','subscription_created','subscription_changed','subscription_cancelled','addon_added','addon_removed','credits_purchased','refund') NOT NULL,
  `provider` enum('stripe','shopify') NOT NULL,
  `provider_event_id` varchar(255) DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT 0.00,
  `currency` varchar(3) DEFAULT 'USD',
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `transfer_ticket`
--

CREATE TABLE `transfer_ticket` (
  `id` int(11) NOT NULL,
  `company_id` int(11) NOT NULL,
  `contact_id` int(11) NOT NULL,
  `assigned_by` int(11) NOT NULL,
  `assigned_to` int(11) NOT NULL,
  `transferred_by` int(11) DEFAULT NULL,
  `timestamp` datetime DEFAULT current_timestamp(),
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `url_mapping`
--

CREATE TABLE `url_mapping` (
  `id` int(11) NOT NULL,
  `original_url` varchar(2083) NOT NULL,
  `short_code` varchar(7) NOT NULL,
  `hit_count` int(11) DEFAULT NULL,
  `admin_id` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) NOT NULL,
  `provider_id` varchar(191) DEFAULT NULL,
  `first_name` varchar(191) DEFAULT NULL,
  `last_name` varchar(191) DEFAULT NULL,
  `email` varchar(191) NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(191) NOT NULL,
  `contact_number` varchar(20) DEFAULT NULL,
  `status` tinyint(4) NOT NULL DEFAULT 1 COMMENT 'Active = 1, Deactivate = 0',
  `created_by` bigint(20) DEFAULT NULL,
  `role` tinyint(4) NOT NULL DEFAULT 2,
  `remember_token` varchar(100) DEFAULT NULL,
  `verify_token` varchar(191) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `latest_invoice` varchar(191) DEFAULT NULL,
  `customer_id` varchar(191) DEFAULT NULL,
  `subscription_id` varchar(191) DEFAULT NULL,
  `subscription_status` varchar(191) DEFAULT NULL,
  `subscription_article_limit` int(11) NOT NULL DEFAULT 0,
  `topup_article_limit` int(11) NOT NULL DEFAULT 0,
  `trail_article_limit` int(20) NOT NULL DEFAULT 0,
  `media_distributions_limit` int(11) NOT NULL DEFAULT 0,
  `company_id` int(11) NOT NULL DEFAULT 0 COMMENT '0 -owner,remaining ids are owner primary id ',
  `common_company_id` int(11) DEFAULT NULL COMMENT 'active company id',
  `login_type` int(11) NOT NULL DEFAULT 2 COMMENT '1-application login 2-gmail login\r\n3-shopify login',
  `browser_info` text DEFAULT NULL,
  `ip_address` text DEFAULT NULL,
  `country` text DEFAULT NULL,
  `city` text DEFAULT NULL,
  `region` text DEFAULT NULL,
  `latitude` text DEFAULT NULL,
  `longitude` text DEFAULT NULL,
  `continent_name` text DEFAULT NULL,
  `time_zone` text DEFAULT NULL,
  `user_timezone` varchar(255) DEFAULT NULL,
  `language` varchar(100) DEFAULT NULL,
  `currency_code` text DEFAULT NULL,
  `partner_id` int(12) DEFAULT NULL,
  `setup_alert` enum('0','1') NOT NULL DEFAULT '0',
  `last_login` datetime DEFAULT NULL,
  `user_type` enum('0','1','2') NOT NULL DEFAULT '0' COMMENT '0-company_user,1-demo_user,2-free_uers',
  `preferences` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`preferences`)),
  `company_role_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_brands`
--

CREATE TABLE `user_brands` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(191) DEFAULT NULL,
  `logo` varchar(191) DEFAULT NULL,
  `about_brand` text DEFAULT NULL,
  `user_id` int(10) DEFAULT NULL,
  `media_contact_ids` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_companys`
--

CREATE TABLE `user_companys` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `secretkey` text DEFAULT NULL,
  `company_email` text DEFAULT NULL,
  `brand_name` varchar(130) DEFAULT NULL,
  `website_url` text DEFAULT NULL,
  `welcome_msg` longtext DEFAULT NULL,
  `brand_logo` text DEFAULT NULL,
  `brand_color` varchar(130) DEFAULT NULL,
  `human_agent_logo` varchar(255) DEFAULT NULL,
  `bot_logo` varchar(255) DEFAULT NULL,
  `language` text DEFAULT NULL,
  `timezone` text NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `greeting_message` longtext DEFAULT NULL,
  `error_message` varchar(512) DEFAULT NULL,
  `utm_source` varchar(255) DEFAULT NULL,
  `business_description` text DEFAULT NULL,
  `shopify_app_id` varchar(255) DEFAULT NULL,
  `dashboard_setting` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT '{"customer_satisfaction":"1","leads_generation":"1","ai_productivity_boost":"1","pending_human_response":"1","engagement":"1","chatbot_usage_time":"1","conversions_from_links":"1","most_common_topics_by_agent":"1","locations":"1","languages_used_in_queries":"1","device_insights":"1","channel_insights":"1","most_common_topics":"1"}',
  `shopify_setup` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`shopify_setup`)),
  `offline_msg` text DEFAULT 'Our team is currently offline. We\'ll get back to you as soon as we can. In the meantime, feel free to continue chatting with our AI concierge.',
  `online_msg` text DEFAULT 'Let me connect you with one of our team members now. Please hold on for a couple of minutes',
  `currency` varchar(10) DEFAULT NULL,
  `office_hours` text DEFAULT NULL,
  `office_hour_msg` text DEFAULT NULL,
  `country` text NOT NULL,
  `auto_translation_enabled` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_favorites`
--

CREATE TABLE `user_favorites` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `category_id` bigint(20) UNSIGNED NOT NULL,
  `sub_category_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_numbers`
--

CREATE TABLE `user_numbers` (
  `ID` int(11) NOT NULL,
  `contact_count` int(11) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `knowledgebase_count` int(11) DEFAULT NULL,
  `unread_count` int(11) DEFAULT NULL,
  `page_token` text DEFAULT NULL,
  `page_id` text DEFAULT NULL,
  `page_name` text DEFAULT '',
  `website_hosted` text DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_online_status`
--

CREATE TABLE `user_online_status` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `socket_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`socket_ids`)),
  `status` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_online_status1`
--

CREATE TABLE `user_online_status1` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `connection_count` int(11) NOT NULL,
  `status` tinyint(1) NOT NULL,
  `latest_update` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_packages`
--

CREATE TABLE `user_packages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `company_id` int(11) DEFAULT NULL,
  `package_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(191) NOT NULL,
  `no_articles` int(11) NOT NULL DEFAULT 0,
  `no_trail_period_articles` int(25) NOT NULL DEFAULT 0,
  `access_use_cases` text DEFAULT NULL,
  `write_languages` int(11) NOT NULL DEFAULT 0,
  `access_tones` int(11) NOT NULL DEFAULT 0,
  `write_languageses` longtext DEFAULT NULL,
  `access_toneses` longtext DEFAULT NULL,
  `generate_images` int(11) NOT NULL DEFAULT 0,
  `plagiarism_checker` varchar(191) DEFAULT NULL,
  `access_community` varchar(191) DEFAULT NULL,
  `custom_use_cases` varchar(191) DEFAULT NULL,
  `dedicated_account` varchar(191) DEFAULT NULL,
  `support` varchar(191) DEFAULT NULL,
  `monthly_price` decimal(8,2) NOT NULL DEFAULT 0.00,
  `yearly_price` decimal(8,2) NOT NULL DEFAULT 0.00,
  `device_limit` int(11) NOT NULL DEFAULT 1,
  `start_date` datetime NOT NULL,
  `end_date` datetime NOT NULL,
  `order_id` bigint(20) UNSIGNED DEFAULT NULL,
  `status` tinyint(4) NOT NULL DEFAULT 0,
  `is_trail` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'default for 1 , not default for 0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `trail_end_date` varchar(255) NOT NULL DEFAULT '0',
  `media_distributions` int(25) DEFAULT NULL,
  `plan_type` int(11) NOT NULL DEFAULT 1 COMMENT '1-monthly,2-yearly'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_package_periods`
--

CREATE TABLE `user_package_periods` (
  `id` int(12) NOT NULL,
  `plan_id` int(11) DEFAULT NULL,
  `month_no` int(12) NOT NULL,
  `startdate` datetime DEFAULT NULL,
  `enddate` datetime DEFAULT NULL,
  `ai_responses_limit` int(255) DEFAULT 0,
  `used_ai_responses` int(255) NOT NULL DEFAULT 0,
  `used_business_knowledge` int(12) NOT NULL DEFAULT 0,
  `business_knowledge_limit` int(12) DEFAULT NULL,
  `email_alert_75_percentage` enum('0','1') NOT NULL DEFAULT '0',
  `email_alert_status` enum('0','1') NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_relationships`
--

CREATE TABLE `user_relationships` (
  `id` int(11) NOT NULL,
  `refer_userid` int(11) NOT NULL DEFAULT 0,
  `company_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `role` int(11) DEFAULT NULL COMMENT '2-teachadmin,3-admin,4-member',
  `chat_access` enum('0','1') DEFAULT '1',
  `business_knowledge_access` enum('0','1') DEFAULT '1',
  `channel_access` enum('0','1') DEFAULT '1',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_social_token`
--

CREATE TABLE `user_social_token` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `facebook` text DEFAULT NULL,
  `telegram` text DEFAULT NULL,
  `instagram` text DEFAULT NULL,
  `whatsapp` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_topups`
--

CREATE TABLE `user_topups` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `topup_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(191) NOT NULL,
  `no_articles` int(11) NOT NULL DEFAULT 0,
  `access_use_cases` text DEFAULT NULL,
  `write_languages` int(11) NOT NULL DEFAULT 0,
  `access_tones` int(11) NOT NULL DEFAULT 0,
  `write_languageses` longtext DEFAULT NULL,
  `access_toneses` longtext DEFAULT NULL,
  `generate_images` int(11) NOT NULL DEFAULT 0,
  `plagiarism_checker` varchar(191) DEFAULT NULL,
  `access_community` varchar(191) DEFAULT NULL,
  `custom_use_cases` varchar(191) DEFAULT NULL,
  `dedicated_account` varchar(191) DEFAULT NULL,
  `support` varchar(191) DEFAULT NULL,
  `price` decimal(8,2) NOT NULL DEFAULT 0.00,
  `device_limit` int(11) NOT NULL DEFAULT 1,
  `start_date` datetime NOT NULL,
  `order_id` bigint(20) UNSIGNED DEFAULT NULL,
  `status` tinyint(4) NOT NULL DEFAULT 0,
  `is_trail` tinyint(4) NOT NULL DEFAULT 0 COMMENT 'default for 1 , not default for 0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `webchat_channels`
--

CREATE TABLE `webchat_channels` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` int(11) NOT NULL,
  `widget_id` varchar(255) NOT NULL,
  `domain` varchar(500) DEFAULT NULL,
  `embed_code` text DEFAULT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `script_installed_at` datetime DEFAULT NULL,
  `installed_domain` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `webhook_deliveries`
--

CREATE TABLE `webhook_deliveries` (
  `id` int(11) NOT NULL,
  `delivery_id` varchar(36) NOT NULL,
  `subscription_id` varchar(36) NOT NULL,
  `event_id` varchar(36) NOT NULL,
  `url` varchar(1024) NOT NULL,
  `request_headers` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`request_headers`)),
  `request_body` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`request_body`)),
  `response_status` int(11) DEFAULT NULL,
  `response_body` text DEFAULT NULL,
  `status` varchar(20) DEFAULT 'pending',
  `attempt` int(11) DEFAULT 1,
  `next_retry_at` datetime DEFAULT NULL,
  `error_message` varchar(500) DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `webhook_subscriptions`
--

CREATE TABLE `webhook_subscriptions` (
  `id` int(11) NOT NULL,
  `subscription_id` varchar(36) NOT NULL,
  `company_id` bigint(20) NOT NULL,
  `url` varchar(1024) NOT NULL,
  `secret` varchar(255) NOT NULL,
  `event_types` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`event_types`)),
  `headers` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`headers`)),
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `description` varchar(500) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `whatsapp_channels`
--

CREATE TABLE `whatsapp_channels` (
  `id` int(11) NOT NULL,
  `company_id` bigint(20) NOT NULL,
  `waba_id` varchar(255) NOT NULL,
  `phone_number_id` varchar(255) NOT NULL,
  `waba_access` text NOT NULL,
  `waba_username` varchar(255) DEFAULT NULL,
  `account_name` varchar(255) DEFAULT NULL,
  `phone_number` varchar(50) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'active',
  `connected_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `wordpress_channels`
--

CREATE TABLE `wordpress_channels` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `company_id` int(11) NOT NULL,
  `site_url` varchar(500) NOT NULL,
  `api_key` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `connected_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin_roles`
--
ALTER TABLE `admin_roles`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `agent_llm_config`
--
ALTER TABLE `agent_llm_config`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `agent_name` (`agent_name`);

--
-- Indexes for table `bot_setting`
--
ALTER TABLE `bot_setting`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_company_id` (`company_id`);

--
-- Indexes for table `brands`
--
ALTER TABLE `brands`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `broadcasts`
--
ALTER TABLE `broadcasts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_broadcasts_status_created` (`status`,`created_at`),
  ADD KEY `idx_broadcasts_sent_at` (`sent_at`),
  ADD KEY `idx_broadcasts_campaign_name` (`campaign_name`),
  ADD KEY `idx_broadcasts_scheduled_at` (`status`,`scheduled_at`);

--
-- Indexes for table `broadcast_recipients`
--
ALTER TABLE `broadcast_recipients`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_recipients_broadcast_id` (`broadcast_id`),
  ADD KEY `idx_recipients_meta_message_id` (`meta_message_id`),
  ADD KEY `idx_recipients_phone` (`phone`),
  ADD KEY `idx_recipients_broadcast_status` (`broadcast_id`,`status`),
  ADD KEY `idx_recipients_status_sent` (`status`,`sent_at`);

--
-- Indexes for table `channel_settings`
--
ALTER TABLE `channel_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_company_channel` (`company_id`);

--
-- Indexes for table `chat_categories`
--
ALTER TABLE `chat_categories`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `company_addons`
--
ALTER TABLE `company_addons`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_ca_company_addon` (`company_id`,`addon_id`);

--
-- Indexes for table `company_billing_info`
--
ALTER TABLE `company_billing_info`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_cbi_company` (`company_id`);

--
-- Indexes for table `company_credits`
--
ALTER TABLE `company_credits`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_cc_company` (`company_id`),
  ADD KEY `idx_cc_type` (`credit_type`);

--
-- Indexes for table `company_onboarding`
--
ALTER TABLE `company_onboarding`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_company_onboarding_company_id` (`company_id`);

--
-- Indexes for table `company_roles`
--
ALTER TABLE `company_roles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_company_role_name` (`company_id`,`name`),
  ADD KEY `idx_company_roles_company` (`company_id`);

--
-- Indexes for table `company_subscriptions`
--
ALTER TABLE `company_subscriptions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_cs_company_active` (`company_id`,`status`),
  ADD KEY `idx_cs_plan` (`plan_id`);

--
-- Indexes for table `company_type`
--
ALTER TABLE `company_type`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `contacts`
--
ALTER TABLE `contacts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_contacts_company_id` (`company_id`),
  ADD KEY `idx_contacts_member_id` (`member_id`),
  ADD KEY `idx_contacts_is_ticket` (`is_ticket`);

--
-- Indexes for table `contacts_geo`
--
ALTER TABLE `contacts_geo`
  ADD PRIMARY KEY (`id`),
  ADD KEY `contact_id` (`contact_id`);

--
-- Indexes for table `contact_channels`
--
ALTER TABLE `contact_channels`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_cc_contact` (`contact_id`),
  ADD KEY `idx_cc_channel` (`channel`),
  ADD KEY `idx_cc_company` (`company_id`);

--
-- Indexes for table `contact_company_data`
--
ALTER TABLE `contact_company_data`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `contact_messages`
--
ALTER TABLE `contact_messages`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `contact_tags`
--
ALTER TABLE `contact_tags`
  ADD PRIMARY KEY (`id`),
  ADD KEY `contact_id` (`contact_id`),
  ADD KEY `tag_id` (`tag_id`),
  ADD KEY `idx_contact_tag_company_contact` (`company_id`,`contact_id`);

--
-- Indexes for table `crawlai_extracted_data`
--
ALTER TABLE `crawlai_extracted_data`
  ADD PRIMARY KEY (`session_id`);

--
-- Indexes for table `crawl_ai_extracted_data`
--
ALTER TABLE `crawl_ai_extracted_data`
  ADD PRIMARY KEY (`session_id`);

--
-- Indexes for table `credit_packs`
--
ALTER TABLE `credit_packs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `credit_tiers`
--
ALTER TABLE `credit_tiers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `credit_usage_log`
--
ALTER TABLE `credit_usage_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_company_type` (`company_id`,`usage_type`),
  ADD KEY `idx_company_date` (`company_id`,`created_at`);

--
-- Indexes for table `csv_uploads`
--
ALTER TABLE `csv_uploads`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `currencies`
--
ALTER TABLE `currencies`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `daily_click_counts`
--
ALTER TABLE `daily_click_counts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_url_date_referrer` (`url_id`,`click_date`,`referrer`);

--
-- Indexes for table `dashboard_settings`
--
ALTER TABLE `dashboard_settings`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `demo_session_details`
--
ALTER TABLE `demo_session_details`
  ADD PRIMARY KEY (`session_id`);

--
-- Indexes for table `emails`
--
ALTER TABLE `emails`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `email_accounts`
--
ALTER TABLE `email_accounts`
  ADD PRIMARY KEY (`company_id`);

--
-- Indexes for table `email_channels`
--
ALTER TABLE `email_channels`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_emc_company_email` (`company_id`,`email_address`),
  ADD KEY `idx_emc_company` (`company_id`);

--
-- Indexes for table `engine_version`
--
ALTER TABLE `engine_version`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `events`
--
ALTER TABLE `events`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_event_id` (`event_id`),
  ADD KEY `idx_event_type` (`event_type`),
  ADD KEY `idx_company_id` (`company_id`);

--
-- Indexes for table `facebook_channels`
--
ALTER TABLE `facebook_channels`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_fbc_company` (`company_id`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indexes for table `faqs`
--
ALTER TABLE `faqs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `file_managers`
--
ALTER TABLE `file_managers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `file_managers_origin_type_origin_id_index` (`origin_type`,`origin_id`);

--
-- Indexes for table `gateways`
--
ALTER TABLE `gateways`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `gateways_slug_unique` (`slug`);

--
-- Indexes for table `gateway_currencies`
--
ALTER TABLE `gateway_currencies`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `generated_tokens`
--
ALTER TABLE `generated_tokens`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `gmail_tokens`
--
ALTER TABLE `gmail_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_email` (`user_email`);

--
-- Indexes for table `how_it_works`
--
ALTER TABLE `how_it_works`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `instagram_channels`
--
ALTER TABLE `instagram_channels`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_igc_company` (`company_id`);

--
-- Indexes for table `invoices`
--
ALTER TABLE `invoices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_company_provider_invoice` (`company_id`,`provider_invoice_id`),
  ADD KEY `idx_inv_company` (`company_id`);

--
-- Indexes for table `invoice_line_items`
--
ALTER TABLE `invoice_line_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_invoice_line_items_invoice` (`invoice_id`);

--
-- Indexes for table `knowledge_base`
--
ALTER TABLE `knowledge_base`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_kb_company` (`company_id`),
  ADD KEY `idx_kb_company_status` (`company_id`,`status`),
  ADD KEY `idx_kb_deleted` (`deleted_at`);

--
-- Indexes for table `knowledge_base_sources`
--
ALTER TABLE `knowledge_base_sources`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_company_id` (`company_id`),
  ADD KEY `idx_shopify_id` (`shopify_id`);

--
-- Indexes for table `languages`
--
ALTER TABLE `languages`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `languages_name_unique` (`name`),
  ADD UNIQUE KEY `languages_code_unique` (`code`);

--
-- Indexes for table `language_list`
--
ALTER TABLE `language_list`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `llm_config`
--
ALTER TABLE `llm_config`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `company_id` (`company_id`);

--
-- Indexes for table `media_settings`
--
ALTER TABLE `media_settings`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `message_id` (`message_id`),
  ADD KEY `contact_id` (`contact_id`),
  ADD KEY `source_id` (`source_id`),
  ADD KEY `idx_messages_contact_created` (`contact_id`,`created_at`),
  ADD KEY `idx_messages_is_read` (`is_read`,`contact_id`),
  ADD KEY `idx_messages_contact_id_created` (`contact_id`,`created_at`);

--
-- Indexes for table `message_translations`
--
ALTER TABLE `message_translations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_msg_lang` (`message_id`,`target_language`);

--
-- Indexes for table `metas`
--
ALTER TABLE `metas`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `notification_rules`
--
ALTER TABLE `notification_rules`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_nr_company` (`company_id`),
  ADD KEY `idx_nr_event` (`event_type`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `outlook_connections`
--
ALTER TABLE `outlook_connections`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_email` (`user_email`);

--
-- Indexes for table `packages`
--
ALTER TABLE `packages`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `packages_name_unique` (`name`),
  ADD UNIQUE KEY `packages_slug_unique` (`slug`);

--
-- Indexes for table `partners`
--
ALTER TABLE `partners`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD KEY `password_resets_email_index` (`email`);

--
-- Indexes for table `pdf_documents`
--
ALTER TABLE `pdf_documents`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uid` (`uid`);

--
-- Indexes for table `permission_definitions`
--
ALTER TABLE `permission_definitions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_permission_key` (`permission_key`);

--
-- Indexes for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`);

--
-- Indexes for table `plan_comparison`
--
ALTER TABLE `plan_comparison`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `plan_entitlements`
--
ALTER TABLE `plan_entitlements`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_pe_plan_feature` (`plan_id`,`feature`),
  ADD KEY `idx_pe_plan` (`plan_id`);

--
-- Indexes for table `private_plan_assignments`
--
ALTER TABLE `private_plan_assignments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_plan_company` (`plan_id`,`company_id`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `promo_codes`
--
ALTER TABLE `promo_codes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `promo_code_redemptions`
--
ALTER TABLE `promo_code_redemptions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_company_promo` (`company_id`,`promo_code_id`),
  ADD KEY `promo_code_id` (`promo_code_id`);

--
-- Indexes for table `qa_pairs`
--
ALTER TABLE `qa_pairs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_qa_pairs_company` (`company_id`),
  ADD KEY `idx_qa_pairs_status` (`status`),
  ADD KEY `idx_qa_pairs_company_status` (`company_id`,`status`);

--
-- Indexes for table `qa_pair_conversations`
--
ALTER TABLE `qa_pair_conversations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_qapc_pair` (`qa_pair_id`);

--
-- Indexes for table `rag_config`
--
ALTER TABLE `rag_config`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `response_source`
--
ALTER TABLE `response_source`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `role_permissions`
--
ALTER TABLE `role_permissions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_role_permission` (`role_id`,`permission_key`);

--
-- Indexes for table `search_results`
--
ALTER TABLE `search_results`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `search_result_items`
--
ALTER TABLE `search_result_items`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `segments`
--
ALTER TABLE `segments`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `segment_members`
--
ALTER TABLE `segment_members`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_seg_contact` (`segment_id`,`contact_id`),
  ADD KEY `idx_sm_segment` (`segment_id`),
  ADD KEY `idx_sm_contact` (`contact_id`);

--
-- Indexes for table `settings`
--
ALTER TABLE `settings`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `shopify`
--
ALTER TABLE `shopify`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `shopify_connections`
--
ALTER TABLE `shopify_connections`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_sc_company` (`company_id`),
  ADD KEY `idx_sc_shopify_url` (`shopify_url`);

--
-- Indexes for table `shopify_webhook_log`
--
ALTER TABLE `shopify_webhook_log`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `webhook_id` (`webhook_id`),
  ADD KEY `idx_topic` (`topic`),
  ADD KEY `idx_shop` (`shop_domain`);

--
-- Indexes for table `sma_members`
--
ALTER TABLE `sma_members`
  ADD PRIMARY KEY (`account_no`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `social_channel`
--
ALTER TABLE `social_channel`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `social_channels`
--
ALTER TABLE `social_channels`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_sc_company_channel` (`company_id`,`channel_type`),
  ADD KEY `idx_sc_company` (`company_id`);

--
-- Indexes for table `standard_onboarding`
--
ALTER TABLE `standard_onboarding`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_company_id` (`company_id`),
  ADD KEY `idx_company_id` (`company_id`);

--
-- Indexes for table `subscription_addons`
--
ALTER TABLE `subscription_addons`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `subscription_plans`
--
ALTER TABLE `subscription_plans`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `sub_categories`
--
ALTER TABLE `sub_categories`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `suggested_questions`
--
ALTER TABLE `suggested_questions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ix_suggested_questions_company_id` (`company_id`);

--
-- Indexes for table `system_settings`
--
ALTER TABLE `system_settings`
  ADD PRIMARY KEY (`setting_key`);

--
-- Indexes for table `tags`
--
ALTER TABLE `tags`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_company_tag` (`company_id`,`tag_name`);

--
-- Indexes for table `team_management`
--
ALTER TABLE `team_management`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `telegram_channels`
--
ALTER TABLE `telegram_channels`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `bot_token` (`bot_token`),
  ADD UNIQUE KEY `telegram_id` (`telegram_id`);

--
-- Indexes for table `testimonials`
--
ALTER TABLE `testimonials`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tickets`
--
ALTER TABLE `tickets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `tickets_ticket_no_unique` (`ticket_no`);

--
-- Indexes for table `ticket_replies`
--
ALTER TABLE `ticket_replies`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `ticket_topics`
--
ALTER TABLE `ticket_topics`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ticket_topics_name_unique` (`name`);

--
-- Indexes for table `top_ups`
--
ALTER TABLE `top_ups`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `top_ups_name_unique` (`name`),
  ADD UNIQUE KEY `top_ups_slug_unique` (`slug`);

--
-- Indexes for table `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `transactions_txn_id_unique` (`txn_id`);

--
-- Indexes for table `transaction_log`
--
ALTER TABLE `transaction_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_txn_company` (`company_id`),
  ADD KEY `idx_txn_provider_event` (`provider_event_id`),
  ADD KEY `idx_txn_created` (`created_at`);

--
-- Indexes for table `transfer_ticket`
--
ALTER TABLE `transfer_ticket`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `url_mapping`
--
ALTER TABLE `url_mapping`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `ix_url_mapping_short_code` (`short_code`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`),
  ADD UNIQUE KEY `users_contact_number_unique` (`contact_number`),
  ADD KEY `idx_users_company_role` (`company_role_id`);

--
-- Indexes for table `user_brands`
--
ALTER TABLE `user_brands`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `user_companys`
--
ALTER TABLE `user_companys`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `user_favorites`
--
ALTER TABLE `user_favorites`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `user_numbers`
--
ALTER TABLE `user_numbers`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `user_online_status`
--
ALTER TABLE `user_online_status`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `user_online_status1`
--
ALTER TABLE `user_online_status1`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `user_packages`
--
ALTER TABLE `user_packages`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `user_package_periods`
--
ALTER TABLE `user_package_periods`
  ADD PRIMARY KEY (`id`),
  ADD KEY `plan_id` (`plan_id`);

--
-- Indexes for table `user_relationships`
--
ALTER TABLE `user_relationships`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `user_social_token`
--
ALTER TABLE `user_social_token`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `user_topups`
--
ALTER TABLE `user_topups`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `webchat_channels`
--
ALTER TABLE `webchat_channels`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_wcc_company` (`company_id`);

--
-- Indexes for table `webhook_deliveries`
--
ALTER TABLE `webhook_deliveries`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_delivery_id` (`delivery_id`),
  ADD KEY `idx_wd_subscription` (`subscription_id`),
  ADD KEY `idx_wd_event` (`event_id`),
  ADD KEY `idx_wd_retry` (`status`,`next_retry_at`,`attempt`);

--
-- Indexes for table `webhook_subscriptions`
--
ALTER TABLE `webhook_subscriptions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_subscription_id` (`subscription_id`),
  ADD KEY `idx_ws_company` (`company_id`);

--
-- Indexes for table `whatsapp_channels`
--
ALTER TABLE `whatsapp_channels`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ix_whatsapp_channels_company_id` (`company_id`);

--
-- Indexes for table `wordpress_channels`
--
ALTER TABLE `wordpress_channels`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_wpc_company` (`company_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admin_roles`
--
ALTER TABLE `admin_roles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `agent_llm_config`
--
ALTER TABLE `agent_llm_config`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `bot_setting`
--
ALTER TABLE `bot_setting`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `brands`
--
ALTER TABLE `brands`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `channel_settings`
--
ALTER TABLE `channel_settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `chat_categories`
--
ALTER TABLE `chat_categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `company_addons`
--
ALTER TABLE `company_addons`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `company_billing_info`
--
ALTER TABLE `company_billing_info`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `company_credits`
--
ALTER TABLE `company_credits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `company_onboarding`
--
ALTER TABLE `company_onboarding`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `company_roles`
--
ALTER TABLE `company_roles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `company_subscriptions`
--
ALTER TABLE `company_subscriptions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `company_type`
--
ALTER TABLE `company_type`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `contacts`
--
ALTER TABLE `contacts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `contacts_geo`
--
ALTER TABLE `contacts_geo`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `contact_company_data`
--
ALTER TABLE `contact_company_data`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `contact_messages`
--
ALTER TABLE `contact_messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `contact_tags`
--
ALTER TABLE `contact_tags`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `credit_packs`
--
ALTER TABLE `credit_packs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `credit_tiers`
--
ALTER TABLE `credit_tiers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `credit_usage_log`
--
ALTER TABLE `credit_usage_log`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `currencies`
--
ALTER TABLE `currencies`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `daily_click_counts`
--
ALTER TABLE `daily_click_counts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `dashboard_settings`
--
ALTER TABLE `dashboard_settings`
  MODIFY `id` int(12) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `emails`
--
ALTER TABLE `emails`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `email_channels`
--
ALTER TABLE `email_channels`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `engine_version`
--
ALTER TABLE `engine_version`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `events`
--
ALTER TABLE `events`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `facebook_channels`
--
ALTER TABLE `facebook_channels`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `faqs`
--
ALTER TABLE `faqs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `file_managers`
--
ALTER TABLE `file_managers`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `gateways`
--
ALTER TABLE `gateways`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `gateway_currencies`
--
ALTER TABLE `gateway_currencies`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `generated_tokens`
--
ALTER TABLE `generated_tokens`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `gmail_tokens`
--
ALTER TABLE `gmail_tokens`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `how_it_works`
--
ALTER TABLE `how_it_works`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `instagram_channels`
--
ALTER TABLE `instagram_channels`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `invoices`
--
ALTER TABLE `invoices`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `invoice_line_items`
--
ALTER TABLE `invoice_line_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `knowledge_base`
--
ALTER TABLE `knowledge_base`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `knowledge_base_sources`
--
ALTER TABLE `knowledge_base_sources`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `languages`
--
ALTER TABLE `languages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `language_list`
--
ALTER TABLE `language_list`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `llm_config`
--
ALTER TABLE `llm_config`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `media_settings`
--
ALTER TABLE `media_settings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `message_translations`
--
ALTER TABLE `message_translations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `metas`
--
ALTER TABLE `metas`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notification_rules`
--
ALTER TABLE `notification_rules`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `outlook_connections`
--
ALTER TABLE `outlook_connections`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `packages`
--
ALTER TABLE `packages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `partners`
--
ALTER TABLE `partners`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pdf_documents`
--
ALTER TABLE `pdf_documents`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `permission_definitions`
--
ALTER TABLE `permission_definitions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `plan_comparison`
--
ALTER TABLE `plan_comparison`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `plan_entitlements`
--
ALTER TABLE `plan_entitlements`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `private_plan_assignments`
--
ALTER TABLE `private_plan_assignments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `promo_codes`
--
ALTER TABLE `promo_codes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `promo_code_redemptions`
--
ALTER TABLE `promo_code_redemptions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `qa_pairs`
--
ALTER TABLE `qa_pairs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `qa_pair_conversations`
--
ALTER TABLE `qa_pair_conversations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `rag_config`
--
ALTER TABLE `rag_config`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `response_source`
--
ALTER TABLE `response_source`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `roles`
--
ALTER TABLE `roles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `role_permissions`
--
ALTER TABLE `role_permissions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `search_results`
--
ALTER TABLE `search_results`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `search_result_items`
--
ALTER TABLE `search_result_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `segment_members`
--
ALTER TABLE `segment_members`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `settings`
--
ALTER TABLE `settings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `shopify`
--
ALTER TABLE `shopify`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `shopify_connections`
--
ALTER TABLE `shopify_connections`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `shopify_webhook_log`
--
ALTER TABLE `shopify_webhook_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `social_channel`
--
ALTER TABLE `social_channel`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `social_channels`
--
ALTER TABLE `social_channels`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `standard_onboarding`
--
ALTER TABLE `standard_onboarding`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sub_categories`
--
ALTER TABLE `sub_categories`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `suggested_questions`
--
ALTER TABLE `suggested_questions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tags`
--
ALTER TABLE `tags`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `team_management`
--
ALTER TABLE `team_management`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `telegram_channels`
--
ALTER TABLE `telegram_channels`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `testimonials`
--
ALTER TABLE `testimonials`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tickets`
--
ALTER TABLE `tickets`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ticket_replies`
--
ALTER TABLE `ticket_replies`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ticket_topics`
--
ALTER TABLE `ticket_topics`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `top_ups`
--
ALTER TABLE `top_ups`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `transaction_log`
--
ALTER TABLE `transaction_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `transfer_ticket`
--
ALTER TABLE `transfer_ticket`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `url_mapping`
--
ALTER TABLE `url_mapping`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_brands`
--
ALTER TABLE `user_brands`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_companys`
--
ALTER TABLE `user_companys`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_favorites`
--
ALTER TABLE `user_favorites`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_numbers`
--
ALTER TABLE `user_numbers`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_online_status`
--
ALTER TABLE `user_online_status`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_online_status1`
--
ALTER TABLE `user_online_status1`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_packages`
--
ALTER TABLE `user_packages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_package_periods`
--
ALTER TABLE `user_package_periods`
  MODIFY `id` int(12) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_relationships`
--
ALTER TABLE `user_relationships`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_social_token`
--
ALTER TABLE `user_social_token`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_topups`
--
ALTER TABLE `user_topups`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `webchat_channels`
--
ALTER TABLE `webchat_channels`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `webhook_deliveries`
--
ALTER TABLE `webhook_deliveries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `webhook_subscriptions`
--
ALTER TABLE `webhook_subscriptions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `whatsapp_channels`
--
ALTER TABLE `whatsapp_channels`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `wordpress_channels`
--
ALTER TABLE `wordpress_channels`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `broadcast_recipients`
--
ALTER TABLE `broadcast_recipients`
  ADD CONSTRAINT `fk_recipients_broadcast` FOREIGN KEY (`broadcast_id`) REFERENCES `broadcasts` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `contacts_geo`
--
ALTER TABLE `contacts_geo`
  ADD CONSTRAINT `contacts_geo_ibfk_1` FOREIGN KEY (`contact_id`) REFERENCES `contacts` (`id`);

--
-- Constraints for table `contact_tags`
--
ALTER TABLE `contact_tags`
  ADD CONSTRAINT `contact_tags_ibfk_1` FOREIGN KEY (`contact_id`) REFERENCES `contacts` (`id`),
  ADD CONSTRAINT `contact_tags_ibfk_2` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`);

--
-- Constraints for table `daily_click_counts`
--
ALTER TABLE `daily_click_counts`
  ADD CONSTRAINT `daily_click_counts_ibfk_1` FOREIGN KEY (`url_id`) REFERENCES `url_mapping` (`id`);

--
-- Constraints for table `invoice_line_items`
--
ALTER TABLE `invoice_line_items`
  ADD CONSTRAINT `invoice_line_items_ibfk_1` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`contact_id`) REFERENCES `contacts` (`id`),
  ADD CONSTRAINT `messages_ibfk_2` FOREIGN KEY (`source_id`) REFERENCES `response_source` (`id`);

--
-- Constraints for table `message_translations`
--
ALTER TABLE `message_translations`
  ADD CONSTRAINT `message_translations_ibfk_1` FOREIGN KEY (`message_id`) REFERENCES `messages` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `private_plan_assignments`
--
ALTER TABLE `private_plan_assignments`
  ADD CONSTRAINT `private_plan_assignments_ibfk_1` FOREIGN KEY (`plan_id`) REFERENCES `subscription_plans` (`id`);

--
-- Constraints for table `promo_code_redemptions`
--
ALTER TABLE `promo_code_redemptions`
  ADD CONSTRAINT `promo_code_redemptions_ibfk_1` FOREIGN KEY (`promo_code_id`) REFERENCES `promo_codes` (`id`);

--
-- Constraints for table `role_permissions`
--
ALTER TABLE `role_permissions`
  ADD CONSTRAINT `role_permissions_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `company_roles` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
