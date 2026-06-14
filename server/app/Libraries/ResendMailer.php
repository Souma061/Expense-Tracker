<?php

namespace App\Libraries;

/**
 * ResendMailer
 *
 * Thin wrapper around the Resend REST API for sending transactional emails.
 * Set RESEND_API_KEY and RESEND_FROM_EMAIL in your .env file.
 *
 * Usage:
 *   $mailer = new \App\Libraries\ResendMailer();
 *   $mailer->sendOtp('user@example.com', 'John', '123456');
 */
class ResendMailer
{
    private string $apiKey;
    private string $fromEmail;
    private string $fromName;

    public function __construct()
    {
        $this->apiKey    = env('RESEND_API_KEY', '');
        $this->fromEmail = env('RESEND_FROM_EMAIL', 'no-reply@yourdomain.com');
        $this->fromName  = env('RESEND_FROM_NAME', 'Expense Tracker');
    }

    /**
     * Send an OTP verification email.
     *
     * @throws \RuntimeException on HTTP or API errors
     */
    public function sendOtp(string $toEmail, string $firstName, string $code): bool
    {
        if (empty($this->apiKey)) {
            log_message('error', '[ResendMailer] RESEND_API_KEY is not set.');
            return false;
        }

        $subject = 'Your Expense Tracker verification code';
        $html    = $this->buildOtpHtml($firstName, $code);

        return $this->send($toEmail, $subject, $html);
    }

    // ── Private ───────────────────────────────────────────────────────────

    private function send(string $to, string $subject, string $html): bool
    {
        $payload = json_encode([
            'from'    => "{$this->fromName} <{$this->fromEmail}>",
            'to'      => [$to],
            'subject' => $subject,
            'html'    => $html,
        ]);

        $ch = curl_init('https://api.resend.com/emails');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $payload,
            CURLOPT_HTTPHEADER     => [
                'Content-Type: application/json',
                'Authorization: Bearer ' . $this->apiKey,
            ],
            CURLOPT_TIMEOUT        => 10,
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);

        if ($curlError) {
            log_message('error', "[ResendMailer] cURL error: {$curlError}");
            return false;
        }

        $body = json_decode($response, true);

        if ($httpCode < 200 || $httpCode >= 300) {
            $errMsg = $body['message'] ?? $body['name'] ?? 'Unknown error';
            log_message('error', "[ResendMailer] API error {$httpCode}: {$errMsg}");
            return false;
        }

        return true;
    }

    private function buildOtpHtml(string $firstName, string $code): string
    {
        $digits = implode('', array_map(
            fn($d) => "<span style=\"display:inline-block;width:44px;height:56px;line-height:56px;
                        text-align:center;font-size:28px;font-weight:800;border-radius:12px;
                        background:#f0f4ff;color:#4f46e5;margin:0 4px;\">{$d}</span>",
            str_split($code)
        ));

        return <<<HTML
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f6f7fb;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0">
    <tr><td align="center" style="padding:40px 16px;">
      <table width="100%" style="max-width:480px;background:#ffffff;border-radius:20px;
             box-shadow:0 4px 24px rgba(0,0,0,0.07);overflow:hidden;">

        <!-- Header -->
        <tr><td style="background:linear-gradient(135deg,#4f46e5,#7c3aed);padding:36px 32px;text-align:center;">
          <p style="margin:0;font-size:13px;color:rgba(255,255,255,0.8);letter-spacing:2px;text-transform:uppercase;">Expense Tracker</p>
          <h1 style="margin:8px 0 0;font-size:26px;color:#ffffff;font-weight:800;">Verify Your Email</h1>
        </td></tr>

        <!-- Body -->
        <tr><td style="padding:36px 32px;">
          <p style="margin:0 0 8px;font-size:16px;color:#1e1b4b;font-weight:600;">Hi {$firstName},</p>
          <p style="margin:0 0 28px;font-size:15px;color:#6b7280;line-height:1.6;">
            Use the code below to verify your email address. It expires in <strong>5 minutes</strong>.
          </p>

          <!-- OTP -->
          <div style="text-align:center;margin:0 0 28px;">{$digits}</div>

          <p style="margin:0 0 6px;font-size:13px;color:#9ca3af;text-align:center;">
            Never share this code with anyone.
          </p>
        </td></tr>

        <!-- Footer -->
        <tr><td style="padding:20px 32px;background:#f9fafb;border-top:1px solid #f0f0f0;text-align:center;">
          <p style="margin:0;font-size:12px;color:#9ca3af;">
            If you didn't create an account, you can safely ignore this email.
          </p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>
HTML;
    }
}
