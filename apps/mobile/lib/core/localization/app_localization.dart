import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english,
  malay,
  chinese;

  String get code => switch (this) {
        AppLanguage.english => 'en',
        AppLanguage.malay => 'ms',
        AppLanguage.chinese => 'zh',
      };

  String get label => switch (this) {
        AppLanguage.english => 'English',
        AppLanguage.malay => 'Bahasa Melayu',
        AppLanguage.chinese => '中文',
      };

  Locale get locale => Locale(code);

  static AppLanguage? fromCode(String? code) => switch (code) {
        'en' => AppLanguage.english,
        'ms' => AppLanguage.malay,
        'zh' => AppLanguage.chinese,
        _ => null,
      };
}

class AppLanguageController extends StateNotifier<AppLanguage> {
  AppLanguageController() : super(AppLanguage.english) {
    _restore();
  }

  static const _storageKey = 'ofrivo.language';

  Future<void> _restore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final restored = AppLanguage.fromCode(preferences.getString(_storageKey));
      if (mounted && restored != null) state = restored;
    } catch (_) {
      // Demo/test platforms may not provide a preferences plugin.
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageKey, language.code);
    } catch (_) {
      // The in-memory selection remains useful when persistence is unavailable.
    }
  }
}

final appLanguageProvider =
    StateNotifierProvider<AppLanguageController, AppLanguage>(
        (ref) => AppLanguageController());

class AppLocalizations {
  const AppLocalizations(this.language);

  final AppLanguage language;

  String text(String key) =>
      _translations[key]?[language] ??
      _translations[key]?[AppLanguage.english] ??
      key;

  static const Map<String, Map<AppLanguage, String>> _translations = {
    'language': {
      AppLanguage.english: 'Language',
      AppLanguage.malay: 'Bahasa',
      AppLanguage.chinese: '语言',
    },
    'tagline': {
      AppLanguage.english: 'Offers for every job',
      AppLanguage.malay: 'Tawaran untuk setiap kerja',
      AppLanguage.chinese: '每个任务都有报价',
    },
    'onboarding_title': {
      AppLanguage.english: 'Post a job.\nCompare offers.\nGet it done.',
      AppLanguage.malay: 'Siarkan kerja.\nBandingkan tawaran.\nSiapkan kerja.',
      AppLanguage.chinese: '发布任务。\n比较报价。\n完成工作。',
    },
    'onboarding_description': {
      AppLanguage.english:
          'A simple local marketplace for customers and trusted service providers.',
      AppLanguage.malay:
          'Pasaran tempatan ringkas untuk pelanggan dan penyedia perkhidmatan yang dipercayai.',
      AppLanguage.chinese: '为客户和可信赖服务商打造的本地服务市场。',
    },
    'login': {
      AppLanguage.english: 'Log in',
      AppLanguage.malay: 'Log masuk',
      AppLanguage.chinese: '登录',
    },
    'create_account': {
      AppLanguage.english: 'Create an account',
      AppLanguage.malay: 'Buat akaun',
      AppLanguage.chinese: '创建账户',
    },
    'explore_preview': {
      AppLanguage.english: 'Explore fake-data preview',
      AppLanguage.malay: 'Lihat pratonton data demo',
      AppLanguage.chinese: '浏览演示数据',
    },
    'welcome_back': {
      AppLanguage.english: 'Welcome back',
      AppLanguage.malay: 'Selamat kembali',
      AppLanguage.chinese: '欢迎回来',
    },
    'create_your_account': {
      AppLanguage.english: 'Create your account',
      AppLanguage.malay: 'Buat akaun anda',
      AppLanguage.chinese: '创建你的账户',
    },
    'new_to_ofrivo': {
      AppLanguage.english: 'New to Ofrivo?',
      AppLanguage.malay: 'Baharu di Ofrivo?',
      AppLanguage.chinese: '还不了解 Ofrivo？',
    },
    'already_have_account': {
      AppLanguage.english: 'Already have an account?',
      AppLanguage.malay: 'Sudah mempunyai akaun?',
      AppLanguage.chinese: '已经有账户？',
    },
    'email_address': {
      AppLanguage.english: 'Email address',
      AppLanguage.malay: 'Alamat e-mel',
      AppLanguage.chinese: '邮箱地址',
    },
    'password': {
      AppLanguage.english: 'Password',
      AppLanguage.malay: 'Kata laluan',
      AppLanguage.chinese: '密码',
    },
    'full_name': {
      AppLanguage.english: 'Full name',
      AppLanguage.malay: 'Nama penuh',
      AppLanguage.chinese: '姓名',
    },
    'register': {
      AppLanguage.english: 'Register',
      AppLanguage.malay: 'Daftar',
      AppLanguage.chinese: '注册',
    },
    'forgot_password': {
      AppLanguage.english: 'Forgot password?',
      AppLanguage.malay: 'Lupa kata laluan?',
      AppLanguage.chinese: '忘记密码？',
    },
    'use_phone_otp': {
      AppLanguage.english: 'Use phone OTP instead',
      AppLanguage.malay: 'Guna OTP telefon',
      AppLanguage.chinese: '改用手机验证码',
    },
    'demo_mode_hint': {
      AppLanguage.english:
          'No Supabase keys? This build uses local demo mode and does not contact a backend.',
      AppLanguage.malay:
          'Tiada kunci Supabase? Binaan ini menggunakan mod demo tempatan tanpa backend.',
      AppLanguage.chinese: '没有 Supabase 密钥？此版本使用本地演示模式，不连接后端。',
    },
    'phone_sign_in': {
      AppLanguage.english: 'Phone sign in',
      AppLanguage.malay: 'Log masuk telefon',
      AppLanguage.chinese: '手机登录',
    },
    'phone_otp_description': {
      AppLanguage.english:
          'Use your phone number to receive a one-time verification code.',
      AppLanguage.malay:
          'Gunakan nombor telefon anda untuk menerima kod pengesahan sekali guna.',
      AppLanguage.chinese: '使用手机号码接收一次性验证码。',
    },
    'phone_number': {
      AppLanguage.english: 'Phone number',
      AppLanguage.malay: 'Nombor telefon',
      AppLanguage.chinese: '手机号码',
    },
    'verification_code': {
      AppLanguage.english: 'Verification code',
      AppLanguage.malay: 'Kod pengesahan',
      AppLanguage.chinese: '验证码',
    },
    'send_code': {
      AppLanguage.english: 'Send code',
      AppLanguage.malay: 'Hantar kod',
      AppLanguage.chinese: '发送验证码',
    },
    'verify_code': {
      AppLanguage.english: 'Verify code',
      AppLanguage.malay: 'Sahkan kod',
      AppLanguage.chinese: '验证验证码',
    },
    'change_phone': {
      AppLanguage.english: 'Change phone number',
      AppLanguage.malay: 'Tukar nombor telefon',
      AppLanguage.chinese: '更换手机号码',
    },
    'prefer_email': {
      AppLanguage.english: 'Prefer email?',
      AppLanguage.malay: 'Lebih suka e-mel?',
      AppLanguage.chinese: '想使用邮箱？',
    },
    'demo_otp': {
      AppLanguage.english: 'Demo mode code: 123456',
      AppLanguage.malay: 'Kod mod demo: 123456',
      AppLanguage.chinese: '演示模式验证码：123456',
    },
    'supabase_code_expiry': {
      AppLanguage.english:
          'The code expires according to your Supabase Auth settings.',
      AppLanguage.malay:
          'Kod tamat tempoh mengikut tetapan Supabase Auth anda.',
      AppLanguage.chinese: '验证码有效期由 Supabase Auth 设置决定。',
    },
    'reset_password': {
      AppLanguage.english: 'Reset password',
      AppLanguage.malay: 'Tetapkan semula kata laluan',
      AppLanguage.chinese: '重置密码',
    },
    'reset_password_description': {
      AppLanguage.english:
          'Enter your email and we will send reset instructions.',
      AppLanguage.malay:
          'Masukkan e-mel anda dan kami akan menghantar arahan tetapan semula.',
      AppLanguage.chinese: '输入邮箱，我们会发送重置说明。',
    },
    'send_instructions': {
      AppLanguage.english: 'Send instructions',
      AppLanguage.malay: 'Hantar arahan',
      AppLanguage.chinese: '发送说明',
    },
    'please_wait': {
      AppLanguage.english: 'Please wait…',
      AppLanguage.malay: 'Sila tunggu…',
      AppLanguage.chinese: '请稍候……',
    },
    'provider_mode': {
      AppLanguage.english: 'Provider mode',
      AppLanguage.malay: 'Mod penyedia',
      AppLanguage.chinese: '服务商模式',
    },
    'notifications': {
      AppLanguage.english: 'Notifications',
      AppLanguage.malay: 'Pemberitahuan',
      AppLanguage.chinese: '通知',
    },
    'switch_mode': {
      AppLanguage.english: 'Switch mode',
      AppLanguage.malay: 'Tukar mod',
      AppLanguage.chinese: '切换模式',
    },
    'switch_to_provider': {
      AppLanguage.english: 'Switch to Provider Mode',
      AppLanguage.malay: 'Tukar ke Mod Penyedia',
      AppLanguage.chinese: '切换到服务商模式',
    },
    'switch_to_customer': {
      AppLanguage.english: 'Switch to Customer Mode',
      AppLanguage.malay: 'Tukar ke Mod Pelanggan',
      AppLanguage.chinese: '切换到客户模式',
    },
    'home': {
      AppLanguage.english: 'Home',
      AppLanguage.malay: 'Laman utama',
      AppLanguage.chinese: '首页',
    },
    'post_job': {
      AppLanguage.english: 'Post Job',
      AppLanguage.malay: 'Siarkan kerja',
      AppLanguage.chinese: '发布任务',
    },
    'my_jobs': {
      AppLanguage.english: 'My Jobs',
      AppLanguage.malay: 'Kerja saya',
      AppLanguage.chinese: '我的任务',
    },
    'profile': {
      AppLanguage.english: 'Profile',
      AppLanguage.malay: 'Profil',
      AppLanguage.chinese: '个人资料',
    },
    'job_feed': {
      AppLanguage.english: 'Job Feed',
      AppLanguage.malay: 'Senarai kerja',
      AppLanguage.chinese: '任务列表',
    },
    'my_bids': {
      AppLanguage.english: 'My Bids',
      AppLanguage.malay: 'Tawaran saya',
      AppLanguage.chinese: '我的报价',
    },
    'assigned': {
      AppLanguage.english: 'Assigned',
      AppLanguage.malay: 'Ditugaskan',
      AppLanguage.chinese: '已分配',
    },
  };
}

const businessTranslations = <String, Map<AppLanguage, String>>{
  'good_morning': {
    AppLanguage.english: 'Good morning, Alex',
    AppLanguage.malay: 'Selamat pagi, Alex',
    AppLanguage.chinese: '早安，Alex',
  },
  'customer_home_subtitle': {
    AppLanguage.english: 'What would you like to get done today?',
    AppLanguage.malay: 'Apa yang ingin anda siapkan hari ini?',
    AppLanguage.chinese: '今天想完成什么？',
  },
  'post_new_job': {
    AppLanguage.english: 'Post a new job',
    AppLanguage.malay: 'Siarkan kerja baharu',
    AppLanguage.chinese: '发布新工作',
  },
  'active_jobs': {
    AppLanguage.english: 'Your active jobs',
    AppLanguage.malay: 'Kerja aktif anda',
    AppLanguage.chinese: '你的进行中工作',
  },
  'no_jobs_yet': {
    AppLanguage.english: 'No jobs yet',
    AppLanguage.malay: 'Belum ada kerja',
    AppLanguage.chinese: '还没有工作',
  },
  'first_request': {
    AppLanguage.english: 'Post your first service request to get started.',
    AppLanguage.malay:
        'Siarkan permintaan perkhidmatan pertama anda untuk bermula.',
    AppLanguage.chinese: '发布第一份服务请求，开始使用。',
  },
  'privacy_provider': {
    AppLanguage.english:
        'Compare verified local providers and keep your address private until you choose.',
    AppLanguage.malay:
        'Bandingkan penyedia tempatan yang disahkan dan rahsiakan alamat sehingga anda memilih.',
    AppLanguage.chinese: '比较已验证的本地服务商，选定前保护地址隐私。',
  },
  'post_job_title': {
    AppLanguage.english: 'Post a job',
    AppLanguage.malay: 'Siarkan kerja',
    AppLanguage.chinese: '发布工作',
  },
  'post_job_hint': {
    AppLanguage.english: 'Give providers enough detail to send useful bids.',
    AppLanguage.malay:
        'Berikan perincian yang cukup supaya penyedia boleh menghantar tawaran yang berguna.',
    AppLanguage.chinese: '提供足够细节，让服务商提交有用的报价。',
  },
  'service_category': {
    AppLanguage.english: 'Service category',
    AppLanguage.malay: 'Kategori perkhidmatan',
    AppLanguage.chinese: '服务类别',
  },
  'job_title': {
    AppLanguage.english: 'Job title',
    AppLanguage.malay: 'Tajuk kerja',
    AppLanguage.chinese: '工作标题',
  },
  'job_description': {
    AppLanguage.english: 'Job description',
    AppLanguage.malay: 'Penerangan kerja',
    AppLanguage.chinese: '工作描述',
  },
  'full_address': {
    AppLanguage.english: 'Full address',
    AppLanguage.malay: 'Alamat penuh',
    AppLanguage.chinese: '完整地址',
  },
  'contact_phone': {
    AppLanguage.english: 'Contact phone',
    AppLanguage.malay: 'Telefon untuk dihubungi',
    AppLanguage.chinese: '联系电话',
  },
  'budget': {
    AppLanguage.english: 'Budget',
    AppLanguage.malay: 'Bajet',
    AppLanguage.chinese: '预算',
  },
  'budget_label': {
    AppLanguage.english: 'Budget',
    AppLanguage.malay: 'Bajet',
    AppLanguage.chinese: '预算',
  },
  'time_window': {
    AppLanguage.english: 'Preferred time window',
    AppLanguage.malay: 'Masa pilihan',
    AppLanguage.chinese: '首选时间段',
  },
  'mark_urgent': {
    AppLanguage.english: 'Mark as urgent',
    AppLanguage.malay: 'Tandakan sebagai segera',
    AppLanguage.chinese: '标记为紧急',
  },
  'photos': {
    AppLanguage.english: 'Photos',
    AppLanguage.malay: 'Foto',
    AppLanguage.chinese: '照片',
  },
  'choose_photos': {
    AppLanguage.english: 'Choose photos',
    AppLanguage.malay: 'Pilih foto',
    AppLanguage.chinese: '选择照片',
  },
  'change_photos': {
    AppLanguage.english: 'Change photos',
    AppLanguage.malay: 'Tukar foto',
    AppLanguage.chinese: '更换照片',
  },
  'save_draft': {
    AppLanguage.english: 'Save as draft',
    AppLanguage.malay: 'Simpan sebagai draf',
    AppLanguage.chinese: '保存为草稿',
  },
  'preview_job': {
    AppLanguage.english: 'Preview job',
    AppLanguage.malay: 'Pratonton kerja',
    AppLanguage.chinese: '预览工作',
  },
  'private_contact': {
    AppLanguage.english: 'Private contact details',
    AppLanguage.malay: 'Butiran hubungan peribadi',
    AppLanguage.chinese: '私密联系方式',
  },
  'review_before_share': {
    AppLanguage.english:
        'Review the details before you share this request with providers.',
    AppLanguage.malay:
        'Semak butiran sebelum berkongsi permintaan ini dengan penyedia.',
    AppLanguage.chinese: '在向服务商发布前，请先检查工作详情。',
  },
  'publish_job': {
    AppLanguage.english: 'Publish job',
    AppLanguage.malay: 'Terbitkan kerja',
    AppLanguage.chinese: '发布工作',
  },
  'keep_editing': {
    AppLanguage.english: 'Keep editing',
    AppLanguage.malay: 'Terus mengedit',
    AppLanguage.chinese: '继续编辑',
  },
  'my_jobs_title': {
    AppLanguage.english: 'My jobs',
    AppLanguage.malay: 'Kerja saya',
    AppLanguage.chinese: '我的工作',
  },
  'track_jobs': {
    AppLanguage.english: 'Track your requests from draft to completed.',
    AppLanguage.malay: 'Jejaki permintaan anda daripada draf hingga selesai.',
    AppLanguage.chinese: '跟踪请求，从草稿到完成。',
  },
  'job_not_found': {
    AppLanguage.english: 'Job not found',
    AppLanguage.malay: 'Kerja tidak ditemui',
    AppLanguage.chinese: '找不到工作',
  },
  'job_removed': {
    AppLanguage.english:
        'This job may have been removed or is no longer available.',
    AppLanguage.malay:
        'Kerja ini mungkin telah dibuang atau tidak lagi tersedia.',
    AppLanguage.chinese: '这项工作可能已被删除或不再可用。',
  },
  'service_address': {
    AppLanguage.english: 'Service address',
    AppLanguage.malay: 'Alamat perkhidmatan',
    AppLanguage.chinese: '服务地址',
  },
  'contact': {
    AppLanguage.english: 'Contact',
    AppLanguage.malay: 'Hubungan',
    AppLanguage.chinese: '联系方式',
  },
  'cancel_job': {
    AppLanguage.english: 'Cancel job',
    AppLanguage.malay: 'Batal kerja',
    AppLanguage.chinese: '取消工作',
  },
  'cancel_job_cannot': {
    AppLanguage.english: 'Job cannot be cancelled',
    AppLanguage.malay: 'Kerja tidak boleh dibatalkan',
    AppLanguage.chinese: '工作无法取消',
  },
  'cancel_job_title': {
    AppLanguage.english: 'Cancel this job?',
    AppLanguage.malay: 'Batalkan kerja ini?',
    AppLanguage.chinese: '要取消这项工作吗？',
  },
  'cancel_job_message': {
    AppLanguage.english: 'This will mark the request as cancelled.',
    AppLanguage.malay: 'Permintaan ini akan ditandakan sebagai dibatalkan.',
    AppLanguage.chinese: '这会将请求标记为已取消。',
  },
  'received_bids': {
    AppLanguage.english: 'Received bids',
    AppLanguage.malay: 'Tawaran diterima',
    AppLanguage.chinese: '收到的报价',
  },
  'no_bids': {
    AppLanguage.english: 'No bids yet',
    AppLanguage.malay: 'Belum ada tawaran',
    AppLanguage.chinese: '还没有报价',
  },
  'no_bids_message': {
    AppLanguage.english:
        'Approved providers will appear here when they respond.',
    AppLanguage.malay:
        'Penyedia yang diluluskan akan muncul di sini apabila mereka menjawab.',
    AppLanguage.chinese: '获批准的服务商回复后会显示在这里。',
  },
  'accept_offer': {
    AppLanguage.english: 'Accept this offer',
    AppLanguage.malay: 'Terima tawaran ini',
    AppLanguage.chinese: '接受此报价',
  },
  'accept_offer_title': {
    AppLanguage.english: 'Accept this offer?',
    AppLanguage.malay: 'Terima tawaran ini?',
    AppLanguage.chinese: '要接受此报价吗？',
  },
  'accept_offer_message': {
    AppLanguage.english:
        'This will assign the job and automatically reject the other pending offers.',
    AppLanguage.malay:
        'Ini akan menetapkan kerja dan menolak tawaran lain yang masih menunggu secara automatik.',
    AppLanguage.chinese: '接受后会分配工作，并自动拒绝其他待处理报价。',
  },
  'contact_revealed': {
    AppLanguage.english:
        'Address and contact details are now available to the selected provider.',
    AppLanguage.malay:
        'Alamat dan butiran hubungan kini tersedia kepada penyedia yang dipilih.',
    AppLanguage.chinese: '地址和联系方式现在已向选定的服务商开放。',
  },
  'your_profile': {
    AppLanguage.english: 'Your profile',
    AppLanguage.malay: 'Profil anda',
    AppLanguage.chinese: '你的个人资料',
  },
  'manage_profile': {
    AppLanguage.english: 'Manage your shared account details.',
    AppLanguage.malay: 'Urus butiran akaun yang dikongsi.',
    AppLanguage.chinese: '管理你的账户资料。',
  },
  'become_provider': {
    AppLanguage.english: 'Become a provider',
    AppLanguage.malay: 'Jadi penyedia',
    AppLanguage.chinese: '成为服务商',
  },
  'apply_receive_requests': {
    AppLanguage.english: 'Apply to receive local job requests',
    AppLanguage.malay: 'Mohon untuk menerima permintaan kerja tempatan',
    AppLanguage.chinese: '申请接收本地工作请求',
  },
  'notification_centre': {
    AppLanguage.english: 'Notification centre',
    AppLanguage.malay: 'Pusat pemberitahuan',
    AppLanguage.chinese: '通知中心',
  },
  'sign_out': {
    AppLanguage.english: 'Sign out',
    AppLanguage.malay: 'Log keluar',
    AppLanguage.chinese: '退出登录',
  },
  'provider_profile': {
    AppLanguage.english: 'Provider profile',
    AppLanguage.malay: 'Profil penyedia',
    AppLanguage.chinese: '服务商资料',
  },
  'available': {
    AppLanguage.english: 'Available',
    AppLanguage.malay: 'Tersedia',
    AppLanguage.chinese: '可接单',
  },
  'contact_after_accept': {
    AppLanguage.english:
        'Contact details are revealed only after a bid is accepted.',
    AppLanguage.malay:
        'Butiran hubungan hanya didedahkan selepas tawaran diterima.',
    AppLanguage.chinese: '报价获接受后才会显示联系方式。',
  },
  'review_customer': {
    AppLanguage.english: 'Review the customer',
    AppLanguage.malay: 'Nilai pelanggan',
    AppLanguage.chinese: '评价客户',
  },
  'review_provider': {
    AppLanguage.english: 'Review the provider',
    AppLanguage.malay: 'Nilai penyedia',
    AppLanguage.chinese: '评价服务商',
  },
  'review_intro': {
    AppLanguage.english:
        'Your review helps the Ofrivo community choose reliable people.',
    AppLanguage.malay:
        'Ulasan anda membantu komuniti Ofrivo memilih orang yang boleh dipercayai.',
    AppLanguage.chinese: '你的评价帮助 Ofrivo 社区选择可靠的人。',
  },
  'detailed_ratings': {
    AppLanguage.english: 'Detailed ratings',
    AppLanguage.malay: 'Penilaian terperinci',
    AppLanguage.chinese: '详细评分',
  },
  'punctuality': {
    AppLanguage.english: 'Punctuality',
    AppLanguage.malay: 'Ketepatan masa',
    AppLanguage.chinese: '准时性',
  },
  'quality': {
    AppLanguage.english: 'Quality',
    AppLanguage.malay: 'Kualiti',
    AppLanguage.chinese: '服务质量',
  },
  'communication': {
    AppLanguage.english: 'Communication',
    AppLanguage.malay: 'Komunikasi',
    AppLanguage.chinese: '沟通',
  },
  'comment_optional': {
    AppLanguage.english: 'Comment (optional)',
    AppLanguage.malay: 'Komen (pilihan)',
    AppLanguage.chinese: '评论（可选）',
  },
  'what_went_well': {
    AppLanguage.english: 'What went well?',
    AppLanguage.malay: 'Apa yang berjalan lancar?',
    AppLanguage.chinese: '哪些地方做得好？',
  },
  'submit_review': {
    AppLanguage.english: 'Submit review',
    AppLanguage.malay: 'Hantar ulasan',
    AppLanguage.chinese: '提交评价',
  },
  'report_issue': {
    AppLanguage.english: 'Report an issue',
    AppLanguage.malay: 'Laporkan isu',
    AppLanguage.chinese: '举报问题',
  },
  'report_intro': {
    AppLanguage.english:
        'Reports are private and reviewed by the Ofrivo safety team.',
    AppLanguage.malay:
        'Laporan adalah peribadi dan disemak oleh pasukan keselamatan Ofrivo.',
    AppLanguage.chinese: '报告是私密的，由 Ofrivo 安全团队审核。',
  },
  'reason': {
    AppLanguage.english: 'Reason',
    AppLanguage.malay: 'Sebab',
    AppLanguage.chinese: '原因',
  },
  'what_happened': {
    AppLanguage.english: 'What happened?',
    AppLanguage.malay: 'Apa yang berlaku?',
    AppLanguage.chinese: '发生了什么？',
  },
  'submit_report': {
    AppLanguage.english: 'Submit report',
    AppLanguage.malay: 'Hantar laporan',
    AppLanguage.chinese: '提交报告',
  },
  'job_history': {
    AppLanguage.english: 'Job history',
    AppLanguage.malay: 'Sejarah kerja',
    AppLanguage.chinese: '工作记录',
  },
  'no_activity': {
    AppLanguage.english: 'No activity recorded yet.',
    AppLanguage.malay: 'Belum ada aktiviti direkodkan.',
    AppLanguage.chinese: '还没有活动记录。',
  },
  'leave_review': {
    AppLanguage.english: 'Leave a review',
    AppLanguage.malay: 'Tulis ulasan',
    AppLanguage.chinese: '留下评价',
  },
  'report': {
    AppLanguage.english: 'Report',
    AppLanguage.malay: 'Lapor',
    AppLanguage.chinese: '举报',
  },
  'job_feed_title': {
    AppLanguage.english: 'Job feed',
    AppLanguage.malay: 'Senarai kerja',
    AppLanguage.chinese: '工作列表',
  },
  'job_feed_subtitle': {
    AppLanguage.english: 'Open requests near your selected service areas.',
    AppLanguage.malay:
        'Permintaan terbuka berhampiran kawasan perkhidmatan pilihan anda.',
    AppLanguage.chinese: '你选择的服务区域附近的公开请求。',
  },
  'filters': {
    AppLanguage.english: 'Filters',
    AppLanguage.malay: 'Penapis',
    AppLanguage.chinese: '筛选',
  },
  'urgent_only': {
    AppLanguage.english: 'Urgent only',
    AppLanguage.malay: 'Segera sahaja',
    AppLanguage.chinese: '仅紧急',
  },
  'no_bids_filter': {
    AppLanguage.english: 'No bids',
    AppLanguage.malay: 'Tiada tawaran',
    AppLanguage.chinese: '没有报价',
  },
  'clear': {
    AppLanguage.english: 'Clear',
    AppLanguage.malay: 'Kosongkan',
    AppLanguage.chinese: '清除',
  },
  'no_matching_jobs': {
    AppLanguage.english: 'No matching jobs',
    AppLanguage.malay: 'Tiada kerja sepadan',
    AppLanguage.chinese: '没有匹配的工作',
  },
  'filters_hint': {
    AppLanguage.english: 'Narrow the feed to jobs you can serve next.',
    AppLanguage.malay:
        'Tapis senarai kepada kerja yang boleh anda lakukan seterusnya.',
    AppLanguage.chinese: '筛选出你可以接下来的工作。',
  },
  'apply_filters': {
    AppLanguage.english: 'Apply filters',
    AppLanguage.malay: 'Guna penapis',
    AppLanguage.chinese: '应用筛选',
  },
  'reset_filters': {
    AppLanguage.english: 'Reset filters',
    AppLanguage.malay: 'Tetapkan semula penapis',
    AppLanguage.chinese: '重置筛选',
  },
  'my_bids_title': {
    AppLanguage.english: 'My bids',
    AppLanguage.malay: 'Tawaran saya',
    AppLanguage.chinese: '我的报价',
  },
  'my_bids_subtitle': {
    AppLanguage.english: 'Keep track of your pending and accepted offers.',
    AppLanguage.malay: 'Jejaki tawaran anda yang menunggu dan diterima.',
    AppLanguage.chinese: '跟踪待处理和已接受的报价。',
  },
  'assigned_jobs_title': {
    AppLanguage.english: 'Assigned jobs',
    AppLanguage.malay: 'Kerja ditugaskan',
    AppLanguage.chinese: '已分配工作',
  },
  'assigned_jobs_subtitle': {
    AppLanguage.english: 'Your accepted work and next actions.',
    AppLanguage.malay: 'Kerja yang diterima dan tindakan seterusnya.',
    AppLanguage.chinese: '你已接受的工作和下一步操作。',
  },
  'no_assigned_jobs': {
    AppLanguage.english: 'No assigned jobs',
    AppLanguage.malay: 'Tiada kerja ditugaskan',
    AppLanguage.chinese: '没有已分配工作',
  },
  'provider_profile_subtitle': {
    AppLanguage.english: 'Your public profile and availability.',
    AppLanguage.malay: 'Profil awam dan ketersediaan anda.',
    AppLanguage.chinese: '你的公开资料和接单状态。',
  },
  'available_new_jobs': {
    AppLanguage.english: 'Available for new jobs',
    AppLanguage.malay: 'Tersedia untuk kerja baharu',
    AppLanguage.chinese: '可接新工作',
  },
  'show_matching_requests': {
    AppLanguage.english: 'Show matching requests in your feed',
    AppLanguage.malay: 'Tunjukkan permintaan sepadan dalam senarai anda',
    AppLanguage.chinese: '在列表中显示匹配请求',
  },
  'verification_status_base': {
    AppLanguage.english: 'Verification status',
    AppLanguage.malay: 'Status pengesahan',
    AppLanguage.chinese: '认证状态',
  },
  'area': {
    AppLanguage.english: 'Area',
    AppLanguage.malay: 'Kawasan',
    AppLanguage.chinese: '区域',
  },
  'saving': {
    AppLanguage.english: 'Saving…',
    AppLanguage.malay: 'Menyimpan…',
    AppLanguage.chinese: '保存中…',
  },
  'draft_saved': {
    AppLanguage.english: 'Draft saved.',
    AppLanguage.malay: 'Draf disimpan.',
    AppLanguage.chinese: '草稿已保存。',
  },
  'job_published': {
    AppLanguage.english: 'Job published.',
    AppLanguage.malay: 'Kerja diterbitkan.',
    AppLanguage.chinese: '工作已发布。',
  },
  'job_cancelled': {
    AppLanguage.english: 'Job cancelled.',
    AppLanguage.malay: 'Kerja dibatalkan.',
    AppLanguage.chinese: '工作已取消。',
  },
  'post_request_here': {
    AppLanguage.english: 'Post a service request to see it here.',
    AppLanguage.malay:
        'Siarkan permintaan perkhidmatan untuk melihatnya di sini.',
    AppLanguage.chinese: '发布服务请求后会显示在这里。',
  },
  'offers_received_suffix': {
    AppLanguage.english: 'offers received',
    AppLanguage.malay: 'tawaran diterima',
    AppLanguage.chinese: '个报价',
  },
  'providers_responded_suffix': {
    AppLanguage.english: 'providers responded',
    AppLanguage.malay: 'penyedia menjawab',
    AppLanguage.chinese: '位服务商已回复',
  },
  'accepting': {
    AppLanguage.english: 'Accepting…',
    AppLanguage.malay: 'Menerima…',
    AppLanguage.chinese: '接受中…',
  },
  'starting': {
    AppLanguage.english: 'Starting…',
    AppLanguage.malay: 'Memulakan…',
    AppLanguage.chinese: '开始中…',
  },
  'mark_started': {
    AppLanguage.english: 'Mark as started',
    AppLanguage.malay: 'Tandakan dimulakan',
    AppLanguage.chinese: '标记为已开始',
  },
  'job_started': {
    AppLanguage.english: 'Job started.',
    AppLanguage.malay: 'Kerja dimulakan.',
    AppLanguage.chinese: '工作已开始。',
  },
  'completing': {
    AppLanguage.english: 'Completing…',
    AppLanguage.malay: 'Menyelesaikan…',
    AppLanguage.chinese: '完成中…',
  },
  'mark_completed': {
    AppLanguage.english: 'Mark as completed',
    AppLanguage.malay: 'Tandakan selesai',
    AppLanguage.chinese: '标记为已完成',
  },
  'job_completed': {
    AppLanguage.english: 'Job completed.',
    AppLanguage.malay: 'Kerja selesai.',
    AppLanguage.chinese: '工作已完成。',
  },
  'cancelling': {
    AppLanguage.english: 'Cancelling…',
    AppLanguage.malay: 'Membatalkan…',
    AppLanguage.chinese: '取消中…',
  },
  'cancel_assigned': {
    AppLanguage.english: 'Cancel assigned job',
    AppLanguage.malay: 'Batal kerja ditugaskan',
    AppLanguage.chinese: '取消已分配工作',
  },
  'cancel_assigned_title': {
    AppLanguage.english: 'Cancel this assigned job?',
    AppLanguage.malay: 'Batalkan kerja yang ditugaskan ini?',
    AppLanguage.chinese: '要取消这项已分配的工作吗？',
  },
  'cancel_assigned_message': {
    AppLanguage.english:
        'The customer will be notified and the job will stop here.',
    AppLanguage.malay:
        'Pelanggan akan dimaklumkan dan kerja akan dihentikan di sini.',
    AppLanguage.chinese: '客户会收到通知，工作将在这里停止。',
  },
  'mark_provider_no_show': {
    AppLanguage.english: 'Mark provider no-show',
    AppLanguage.malay: 'Tandakan penyedia tidak hadir',
    AppLanguage.chinese: '标记服务商未到场',
  },
  'mark_customer_no_show': {
    AppLanguage.english: 'Report customer no-show',
    AppLanguage.malay: 'Laporkan pelanggan tidak hadir',
    AppLanguage.chinese: '举报客户未到场',
  },
  'no_show_title': {
    AppLanguage.english: 'Mark a no-show?',
    AppLanguage.malay: 'Tandakan tidak hadir?',
    AppLanguage.chinese: '要标记未到场吗？',
  },
  'no_show_message': {
    AppLanguage.english:
        'This creates a private safety event for the job and notifies the other participant.',
    AppLanguage.malay:
        'Ini mencipta acara keselamatan peribadi dan memaklumkan peserta lain.',
    AppLanguage.chinese: '这会创建私密安全事件，并通知另一位参与者。',
  },
  'no_show_marked': {
    AppLanguage.english: 'No-show marked for safety review.',
    AppLanguage.malay: 'Ketidakhadiran ditandakan untuk semakan keselamatan.',
    AppLanguage.chinese: '未到场事件已标记，等待安全审核。',
  },
  'submitting': {
    AppLanguage.english: 'Submitting…',
    AppLanguage.malay: 'Menghantar…',
    AppLanguage.chinese: '提交中…',
  },
  'review_submitted': {
    AppLanguage.english: 'Review submitted.',
    AppLanguage.malay: 'Ulasan dihantar.',
    AppLanguage.chinese: '评价已提交。',
  },
  'report_details_hint': {
    AppLanguage.english: 'Include dates, messages, or other useful details.',
    AppLanguage.malay:
        'Sertakan tarikh, mesej, atau butiran berguna yang lain.',
    AppLanguage.chinese: '请提供日期、消息或其他有用细节。',
  },
  'report_submitted': {
    AppLanguage.english: 'Report submitted to the safety team.',
    AppLanguage.malay: 'Laporan dihantar kepada pasukan keselamatan.',
    AppLanguage.chinese: '报告已提交给安全团队。',
  },
  'view_verification_status': {
    AppLanguage.english: 'View verification status',
    AppLanguage.malay: 'Lihat status pengesahan',
    AppLanguage.chinese: '查看认证状态',
  },
  'update_provider_application': {
    AppLanguage.english: 'Update your provider application',
    AppLanguage.malay: 'Kemas kini permohonan penyedia anda',
    AppLanguage.chinese: '更新服务商申请',
  },
  'services': {
    AppLanguage.english: 'Services',
    AppLanguage.malay: 'Perkhidmatan',
    AppLanguage.chinese: '服务',
  },
  'service_areas': {
    AppLanguage.english: 'Service areas',
    AppLanguage.malay: 'Kawasan perkhidmatan',
    AppLanguage.chinese: '服务区域',
  },
  'verification_documents': {
    AppLanguage.english: 'Verification documents',
    AppLanguage.malay: 'Dokumen pengesahan',
    AppLanguage.chinese: '认证文件',
  },
  'id_front': {
    AppLanguage.english: 'ID front',
    AppLanguage.malay: 'Bahagian depan ID',
    AppLanguage.chinese: '身份证正面',
  },
  'id_back': {
    AppLanguage.english: 'ID back',
    AppLanguage.malay: 'Bahagian belakang ID',
    AppLanguage.chinese: '身份证背面',
  },
  'verification_selfie': {
    AppLanguage.english: 'Verification selfie',
    AppLanguage.malay: 'Swafoto pengesahan',
    AppLanguage.chinese: '认证自拍',
  },
  'business_document_optional': {
    AppLanguage.english: 'SSM / business document (optional)',
    AppLanguage.malay: 'SSM / dokumen perniagaan (pilihan)',
    AppLanguage.chinese: 'SSM／商业文件（可选）',
  },
  'work_photos': {
    AppLanguage.english: 'Work photos',
    AppLanguage.malay: 'Foto kerja',
    AppLanguage.chinese: '工作照片',
  },
  'submit_application': {
    AppLanguage.english: 'Submit application',
    AppLanguage.malay: 'Hantar permohonan',
    AppLanguage.chinese: '提交申请',
  },
  'verification_status': {
    AppLanguage.english: 'Verification status',
    AppLanguage.malay: 'Status pengesahan',
    AppLanguage.chinese: '认证状态',
  },
  'no_application': {
    AppLanguage.english: 'No application yet',
    AppLanguage.malay: 'Belum ada permohonan',
    AppLanguage.chinese: '还没有申请',
  },
  'complete_provider_apply': {
    AppLanguage.english:
        'Complete your provider information and verification documents to apply.',
    AppLanguage.malay:
        'Lengkapkan maklumat penyedia dan dokumen pengesahan untuk memohon.',
    AppLanguage.chinese: '完成服务商资料和认证文件后即可申请。',
  },
  'start_application': {
    AppLanguage.english: 'Start application',
    AppLanguage.malay: 'Mula permohonan',
    AppLanguage.chinese: '开始申请',
  },
  'approved': {
    AppLanguage.english: 'Approved',
    AppLanguage.malay: 'Diluluskan',
    AppLanguage.chinese: '已批准',
  },
  'changes_requested': {
    AppLanguage.english: 'Changes requested',
    AppLanguage.malay: 'Perubahan diperlukan',
    AppLanguage.chinese: '需要修改',
  },
  'provider_access_suspended': {
    AppLanguage.english: 'Provider access suspended',
    AppLanguage.malay: 'Akses penyedia digantung',
    AppLanguage.chinese: '服务商权限已暂停',
  },
  'pending_review': {
    AppLanguage.english: 'Pending review',
    AppLanguage.malay: 'Menunggu semakan',
    AppLanguage.chinese: '等待审核',
  },
  'provider_approved_message': {
    AppLanguage.english:
        'Your provider profile is approved. You can switch to Provider Mode.',
    AppLanguage.malay:
        'Profil penyedia anda diluluskan. Anda boleh beralih ke Mod Penyedia.',
    AppLanguage.chinese: '服务商资料已批准，你可以切换到服务商模式。',
  },
  'resubmit_admin_note': {
    AppLanguage.english:
        'Update the application using the admin note below and submit again.',
    AppLanguage.malay:
        'Kemas kini permohonan menggunakan nota admin di bawah dan hantar semula.',
    AppLanguage.chinese: '根据下方管理员备注修改申请并重新提交。',
  },
  'provider_suspended_message': {
    AppLanguage.english:
        'Provider features are temporarily unavailable. Contact support if you need help.',
    AppLanguage.malay:
        'Ciri penyedia tidak tersedia buat sementara. Hubungi sokongan jika perlu.',
    AppLanguage.chinese: '服务商功能暂时不可用。如需帮助，请联系客服。',
  },
  'documents_pending_message': {
    AppLanguage.english: 'Your documents are waiting for an admin review.',
    AppLanguage.malay: 'Dokumen anda sedang menunggu semakan admin.',
    AppLanguage.chinese: '你的文件正在等待管理员审核。',
  },
  'edit_resubmit': {
    AppLanguage.english: 'Edit and resubmit',
    AppLanguage.malay: 'Edit dan hantar semula',
    AppLanguage.chinese: '编辑并重新提交',
  },
  'open_provider_mode': {
    AppLanguage.english: 'Open Provider Mode',
    AppLanguage.malay: 'Buka Mod Penyedia',
    AppLanguage.chinese: '打开服务商模式',
  },
  'jobs_available_suffix': {
    AppLanguage.english: 'jobs available',
    AppLanguage.malay: 'kerja tersedia',
    AppLanguage.chinese: '个工作可接',
  },
  'try_another_filter': {
    AppLanguage.english: 'Try another category, area, budget, or sort option.',
    AppLanguage.malay: 'Cuba kategori, kawasan, bajet, atau susunan lain.',
    AppLanguage.chinese: '请尝试其他类别、区域、预算或排序。',
  },
  'job_filters': {
    AppLanguage.english: 'Job filters',
    AppLanguage.malay: 'Penapis kerja',
    AppLanguage.chinese: '工作筛选',
  },
  'category': {
    AppLanguage.english: 'Category',
    AppLanguage.malay: 'Kategori',
    AppLanguage.chinese: '类别',
  },
  'min_budget': {
    AppLanguage.english: 'Min budget',
    AppLanguage.malay: 'Bajet minimum',
    AppLanguage.chinese: '最低预算',
  },
  'max_budget': {
    AppLanguage.english: 'Max budget',
    AppLanguage.malay: 'Bajet maksimum',
    AppLanguage.chinese: '最高预算',
  },
  'service_date': {
    AppLanguage.english: 'Service date',
    AppLanguage.malay: 'Tarikh perkhidmatan',
    AppLanguage.chinese: '服务日期',
  },
  'urgent_jobs_only': {
    AppLanguage.english: 'Urgent jobs only',
    AppLanguage.malay: 'Kerja segera sahaja',
    AppLanguage.chinese: '仅紧急工作',
  },
  'urgent_jobs_hint': {
    AppLanguage.english: 'Prioritise requests that need a fast response.',
    AppLanguage.malay: 'Utamakan permintaan yang memerlukan respons pantas.',
    AppLanguage.chinese: '优先处理需要快速响应的请求。',
  },
  'first_offer_hint': {
    AppLanguage.english: 'Find jobs where you can be the first offer.',
    AppLanguage.malay:
        'Cari kerja yang membolehkan anda menjadi tawaran pertama.',
    AppLanguage.chinese: '寻找你可以提交第一份报价的工作。',
  },
  'sort_by': {
    AppLanguage.english: 'Sort by',
    AppLanguage.malay: 'Susun mengikut',
    AppLanguage.chinese: '排序方式',
  },
  'job_unavailable': {
    AppLanguage.english: 'Job unavailable',
    AppLanguage.malay: 'Kerja tidak tersedia',
    AppLanguage.chinese: '工作不可用',
  },
  'job_expired_removed': {
    AppLanguage.english: 'This request may have expired or been removed.',
    AppLanguage.malay:
        'Permintaan ini mungkin telah tamat tempoh atau dibuang.',
    AppLanguage.chinese: '此请求可能已过期或被删除。',
  },
  'urgent': {
    AppLanguage.english: 'Urgent',
    AppLanguage.malay: 'Segera',
    AppLanguage.chinese: '紧急',
  },
  'customer_budget': {
    AppLanguage.english: 'Customer budget',
    AppLanguage.malay: 'Bajet pelanggan',
    AppLanguage.chinese: '客户预算',
  },
  'address_protected': {
    AppLanguage.english: 'Address protected',
    AppLanguage.malay: 'Alamat dilindungi',
    AppLanguage.chinese: '地址已保护',
  },
  'address_protected_message': {
    AppLanguage.english:
        'Full address, phone, WhatsApp, and exact GPS stay hidden until a bid is accepted.',
    AppLanguage.malay:
        'Alamat penuh, telefon, WhatsApp dan GPS tepat disembunyikan sehingga tawaran diterima.',
    AppLanguage.chinese: '完整地址、电话、WhatsApp 和精确 GPS 会在报价获接受前保持隐藏。',
  },
  'submit_bid': {
    AppLanguage.english: 'Submit a bid',
    AppLanguage.malay: 'Hantar tawaran',
    AppLanguage.chinese: '提交报价',
  },
  'edit_bid': {
    AppLanguage.english: 'Edit your bid',
    AppLanguage.malay: 'Edit tawaran anda',
    AppLanguage.chinese: '编辑报价',
  },
  'view_accepted_bid': {
    AppLanguage.english: 'View your accepted bid',
    AppLanguage.malay: 'Lihat tawaran diterima anda',
    AppLanguage.chinese: '查看已接受的报价',
  },
  'bid_amount': {
    AppLanguage.english: 'Bid amount',
    AppLanguage.malay: 'Jumlah tawaran',
    AppLanguage.chinese: '报价金额',
  },
  'what_included': {
    AppLanguage.english: 'What is included?',
    AppLanguage.malay: 'Apa yang termasuk?',
    AppLanguage.chinese: '包含哪些内容？',
  },
  'what_excluded': {
    AppLanguage.english: 'What is excluded?',
    AppLanguage.malay: 'Apa yang tidak termasuk?',
    AppLanguage.chinese: '不包含哪些内容？',
  },
  'materials_note': {
    AppLanguage.english: 'Materials note',
    AppLanguage.malay: 'Nota bahan',
    AppLanguage.chinese: '材料说明',
  },
  'additional_note': {
    AppLanguage.english: 'Additional note',
    AppLanguage.malay: 'Nota tambahan',
    AppLanguage.chinese: '补充说明',
  },
  'send_bid': {
    AppLanguage.english: 'Send bid',
    AppLanguage.malay: 'Hantar tawaran',
    AppLanguage.chinese: '发送报价',
  },
  'save_changes': {
    AppLanguage.english: 'Save changes',
    AppLanguage.malay: 'Simpan perubahan',
    AppLanguage.chinese: '保存更改',
  },
  'working': {
    AppLanguage.english: 'Working…',
    AppLanguage.malay: 'Sedang diproses…',
    AppLanguage.chinese: '处理中…',
  },
  'withdraw_bid': {
    AppLanguage.english: 'Withdraw bid',
    AppLanguage.malay: 'Tarik balik tawaran',
    AppLanguage.chinese: '撤回报价',
  },
  'withdraw_bid_title': {
    AppLanguage.english: 'Withdraw bid?',
    AppLanguage.malay: 'Tarik balik tawaran?',
    AppLanguage.chinese: '要撤回报价吗？',
  },
  'withdraw_bid_message': {
    AppLanguage.english:
        'The customer will no longer count this offer as active.',
    AppLanguage.malay:
        'Pelanggan tidak lagi mengira tawaran ini sebagai aktif.',
    AppLanguage.chinese: '客户将不再把此报价视为有效。',
  },
  'bid_saved': {
    AppLanguage.english: 'Your bid was saved.',
    AppLanguage.malay: 'Tawaran anda telah disimpan.',
    AppLanguage.chinese: '你的报价已保存。',
  },
  'accepted_bid_locked': {
    AppLanguage.english:
        'Accepted bids cannot be edited. The customer has selected this offer.',
    AppLanguage.malay:
        'Tawaran yang diterima tidak boleh diedit. Pelanggan telah memilih tawaran ini.',
    AppLanguage.chinese: '已接受的报价无法编辑，客户已选择此报价。',
  },
  'my_bids_subtitle_base': {
    AppLanguage.english: 'Keep track of your pending and accepted offers.',
    AppLanguage.malay: 'Jejaki tawaran anda yang menunggu dan diterima.',
    AppLanguage.chinese: '跟踪待处理和已接受的报价。',
  },
  'first_bid_message': {
    AppLanguage.english: 'Open a job from the feed and send your first offer.',
    AppLanguage.malay:
        'Buka kerja daripada senarai dan hantar tawaran pertama anda.',
    AppLanguage.chinese: '从工作列表打开一项工作并提交第一份报价。',
  },
  'accepted_jobs_message': {
    AppLanguage.english:
        'Accepted offers will appear here after a customer selects you.',
    AppLanguage.malay:
        'Tawaran diterima akan muncul di sini selepas pelanggan memilih anda.',
    AppLanguage.chinese: '客户选择你后，已接受的报价会显示在这里。',
  },
  'assigned_job_not_found': {
    AppLanguage.english: 'Assigned job not found',
    AppLanguage.malay: 'Kerja ditugaskan tidak ditemui',
    AppLanguage.chinese: '找不到已分配工作',
  },
  'accepted_provider_only': {
    AppLanguage.english:
        'Only the accepted provider can reveal this job address.',
    AppLanguage.malay:
        'Hanya penyedia yang diterima boleh melihat alamat kerja ini.',
    AppLanguage.chinese: '只有已接受的服务商可以查看工作地址。',
  },
  'private_service_details': {
    AppLanguage.english: 'Private service details',
    AppLanguage.malay: 'Butiran perkhidmatan peribadi',
    AppLanguage.chinese: '私密服务详情',
  },
  'address_not_provided': {
    AppLanguage.english: 'Address not provided.',
    AppLanguage.malay: 'Alamat tidak diberikan.',
    AppLanguage.chinese: '未提供地址。',
  },
};

extension BusinessLocalizations on AppLocalizations {
  String business(String key) =>
      businessTranslations[key]?[language] ?? text(key);
}

class LanguagePicker extends ConsumerWidget {
  const LanguagePicker({super.key, this.showLabel = false});

  final bool showLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);
    final strings = AppLocalizations(language);
    return PopupMenuButton<AppLanguage>(
      tooltip: strings.text('language'),
      icon: showLabel ? null : const Icon(Icons.language_outlined),
      child: showLabel
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language_outlined),
                  const SizedBox(width: 8),
                  Text(language.label),
                ],
              ),
            )
          : null,
      onSelected: (value) =>
          ref.read(appLanguageProvider.notifier).setLanguage(value),
      itemBuilder: (context) => [
        for (final option in AppLanguage.values)
          PopupMenuItem<AppLanguage>(
            value: option,
            child: Row(
              children: [
                SizedBox(width: 28, child: Text(option.code.toUpperCase())),
                Expanded(child: Text(option.label)),
                if (option == language) const Icon(Icons.check, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}
