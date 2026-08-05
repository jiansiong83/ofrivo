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
