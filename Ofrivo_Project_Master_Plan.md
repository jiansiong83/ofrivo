# Ofrivo 项目完整执行基线

> **项目定位：** 本地服务 Job Bid 平台  
> **核心流程：** 顾客发布 Job → 技工报价 → 顾客选择 → 完成服务 → 双向评价  
> **首发地区：** Johor Bahru, Malaysia  
> **当前阶段：** Android 雏形 + 云后端 + Admin Web  
> **技术路线：** Flutter + Supabase + Next.js  
> **品牌名称：** Ofrivo  
> **品牌含义：** Offers for every job  
> **建议标语：** Post a job. Compare offers. Get it done.

---

# 1. 项目目标

Ofrivo 是一个本地服务任务报价平台。

顾客发布需要处理的任务，例如：

- 通厕所
- 修水喉
- 装灯
- 装风扇
- 冷气维修
- 搬运
- 清洁
- Handyman 小维修

经过审核的技工可以在 Job Feed 中直接看到：

- 顾客需要什么服务
- 大概地区
- 顾客预算
- 需要时间
- 已有多少人报价

技工提交自己的价格和服务说明，顾客比较报价、评分、时间和验证状态后，自主选择一个技工。

第一阶段需要验证：

1. 顾客愿不愿意发布 Job。
2. 技工愿不愿意查看 Job Feed。
3. 技工愿不愿意提交报价。
4. 每个 Job 能否收到至少 2 个报价。
5. 顾客是否愿意选择其中一个报价。
6. 上门服务的安全、投诉和乱加价问题能否控制。
7. 技工未来是否愿意为有效 Job 付费。

---

# 2. 品牌基线

## 2.1 品牌名称

```text
Ofrivo
```

品牌解释：

```text
Offers for every job
```

## 2.2 品牌文案

英文主标语：

```text
Post a job. Compare offers. Get it done.
```

英文短标语：

```text
Your job. Their offer. Your choice.
```

中文：

```text
发布任务，比较报价，选择合适的人完成。
```

## 2.3 正式上线前仍需检查

在注册公司、商标、域名或上传 Google Play 前，继续完成正式查名：

- MyIPO 商标
- SSM 公司名称
- Google Play
- Apple App Store
- `.com`
- `.my`
- `.app`
- Facebook
- Instagram
- TikTok
- YouTube Handle

在正式确认前，不要上传最终包名到 Google Play。

---

# 3. 第一版服务范围

首版只做 6 类服务：

1. **Plumbing / Toilet**  
   水喉、漏水、通厕所

2. **Electrical**  
   装灯、装风扇、电线、小型电工

3. **Air Conditioning**  
   清洗、检查、维修

4. **Moving / Delivery**  
   搬家具、搬电器、小型载货

5. **Cleaning**  
   房屋、店面、空屋清洁

6. **Handyman**  
   装架子、装柜、小型维修

## 第一版不开放

- 开锁
- 保姆
- 医疗护理
- 陪同服务
- 私人司机
- 金融服务
- 借贷
- 高金额装修
- 高风险工程
- 需要特殊执照的专业服务

---

# 4. MVP 必须完成

## 4.1 顾客功能

- 注册和登录
- 修改个人资料
- 发布 Job
- 上传 1–5 张照片
- 选择服务类别
- 填写大概地区
- 填写完整地址
- 设置预算
- 设置日期和时间
- 查看自己的 Job
- 查看收到的报价
- 查看技工资料
- 接受一个报价
- 查看中标技工联系方式
- 标记 Job 开始
- 标记 Job 完成
- 评价技工
- 举报技工
- 取消 Job

## 4.2 技工功能

- 普通账号注册
- 申请成为技工
- 填写服务简介
- 选择服务类别
- 选择服务地区
- 上传身份验证资料
- 上传工作案例
- 查看审核状态
- 审核通过后查看 Job Feed
- 筛选 Job
- 查看 Job 详情
- 提交报价
- 修改 pending 报价
- 撤回 pending 报价
- 查看自己的报价
- 查看已中标 Job
- 查看完整地址和联系方式
- 标记开始工作
- 查看评价
- 评价顾客
- 举报顾客

## 4.3 Admin 功能

- Admin 登录
- Dashboard
- 审核技工
- 查看身份验证资料
- 批准或拒绝技工
- 暂停技工
- 暂停顾客
- 查看所有 Job
- 查看所有 Bid
- 查看投诉
- 处理投诉
- 管理服务类别
- 管理地区
- 查看 Audit Log
- 查看基础统计

---

# 5. 第一版不做

- App 内付款
- Escrow
- Wallet
- App 内聊天
- 实时 GPS
- 自动派单
- Google Maps 路线
- AI 报价
- 会员
- Bid Credit
- Referral
- 优惠券
- iOS 正式发布
- 多城市
- 全国推广
- 复杂商业报表

---

# 6. 最终技术架构

## 6.1 Mobile App

```text
Flutter
Dart
Riverpod
go_router
Supabase Flutter SDK
Firebase Cloud Messaging
```

用途：

- 顾客模式
- 技工模式
- Job Feed
- 发布 Job
- 报价
- 图片上传
- Job 状态
- 推送通知

## 6.2 Backend

```text
Supabase
PostgreSQL
Supabase Auth
Supabase Storage
Supabase Realtime
PostgreSQL RPC Functions
Supabase Edge Functions
Row Level Security
```

Supabase 负责：

- 用户登录
- 数据库
- 文件储存
- API
- 数据权限
- Job 和 Bid 数据
- 关键交易逻辑
- 即时数据更新
- 推送通知触发

## 6.3 Admin Web

```text
Next.js
TypeScript
Tailwind CSS
Supabase JavaScript SDK
Vercel
```

Admin 独立做成 Web，不放进用户 App。

## 6.4 总架构

```text
Ofrivo Flutter App
├── Customer Mode
├── Provider Mode
└── Shared Account/Profile
        │
        ▼
Supabase Backend
├── Auth
├── PostgreSQL
├── Storage
├── Realtime
├── RPC
├── Edge Functions
└── RLS
        │
        ├── Firebase Cloud Messaging
        │
        └── Ofrivo Admin Web
```

---

# 7. Supabase 项目配置

继续使用现有 Supabase 账号，但建立独立 Project：

```text
ofrivo-dev
```

不要和百家乐网站共用同一个 Supabase Project。

建议结构：

```text
Supabase Account
├── Baccarat Project
└── ofrivo-dev
```

Ofrivo 独立拥有：

- Database
- Auth
- Storage
- API Keys
- Edge Functions
- RLS Policies
- Logs

正式公开前，再考虑建立：

```text
ofrivo-prod
```

当前阶段只需要：

```text
ofrivo-dev
```

---

# 8. 账号与角色设计

不要把用户永久锁死成 Customer 或 Provider。

正确设计：

> 所有注册用户默认都可以发布 Job。  
> 用户通过申请和审核后，可以额外成为 Provider。

## 普通用户可以

- 发布 Job
- 查看自己的 Job
- 接受报价
- 完成 Job
- 评价
- 举报

## 审核通过的 Provider 额外可以

- 切换到 Provider Mode
- 查看 Job Feed
- 提交 Bid
- 查看中标 Job
- 管理技工资料

## Admin

Admin 不通过普通 App 操作，使用独立 Web 后台。

---

# 9. App 模式设计

## 9.1 顾客模式底部导航

```text
Home
Post Job
My Jobs
Profile
```

## 9.2 技工模式底部导航

```text
Job Feed
My Bids
Assigned
Profile
```

## 9.3 模式切换

只有审核通过的 Provider 才显示：

```text
Switch to Provider Mode
```

普通用户看不到技工模式入口。

---

# 10. 核心状态设计

## Provider Verification

```text
not_applied
pending
approved
rejected
suspended
```

## Job Status

```text
draft
open
assigned
in_progress
completed
cancelled
expired
```

## Bid Status

```text
pending
accepted
rejected
withdrawn
expired
```

## Report Status

```text
open
reviewing
resolved
dismissed
```

## Account Status

```text
active
suspended
deleted
```

状态值必须使用数据库约束，不允许 App 自由输入任意字符串。

---

# 11. 页面结构

## 11.1 公共页面

```text
Splash
Onboarding
Login
Register
Forgot Password
Terms
Privacy Policy
Profile
Edit Profile
Notification Centre
Account Suspended
```

## 11.2 顾客页面

```text
Customer Home
Post Job
Post Job Preview
My Jobs
Job Detail
Received Bids
Provider Profile
Accepted Job Detail
Complete Job
Write Review
Submit Report
Cancel Job
```

## 11.3 技工申请页面

```text
Become a Provider
Provider Information
Select Categories
Select Service Areas
Upload IC
Upload Selfie
Upload Work Photos
Application Preview
Verification Status
Verification Rejected
```

## 11.4 技工页面

```text
Provider Home / Job Feed
Job Filters
Job Detail
Submit Bid
Edit Bid
My Bids
Assigned Jobs
Assigned Job Detail
Provider Profile
Availability Settings
Reviews
```

## 11.5 Admin 页面

```text
Dashboard
Pending Providers
Provider Detail
Users
Jobs
Job Detail
Bids
Reports
Report Detail
Categories
Areas
Audit Log
System Settings
```

---

# 12. 顾客发布 Job 流程

顾客填写：

- 服务类别
- 标题
- 问题描述
- 1–5 张照片
- 大概地区
- 完整地址
- 预算
- 服务日期
- 时间段
- 是否急单
- 联系号码

## Job Feed 可公开字段

审核通过的技工可以看到：

- 服务类别
- 标题
- 描述
- Job 照片
- 大概地区
- 顾客预算
- 日期
- 时间
- 是否急单
- Bid 数量

## 隐藏字段

未中标技工不能看到：

- 完整地址
- 门牌号码
- 顾客电话
- 顾客 WhatsApp
- 精确 GPS
- 其他隐私资料

中标后才开放。

---

# 13. 技工 Job Feed

## Job Card 内容

```text
[Urgent]
Toilet blockage
Plumbing / Toilet

Mount Austin
Customer budget: RM100
Today, 2pm–6pm
3 offers received

View details
```

## 筛选

- 类别
- 地区
- 日期
- 预算
- 急单
- 最新
- 尚无报价
- 高预算

## 报价隐私

技工只能看到：

```text
3 offers received
```

不能看到其他技工报价金额。

---

# 14. Bid 表单

技工必须填写：

- 报价金额
- 最早到达时间
- 报价包含什么
- 报价不包含什么
- 材料是否另算
- 额外说明

例子：

```text
Price: RM120
Available: Today, 5pm
Includes: Inspection and labour
Excludes: Materials and wall hacking
Note: Any additional cost will be confirmed before work starts.
```

---

# 15. 接受 Bid 的正确流程

顾客接受 Bid 时，不能由 Flutter 连续执行多个 update。

必须调用数据库 RPC，并在同一个事务中完成。

## `accept_bid` RPC

执行：

1. 检查当前用户是 Job owner。
2. 锁定 Job row，避免并发。
3. 检查 Job 状态是 `open`。
4. 检查目标 Bid 状态是 `pending`。
5. 将目标 Bid 改成 `accepted`。
6. 将其他 Bid 改成 `rejected`。
7. 将 Job 改成 `assigned`。
8. 写入 `accepted_bid_id`。
9. 写入 `job_events`。
10. 返回处理结果。

---

# 16. Job 生命周期

```text
draft
  ↓
open
  ↓
assigned
  ↓
in_progress
  ↓
completed
```

其他路径：

```text
open → cancelled
open → expired
assigned → cancelled
in_progress → report
```

## `start_job` RPC

```text
assigned → in_progress
```

## `complete_job` RPC

```text
Job → completed
Provider completed_jobs +1
允许双方评价
写入 job_events
```

## `cancel_job` RPC

- `open`：顾客可以取消
- `assigned`：取消要记录责任方
- `in_progress`：需要确认或举报
- `completed`：不能取消

---

# 17. UI 设计系统

## 17.1 视觉方向

```text
Reliable
Clear
Professional
Local
Safe
Simple
```

避免：

- 太多渐变
- 游戏化设计
- 复杂动画
- 太多颜色
- 小字太密
- 博彩风格
- 金融交易风格
- 廉价分类广告感

## 17.2 色彩建议

```text
Primary: Deep teal / dark blue-green
Secondary: Blue
Success: Green
Warning: Orange
Danger: Red
Background: Light grey-white
Surface: White
Text Primary: Dark grey
Text Secondary: Medium grey
```

## 17.3 状态颜色

```text
Open: Green
Assigned: Blue
In Progress: Purple
Completed: Grey
Cancelled: Red
Pending: Orange
Verified: Green
```

## 17.4 核心组件

```text
AppScaffold
PrimaryButton
SecondaryButton
DangerButton
JobCard
BidCard
ProviderCard
StatusBadge
VerifiedBadge
CategoryChip
AreaChip
BudgetInput
DateTimeSelector
PhotoUploader
ProfileAvatar
RatingSummary
EmptyState
ErrorState
LoadingSkeleton
ConfirmationDialog
ReportDialog
FilterBottomSheet
```

## 17.5 每页必须考虑的状态

- Loading
- Empty
- Error
- Offline
- Permission denied
- Account suspended
- Verification pending
- Verification rejected
- No bids
- Job expired
- Bid withdrawn
- Job already assigned
- Upload failed
- Network retry

---

# 18. UI 先行执行方式

## Step UI-1：Screen Map

整理所有页面和跳转。

## Step UI-2：Low-Fidelity Wireframe

确认：

- 页面信息顺序
- 按钮位置
- 表单字段
- Job Card 内容
- Bid Card 内容
- Bottom Navigation
- 模式切换

## Step UI-3：Design System

完成：

- 色彩
- 字体
- 间距
- 卡片
- 按钮
- 输入框
- 图标
- 状态
- 图片比例

## Step UI-4：Fake Data Prototype

先不连接 Supabase。

用假数据跑通：

- 顾客首页
- 发布 Job
- Job Detail
- Bid List
- 技工 Job Feed
- Submit Bid
- 技工申请
- Verification Status
- Assigned Job

UI、导航和体验确认后，才接后端。

---

# 19. 数据库设计

## 19.1 `profiles`

```sql
profiles
- id uuid primary key references auth.users(id)
- full_name text
- display_name text
- phone text
- whatsapp text
- avatar_path text
- account_status text
- created_at timestamptz
- updated_at timestamptz
```

## 19.2 `provider_profiles`

```sql
provider_profiles
- user_id uuid primary key references profiles(id)
- bio text
- verification_status text
- rating_average numeric
- rating_count integer
- completed_jobs integer
- is_available boolean
- approved_at timestamptz
- suspended_at timestamptz
- created_at timestamptz
- updated_at timestamptz
```

## 19.3 `service_categories`

```sql
service_categories
- id uuid primary key
- slug text unique
- name_en text
- name_ms text
- name_zh text
- icon_name text
- is_active boolean
- sort_order integer
```

## 19.4 `areas`

```sql
areas
- id uuid primary key
- state text
- city text
- area_name text
- is_active boolean
- sort_order integer
```

## 19.5 `provider_categories`

```sql
provider_categories
- provider_id uuid
- category_id uuid
- primary key(provider_id, category_id)
```

## 19.6 `provider_areas`

```sql
provider_areas
- provider_id uuid
- area_id uuid
- primary key(provider_id, area_id)
```

## 19.7 `provider_verifications`

```sql
provider_verifications
- id uuid primary key
- provider_id uuid
- ic_front_path text
- ic_back_path text
- selfie_path text
- ssm_path text
- certificate_paths jsonb
- status text
- admin_note text
- submitted_at timestamptz
- reviewed_at timestamptz
- reviewed_by uuid
```

## 19.8 `jobs`

```sql
jobs
- id uuid primary key
- customer_id uuid
- category_id uuid
- area_id uuid
- title text
- description text
- public_location_text text
- full_address text
- budget_amount numeric
- scheduled_at timestamptz
- time_window text
- urgency text
- status text
- accepted_bid_id uuid
- contact_phone text
- contact_whatsapp text
- created_at timestamptz
- updated_at timestamptz
- expires_at timestamptz
```

## 19.9 `job_photos`

```sql
job_photos
- id uuid primary key
- job_id uuid
- storage_path text
- sort_order integer
- created_at timestamptz
```

## 19.10 `bids`

```sql
bids
- id uuid primary key
- job_id uuid
- provider_id uuid
- amount numeric
- available_at timestamptz
- inclusions text
- exclusions text
- materials_note text
- message text
- status text
- created_at timestamptz
- updated_at timestamptz
```

限制：

```text
同一个 Provider 对同一个 Job 只能有一个有效 Bid。
```

## 19.11 `reviews`

```sql
reviews
- id uuid primary key
- job_id uuid
- reviewer_id uuid
- reviewee_id uuid
- rating integer
- comment text
- created_at timestamptz
```

限制：

```text
每个用户对同一个 Job 只能评价对方一次。
Rating 必须是 1–5。
```

## 19.12 `reports`

```sql
reports
- id uuid primary key
- job_id uuid
- reporter_id uuid
- reported_user_id uuid
- reason_code text
- description text
- evidence_paths jsonb
- status text
- admin_note text
- created_at timestamptz
- resolved_at timestamptz
```

## 19.13 `notifications`

```sql
notifications
- id uuid primary key
- user_id uuid
- type text
- title text
- body text
- reference_type text
- reference_id uuid
- is_read boolean
- created_at timestamptz
```

## 19.14 `device_tokens`

```sql
device_tokens
- id uuid primary key
- user_id uuid
- token text unique
- platform text
- last_seen_at timestamptz
- created_at timestamptz
```

## 19.15 `job_events`

```sql
job_events
- id uuid primary key
- job_id uuid
- actor_id uuid
- event_type text
- metadata jsonb
- created_at timestamptz
```

事件例子：

```text
job_created
job_published
bid_submitted
bid_updated
bid_withdrawn
bid_accepted
job_started
job_completed
job_cancelled
job_expired
report_created
```

---

# 20. 数据库约束和 Index

## Constraints

- Budget > 0
- Bid amount > 0
- Rating between 1 and 5
- Valid status values
- Valid urgency values
- accepted_bid_id 必须属于该 Job
- Provider 必须 approved 才能 Bid
- 同一个 Provider 同一个 Job 只能有一个有效 Bid

## Indexes

```text
jobs(status, created_at)
jobs(category_id, area_id, status)
jobs(customer_id, created_at)
bids(job_id, status)
bids(provider_id, created_at)
provider_profiles(verification_status)
notifications(user_id, is_read, created_at)
reports(status, created_at)
job_events(job_id, created_at)
```

---

# 21. Storage 配置

建立 4 个 bucket：

```text
avatars
job-photos
provider-verifications
report-evidence
```

## `avatars`

- 可以公开读取
- 用户只能修改自己的头像

## `job-photos`

- 不使用永久 Public URL
- 使用 Storage Policy
- 顾客可以管理自己 Job 的照片
- 审核技工可以读取 Open Job 照片
- Job 删除后应清理文件

## `provider-verifications`

必须 Private。

只有：

- Provider 本人
- Admin

可以读取。

Admin 查看时使用短时间 Signed URL。

## `report-evidence`

必须 Private。

只有：

- 举报人
- Admin

可以读取。

## 图片安全

上传前：

- 压缩图片
- 限制分辨率
- 限制单张大小
- 只允许指定文件类型
- 限制上传数量
- 尽量移除 EXIF
- 移除 GPS Metadata

---

# 22. Row Level Security

所有表必须启用 RLS。

## Profiles

用户：

- 可以看自己的完整资料
- 可以修改自己的资料

其他用户：

- 只能看公开 Profile View
- 不能看到电话、WhatsApp、账号状态等隐私字段

## Jobs

顾客：

- 可以建立自己的 Job
- 可以看自己的全部 Job
- 可以修改 `draft` 或 `open` Job
- 可以取消自己的 Job

审核技工：

- 可以查看 `open` Job 的公开信息
- 看不到 `full_address`
- 看不到联系电话

中标技工：

- 可以读取指定 Job 的完整地址
- 可以读取联系方式

普通用户：

- 不能读取全部 Job Feed

## Bids

Provider：

- 只能建立自己的 Bid
- 只能修改自己的 pending Bid
- 只能撤回自己的 pending Bid
- 不能看其他 Provider 的报价金额

顾客：

- 只能查看自己 Job 收到的 Bid

## Provider Verification

只有：

- Provider 本人
- Admin

可以访问。

## Service Role Key

`service_role` 只能放在：

- Edge Functions
- Admin Server
- 安全环境变量

绝对不能放在 Flutter App。

Flutter App 只使用：

```text
SUPABASE_URL
SUPABASE_ANON_KEY
```

---

# 23. 登录方案

雏形阶段使用：

```text
Email + Password
```

同时收集：

- 手机号码
- WhatsApp

暂时不做 SMS OTP。

后期加入：

- Phone OTP
- Google Sign-In
- Apple Sign-In

---

# 24. 推送通知

FCM 在核心流程稳定后接入。

## 新 Job

发送给：

- Provider approved
- 选择相关 Category
- 选择相关 Area
- is_available = true

例子：

```text
New job in Mount Austin
Toilet blockage · Budget RM100
```

## 新 Bid

```text
Your job received a new offer
Offer amount: RM120
```

## Bid Accepted

```text
Your offer has been accepted
The customer address and contact details are now available.
```

## 其他通知

- Provider approved
- Provider rejected
- Job cancelled
- Job expiring
- Review received
- Report updated
- Account suspended

---

# 25. Flutter 项目结构

```text
apps/mobile/
└── lib/
    ├── main.dart
    ├── app.dart
    ├── core/
    │   ├── config/
    │   ├── router/
    │   ├── theme/
    │   ├── errors/
    │   ├── constants/
    │   └── utils/
    ├── data/
    │   ├── models/
    │   ├── repositories/
    │   └── services/
    ├── features/
    │   ├── auth/
    │   ├── onboarding/
    │   ├── profile/
    │   ├── customer_jobs/
    │   ├── provider_application/
    │   ├── provider_feed/
    │   ├── bids/
    │   ├── assigned_jobs/
    │   ├── reviews/
    │   ├── reports/
    │   └── notifications/
    ├── shared/
    │   ├── widgets/
    │   ├── forms/
    │   └── extensions/
    └── l10n/
```

## 建议 Packages

```text
flutter_riverpod
go_router
supabase_flutter
image_picker
cached_network_image
intl
freezed
json_serializable
flutter_image_compress
connectivity_plus
```

---

# 26. Repository 结构

```text
ofrivo/
├── apps/
│   ├── mobile/
│   └── admin/
├── supabase/
│   ├── migrations/
│   ├── functions/
│   ├── seed.sql
│   └── config.toml
├── docs/
│   ├── PROJECT_STATUS.md
│   ├── PRODUCT_SCOPE.md
│   ├── UI_SPEC.md
│   ├── SCREEN_MAP.md
│   ├── DATA_MODEL.md
│   ├── SECURITY.md
│   ├── TEST_PLAN.md
│   ├── CHANGELOG.md
│   └── RELEASE_CHECKLIST.md
├── assets/
│   ├── branding/
│   ├── icons/
│   └── mockups/
└── README.md
```

---

# 27. 环境变量

## Flutter

```text
SUPABASE_URL
SUPABASE_ANON_KEY
APP_ENV=development
```

## Admin

```text
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
```

`SUPABASE_SERVICE_ROLE_KEY` 只能存在 Vercel Server Environment。

## Edge Functions

```text
FCM_PROJECT_ID
FCM_CLIENT_EMAIL
FCM_PRIVATE_KEY
```

---

# 28. 开发阶段

## Step 0：项目文档和 UI

完成：

- Product Scope
- Screen Map
- Database Draft
- UI Wireframe
- UI Design System
- Fake Data Prototype

不接 Supabase。

## Step 1：Repository 骨架

建立：

- Git Repository
- Flutter Project
- Next.js Admin
- Supabase Project
- 文件结构
- Theme
- Router
- Riverpod
- 环境变量
- 基础 CI

## Step 2：Supabase Database

完成：

- Migrations
- Constraints
- Foreign Keys
- Indexes
- Storage Buckets
- RLS 初版
- Seed Data
- Test Accounts

## Step 3：Authentication

完成：

- Register
- Login
- Logout
- Forgot Password
- Profile Creation
- Edit Profile
- Account Suspended State

## Step 4：顾客发布 Job

完成：

- Post Job Form
- 图片上传
- Draft
- Preview
- Publish
- My Jobs
- Job Detail
- Cancel Job

## Step 5：Provider Application

完成：

- Provider Information
- Categories
- Areas
- Verification Upload
- Work Photos
- Pending UI
- Approved UI
- Rejected UI

## Step 6：Provider Job Feed

完成：

- Feed
- Filters
- Job Detail
- Hide Full Address
- Submit Bid
- Edit Bid
- Withdraw Bid
- My Bids

## Step 7：Accept Bid

完成：

- Received Bid List
- Provider Profile
- Transactional `accept_bid`
- Reject Other Bids
- Address Reveal
- Job Assigned State
- Notifications

## Step 8：Job Completion

完成：

- Start Job
- Complete Job
- Cancel Assigned Job
- Review
- Report
- Job Event Log

## Step 9：Admin Web

完成：

- Admin Login
- Dashboard
- Provider Verification
- Users
- Jobs
- Bids
- Reports
- Suspend Account
- Audit Log

## Step 10：Push Notification

完成：

- Device Token
- New Job
- New Bid
- Bid Accepted
- Verification Result
- Job Expiring

## Step 11：Security and Testing

完成：

- RLS Test
- Storage Permission Test
- Multiple Account Test
- Concurrent Accept Bid Test
- Error State
- Offline State
- Crash Handling
- Image Validation

## Step 12：Closed Beta

完成：

- Signed APK / AAB
- Google Play Internal Test
- Closed Test
- Test Accounts
- Test Jobs
- Bug Report Process
- Rollback Build

---

# 29. 测试计划

## Unit Tests

- Budget validation
- Bid amount validation
- Job status transition
- Bid status transition
- Date validation
- Provider eligibility
- Rating calculation
- Job expiry
- Contact reveal eligibility

## Widget Tests

- Login Form
- Post Job Form
- Job Card
- Bid Card
- Provider Verification
- Filter Bottom Sheet
- Empty State
- Error State
- Loading State

## Integration Test

```text
Customer registration
→ Post Job
→ Provider application
→ Admin approval
→ Provider sees Job
→ Provider submits Bid
→ Customer sees Bid
→ Customer accepts Bid
→ Provider sees address
→ Job starts
→ Job completes
→ Both users review
```

## RLS Security Test

建立：

```text
Customer A
Customer B
Provider A
Provider B
Pending Provider
Suspended User
Admin
```

验证：

- Customer A 看不到 Customer B 的私密资料
- Provider A 看不到 Provider B 的 Bid 金额
- 未审核 Provider 不能 Bid
- 中标前看不到地址
- 中标后只能看自己的 Assigned Job 地址
- Verification 文件不能公开
- 普通用户不能调用 Admin 操作
- Flutter App 无 Service Role
- Suspended User 无法继续发布或 Bid

## 并发测试

两个设备同时接受不同 Bid：

- 只能有一个 Bid 成功
- 不能出现两个中标技工
- Job 和 accepted_bid_id 必须一致
- 其他 Bid 必须 rejected

---

# 30. 安全基线

必须完成：

- 全表 RLS
- Private Verification Bucket
- Private Evidence Bucket
- Signed URL
- 图片压缩
- EXIF 移除
- Address Reveal 限制
- Provider 审核后才能 Bid
- Bid Acceptance Transaction
- Audit Log
- Suspended Account Enforcement
- Rate Limiting 预留
- 举报和封号
- 不在 App 保存 Service Role Key

---

# 31. 数据与隐私

平台处理：

- 姓名
- 手机号码
- WhatsApp
- 地址
- Job 照片
- IC
- 自拍
- 工作照片
- 举报证据
- 评价
- 订单记录

正式上线前需要：

- Privacy Policy
- Terms of Service
- Provider Agreement
- Independent Contractor Disclaimer
- Data Retention Policy
- Account Deletion Flow
- Report and Appeal Process

---

# 32. 费用基线

开发雏形阶段：

```text
Supabase Free
Firebase Free
Vercel Free
Flutter Local Build
```

初期系统费用可以接近：

```text
RM0
```

可能费用：

- Google Play Console
- Domain
- 图标或 UI 素材
- Apple Developer 后期才需要

Supabase 升级时机：

- 开始有真实顾客资料
- 需要稳定备份
- 图片和流量明显增加
- 投资人长期测试
- 正式公开 Beta
- 免费额度接近上限

---

# 33. 雏形完成标准

以下全部通过，才算完成：

- 顾客可以注册
- 顾客可以发布 Job
- Job 图片上传成功
- Job Feed 显示公开字段
- 未审核 Provider 不能 Bid
- 审核 Provider 可以 Bid
- Provider 看不到其他报价金额
- 顾客可以看到自己收到的 Bid
- 顾客只能接受一个 Bid
- 中标 Provider 才能看地址
- Job 可以开始和完成
- 双方可以评价
- 双方可以举报
- Admin 可以审核和封号
- RLS Test 通过
- 两台 Android 手机测试通过
- App 重启后状态正确
- 网络失败不会破坏数据
- 并发 Accept Bid 测试通过
- 敏感文件不公开

---

# 34. KPI

## 供给端

- Approved Providers
- Active Providers
- Providers by Category
- Providers by Area
- Provider 7-Day Retention
- Provider 30-Day Retention
- Average Bids per Provider
- Bid Acceptance Rate

## 需求端

- Jobs Posted
- Valid Job Rate
- Average Bids per Job
- Time to First Bid
- Job Conversion Rate
- Job Cancellation Rate
- Repeat Customer Rate

## 安全

- No-show Rate
- Complaint Rate
- Late Cancellation Rate
- Price Dispute Rate
- Suspended Accounts
- Average Resolution Time

## 商业化

后期追踪：

- Provider Paid Conversion
- Average Revenue per Job
- Membership Conversion
- Lead Fee Revenue
- CAC
- LTV

---

# 35. 后续版本

## Version 1.1

- Phone OTP
- 三语支持
- 完整 Push Notification
- Provider Portfolio
- No-show 标记
- Job 自动过期
- 更完整评价维度

## Version 1.2

- Google Maps 大概距离
- 服务半径
- 收藏 Provider
- 重复预约
- B2B Property Account
- Condo Management Account

## Version 2.0

- Payment
- Escrow
- Platform Fee
- Bid Credit
- Membership
- Warranty
- Insurance
- Customer Web Portal
- iOS 正式版
- 多城市

---

# 36. 每轮开发记录格式

每完成一个 Step，更新：

```text
Current Stable Version
Current Objective
Completed
Not Completed
Known Issues
Database Migration
Test Result
Build Result
Commit ID
Rollback Point
Next Step
```

建议 Commit：

```text
feat: establish Ofrivo mobile project structure
feat: add customer job creation flow
feat: add provider verification workflow
feat: add provider job feed
feat: add transactional bid acceptance
feat: add job completion and reviews
feat: add admin provider approval
```

每个 Step 独立 Commit。

不要一轮同时加入多个阶段功能。

---

# 37. Codex / Antigravity 总指令

```text
建立一个名为 Ofrivo 的本地服务 Job Bid 平台雏形。

品牌：
- App 名：Ofrivo
- 品牌含义：Offers for every job
- Slogan：Post a job. Compare offers. Get it done.

架构：
- Flutter Android App
- Dart
- Riverpod
- go_router
- Supabase Auth
- Supabase PostgreSQL
- Supabase Storage
- PostgreSQL RPC
- Supabase Edge Functions
- Firebase Cloud Messaging 后续接入
- Next.js + TypeScript Admin Web

账号模型：
- 所有注册用户默认可以发布 Job。
- 用户可以另外申请成为 Provider。
- Provider 必须 verification_status = approved 才能 Bid。
- 不要把用户锁死成 customer 或 provider 两个独立账号。
- Approved Provider 可以在 Customer Mode 和 Provider Mode 之间切换。
- Admin 不放在 Flutter App，使用独立 Next.js Admin Web。

第一版服务类别：
1. Plumbing / Toilet
2. Electrical / Lighting / Fan
3. Air Conditioning
4. Moving / Delivery
5. Cleaning
6. Handyman

核心流程：
1. 用户注册。
2. 顾客发布 Job。
3. Job Feed 只显示公开地区，不显示完整地址。
4. 审核通过的 Provider 可以查看相关 Job。
5. Provider 提交 Bid。
6. Provider 只能看到 Bid 数量，不能看到其他 Provider 的报价金额。
7. 顾客查看自己的 Job 收到的所有 Bid。
8. 顾客接受一个 Bid。
9. accept_bid 必须通过 PostgreSQL RPC 在单一事务内执行。
10. 其他 Bid 自动 rejected。
11. Job 改成 assigned。
12. 中标 Provider 才能读取完整地址和 WhatsApp。
13. Job 可以进入 in_progress 和 completed。
14. 完成后双方可以评价。
15. 双方可以举报，Admin 可以处理和暂停账号。

状态：
Provider Verification:
- not_applied
- pending
- approved
- rejected
- suspended

Job:
- draft
- open
- assigned
- in_progress
- completed
- cancelled
- expired

Bid:
- pending
- accepted
- rejected
- withdrawn
- expired

Report:
- open
- reviewing
- resolved
- dismissed

安全要求：
- 所有表启用 RLS。
- profiles.id 直接使用 auth.users.id。
- provider-verifications 和 report-evidence 使用 private storage bucket。
- App 不能包含 service_role key。
- full_address 只能由顾客本人、Admin 和中标 Provider 读取。
- Provider Verification 文件只能由本人和 Admin 读取。
- 重要状态变更不能由 Flutter 连续执行多个 update。
- accept_bid、start_job、complete_job、cancel_job 使用事务 RPC。
- 保存 job_events audit log。
- 上传图片时限制大小、类型和数量，并尽量移除 EXIF 和 GPS Metadata。
- 未审核 Provider 不能 Bid。
- Suspended User 不能发布 Job 或 Bid。
- 同一个 Provider 对同一个 Job 只能有一个有效 Bid。
- 每个用户对同一个 Job 只能评价对方一次。

数据库：
- profiles
- provider_profiles
- service_categories
- areas
- provider_categories
- provider_areas
- provider_verifications
- jobs
- job_photos
- bids
- reviews
- reports
- notifications
- device_tokens
- job_events

Storage：
- avatars
- job-photos
- provider-verifications
- report-evidence

UI 流程：

公共：
- Splash
- Onboarding
- Login
- Register
- Forgot Password
- Profile
- Notification Centre
- Account Suspended

顾客：
- Customer Home
- Post Job
- Post Job Preview
- My Jobs
- Job Detail
- Received Bids
- Provider Profile
- Accepted Job Detail
- Complete Job
- Review
- Report
- Cancel Job

Provider：
- Become Provider
- Provider Application
- Select Categories
- Select Areas
- Verification Upload
- Verification Status
- Provider Home / Job Feed
- Job Filters
- Job Detail
- Submit Bid
- Edit Bid
- My Bids
- Assigned Jobs
- Provider Profile
- Availability Settings
- Reviews

Admin Web：
- Dashboard
- Pending Providers
- Provider Detail
- Users
- Jobs
- Bids
- Reports
- Categories
- Areas
- Audit Log
- System Settings

UI 风格：
- Mobile-first
- Clean
- Reliable
- Professional
- Card-based
- Deep teal / dark blue-green primary
- Avoid excessive gradients
- Avoid game-like UI
- Avoid tiny dense text
- Include loading, empty, error, offline, rejected, suspended and expired states

执行顺序：
Step 0：先建立 docs、screen map、wireframe 和 fake-data UI，不接 Supabase。
Step 1：建立 Flutter、Next.js、Supabase Repository Structure。
Step 2：建立 SQL migrations、constraints、indexes、storage 和 RLS。
Step 3：完成 Auth 和 profiles。
Step 4：完成顾客发布 Job。
Step 5：完成 Provider Application。
Step 6：完成 Provider Job Feed 和 Bid。
Step 7：完成 transactional accept_bid。
Step 8：完成 Job Completion、Review 和 Report。
Step 9：完成 Admin Web。
Step 10：接入 FCM。
Step 11：完成 unit、widget、integration、RLS 和 concurrency tests。
Step 12：建立 Android closed beta。

第一版不要做：
- Payment
- Wallet
- Escrow
- In-app chat
- Live GPS
- Auto dispatch
- Google Maps route
- AI pricing
- Membership
- Bid credit
- Referral
- iOS production release
- Multi-city launch

每完成一个 Step：
- 更新 PROJECT_STATUS.md
- 更新 CHANGELOG.md
- 运行测试
- 运行 build
- 提交单独 Git commit
- 记录 commit ID
- 记录 rollback point
- 不要在同一个 Step 同时加入下一阶段功能
```

---

# 38. Codex 第一轮启动指令

> 这一段适合你新建项目文件夹后，第一次直接给 Codex。

```text
你现在要开始建立 Ofrivo 项目，但本轮只执行 Step 0 和 Step 1，不要连接真实 Supabase，不要开始数据库 Migration，不要提前做下一阶段业务功能。

项目目标：
Ofrivo 是一个本地服务 Job Bid 平台。顾客发布 Job，审核通过的 Provider 查看 Job Feed 并提交报价，顾客选择报价。

本轮任务：

1. 在当前目录建立 monorepo 结构：

ofrivo/
├── apps/
│   ├── mobile/
│   └── admin/
├── supabase/
│   ├── migrations/
│   ├── functions/
│   ├── seed.sql
│   └── config.toml
├── docs/
│   ├── PROJECT_STATUS.md
│   ├── PRODUCT_SCOPE.md
│   ├── UI_SPEC.md
│   ├── SCREEN_MAP.md
│   ├── DATA_MODEL.md
│   ├── SECURITY.md
│   ├── TEST_PLAN.md
│   ├── CHANGELOG.md
│   └── RELEASE_CHECKLIST.md
├── assets/
│   ├── branding/
│   ├── icons/
│   └── mockups/
└── README.md

2. 在 apps/mobile 建立 Flutter Android 项目：
- Dart
- Riverpod
- go_router
- Material 3
- Feature-based structure
- 暂时使用 fake data
- 不接 Supabase
- 不接 Firebase
- 不加入 service role key
- 不建立付款、地图、聊天、AI 功能

3. 在 apps/admin 建立 Next.js + TypeScript + Tailwind 项目：
- 只建立基础骨架
- 不接真实 Supabase
- 只做 Admin Layout 占位
- 不做真实审核逻辑

4. 建立统一 Design System：
- Primary：deep teal / dark blue-green
- Secondary：blue
- Background：light grey-white
- Surface：white
- Success：green
- Warning：orange
- Danger：red
- Material 3
- 卡片式
- 简洁、可靠、专业
- 不要大量渐变
- 不要游戏化
- 不要密集小字

5. Flutter Fake Data UI 必须先建立这些页面和导航：
公共：
- Splash
- Onboarding
- Login
- Register

顾客：
- Customer Home
- Post Job
- My Jobs
- Job Detail
- Received Bids
- Provider Profile

Provider：
- Become Provider
- Verification Status
- Provider Job Feed
- Job Filters
- Job Detail
- Submit Bid
- My Bids
- Assigned Jobs

6. 建立 reusable widgets：
- AppScaffold
- PrimaryButton
- SecondaryButton
- DangerButton
- JobCard
- BidCard
- ProviderCard
- StatusBadge
- VerifiedBadge
- CategoryChip
- AreaChip
- BudgetInput
- DateTimeSelector
- PhotoUploader placeholder
- EmptyState
- ErrorState
- LoadingSkeleton
- ConfirmationDialog
- FilterBottomSheet

7. 所有页面必须先处理：
- loading
- empty
- error
- offline placeholder
- verification pending
- verification rejected
- no bids
- expired job
- suspended account placeholder

8. docs 内容必须写清楚：
- PRODUCT_SCOPE.md：MVP 做什么、不做什么
- SCREEN_MAP.md：全部页面和跳转
- UI_SPEC.md：颜色、组件、间距、状态
- DATA_MODEL.md：数据库草案，但不执行 migration
- SECURITY.md：RLS、地址隐藏、Private Bucket、service role 禁止放 App
- TEST_PLAN.md：unit、widget、integration、RLS、concurrency
- PROJECT_STATUS.md：当前阶段、稳定状态、下一步
- CHANGELOG.md：记录本轮建立内容

9. 完成后执行：
- flutter analyze
- flutter test
- Android debug build
- npm lint
- npm build

10. 如果环境缺少工具或 Build 失败：
- 不要绕过错误
- 记录真实错误
- 不要宣称成功
- 把阻塞写进 PROJECT_STATUS.md

11. 最后提交一个 Git commit：
feat: establish Ofrivo project foundation and fake-data UI

12. 返回：
- 建立了哪些文件
- UI 页面清单
- 测试结果
- Build 结果
- 已知问题
- Commit ID
- Rollback point
- 下一步建议

本轮禁止：
- 连接 Supabase
- 写入真实 API Key
- 创建真实数据库
- 创建真实 Storage Bucket
- 接入 Firebase
- 开发付款
- 开发地图
- 开发聊天
- 开发 AI 报价
- 跳到 Step 2 或后续阶段
```

---

# 39. Codex 第二轮：Supabase 基础指令

> 第一轮 UI 骨架完成并通过测试后才使用。

```text
继续 Ofrivo 项目，本轮只执行 Step 2：Supabase Database Foundation。

开始前：
1. 阅读 README.md。
2. 阅读 docs/PROJECT_STATUS.md。
3. 阅读 docs/PRODUCT_SCOPE.md。
4. 阅读 docs/DATA_MODEL.md。
5. 阅读 docs/SECURITY.md。
6. 检查当前 Git 状态和最后 Commit。
7. 不修改已验收的 Fake Data UI，除非接入数据需要最小调整。

本轮目标：
建立 Supabase 本地 Migration、数据库约束、Indexes、Storage 配置草案、RLS 初版和 Seed Data。

建立表：
- profiles
- provider_profiles
- service_categories
- areas
- provider_categories
- provider_areas
- provider_verifications
- jobs
- job_photos
- bids
- reviews
- reports
- notifications
- device_tokens
- job_events

要求：
- profiles.id 直接 references auth.users(id)
- 使用 timestamptz
- 使用 foreign keys
- 使用 check constraints 或 enum-like constraints
- Budget 和 Bid amount 必须 > 0
- Rating 必须 1–5
- 同一 Provider 对同一 Job 只能有一个有效 Bid
- 每个用户对同一 Job 只能评价对方一次
- 建立必要 indexes
- 所有用户数据表启用 RLS
- provider-verifications 和 report-evidence 规划为 private bucket
- 不建立永久公开 verification URL
- full_address 不能直接暴露给 Job Feed
- 不在 Flutter App 放 service_role key

建立事务 RPC 草案：
- accept_bid
- start_job
- complete_job
- cancel_job

accept_bid 必须：
- 验证调用者是 Job owner
- lock Job row
- 检查 Job status=open
- 检查 Bid status=pending
- 接受目标 Bid
- 拒绝其他 Bid
- 更新 Job assigned
- 写 accepted_bid_id
- 写 job_events
- 保证单一事务

Seed Data：
- 6 个服务类别
- Johor Bahru 初始地区
- Fake Customer
- Approved Provider
- Pending Provider
- Open Jobs
- Pending Bids
- Assigned Job 示例

测试：
- Migration 可以从空数据库执行
- Seed 可以执行
- SQL lint/validation
- RLS 基础测试
- accept_bid 并发逻辑测试或 SQL 测试草案

完成后：
- 更新 DATA_MODEL.md
- 更新 SECURITY.md
- 更新 PROJECT_STATUS.md
- 更新 CHANGELOG.md
- 记录 Migration 文件
- 运行现有 Flutter 和 Admin 测试，确认没有破坏 UI
- 提交 Commit：
feat: add Ofrivo Supabase schema and security foundation

返回：
- Migration 文件
- Tables
- Constraints
- Indexes
- RLS Policies
- RPC
- Seed Data
- 测试结果
- Build 结果
- 已知问题
- Commit ID
- Rollback point
- 下一步

本轮不要：
- 接入真实 Supabase Cloud
- 写真实 Project URL
- 加 FCM
- 做付款
- 做聊天
- 做地图
- 开始 Provider Feed 实际 API 接入
```

---

# 40. Codex 第三轮：Auth 与 Profile 指令

```text
继续 Ofrivo 项目，本轮只执行 Step 3：Authentication and Profiles。

开始前阅读：
- README.md
- PROJECT_STATUS.md
- DATA_MODEL.md
- SECURITY.md
- TEST_PLAN.md

目标：
将 Flutter App 接入 ofrivo-dev Supabase，完成 Email + Password Auth 和 profiles。

要求：
- SUPABASE_URL 和 SUPABASE_ANON_KEY 通过开发环境配置读取
- 不把 service_role 放进 App
- Register
- Login
- Logout
- Forgot Password
- Session Restore
- Profile 自动建立
- Edit Profile
- Account Suspended State
- Auth Guard
- Provider Mode Guard 先保留
- 错误、Loading、Offline 状态完整
- 不做 Phone OTP
- 不做 Google Sign-In
- 不做 Apple Sign-In

安全：
- 用户只能修改自己的 profile
- 其他用户不能读取电话和 WhatsApp
- 使用公开 Profile View 或安全 query
- Suspended User 不能进入正常业务页面

测试：
- Auth Service Unit Test
- Login/Register Widget Test
- Session Restore Test
- RLS Profile Test
- Invalid Login
- Suspended Account
- Network Failure

完成：
- 更新 PROJECT_STATUS.md
- 更新 CHANGELOG.md
- 运行 flutter analyze
- 运行 flutter test
- Android debug build
- 提交：
feat: add Ofrivo authentication and user profiles

不要提前做：
- Post Job
- Provider Application
- FCM
- Payment
- Chat
- Maps
```

---

# 41. 最终确认

```text
品牌：Ofrivo
品牌含义：Offers for every job
Slogan：Post a job. Compare offers. Get it done.
App：Flutter，一个 App，顾客和技工模式
账号：所有人可发布 Job，审核后额外成为 Provider
状态管理：Riverpod
路由：go_router
Backend：独立 Supabase ofrivo-dev Project
Database：PostgreSQL
关键状态：PostgreSQL Transaction RPC
文件：Supabase Storage
敏感文件：Private Bucket
权限：RLS
通知：Firebase Cloud Messaging
Admin：Next.js Web
初期登录：Email + Password
初期地区：Johor Bahru
初期类别：6 类
开发方式：UI Fake Data 完成后再连接 Backend
初期系统费用：接近 RM0
```
