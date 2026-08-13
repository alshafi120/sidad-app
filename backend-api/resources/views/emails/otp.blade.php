<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: 'Segoe UI', Tahoma, sans-serif; background: #f4f5f9; margin: 0; padding: 40px 0; direction: rtl; }
        .container { max-width: 420px; margin: 0 auto; background: #fff; border-radius: 16px; padding: 40px 32px; box-shadow: 0 4px 24px rgba(0,0,0,0.06); }
        .logo { text-align: center; margin-bottom: 24px; }
        .logo-box { display: inline-block; width: 56px; height: 56px; background: linear-gradient(135deg, #532CD8, #6C4CF1); border-radius: 16px; line-height: 56px; color: #fff; font-size: 24px; }
        h1 { text-align: center; color: #191C1F; font-size: 22px; margin: 0 0 8px; }
        .subtitle { text-align: center; color: #484555; font-size: 14px; margin: 0 0 32px; }
        .otp-box { text-align: center; background: #F2F3F7; border-radius: 16px; padding: 24px; margin: 0 0 24px; }
        .otp-code { font-size: 36px; font-weight: 800; letter-spacing: 12px; color: #532CD8; font-family: monospace; }
        .note { text-align: center; color: #797587; font-size: 13px; margin-bottom: 0; }
        .footer { text-align: center; margin-top: 32px; color: #797587; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo"><div class="logo-box">💳</div></div>
        <h1>رمز التحقق</h1>
        <p class="subtitle">مرحباً {{ $userName }}، استخدم الرمز التالي لتفعيل حسابك</p>
        <div class="otp-box">
            <div class="otp-code">{{ $code }}</div>
        </div>
        <p class="note">الرمز صالح لمدة ١٠ دقائق فقط. لا تشاركه مع أحد.</p>
        <div class="footer">سداد — منصة إدارة المديونيات</div>
    </div>
</body>
</html>
