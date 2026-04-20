import axios from "axios";

const BREVO_EMAIL_URL = "https://api.brevo.com/v3/smtp/email";

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

export async function sendOtpEmail(to: string, otp: string, name: string): Promise<void> {
  const apiKey = process.env.BREVO_API_KEY;
  if (!apiKey) {
    throw new Error("BREVO_API_KEY belum dikonfigurasi.");
  }

  const senderEmail = process.env.BREVO_SENDER_EMAIL || "noreply@nexpos.app";
  const senderName = process.env.BREVO_SENDER_NAME || "NexPos Admin";
  const safeName = escapeHtml(name || "Admin");
  const safeOtp = escapeHtml(otp);

  const body = {
    sender: { email: senderEmail, name: senderName },
    to: [{ email: to, name }],
    subject: "Kode OTP Reset Password NexPos",
    htmlContent: `
      <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;padding:32px;border:1px solid #e0e0e0;border-radius:12px">
        <h2 style="color:#1565C0;margin-bottom:8px">NexPos Admin</h2>
        <p style="color:#555;margin-bottom:24px">Halo <strong>${safeName}</strong>,</p>
        <p style="color:#333">Anda meminta reset password untuk akun NexPos Anda. Gunakan kode OTP berikut:</p>
        <div style="background:#E3F2FD;border-radius:8px;padding:20px;text-align:center;margin:24px 0">
          <span style="font-size:36px;font-weight:bold;letter-spacing:12px;color:#1565C0">${safeOtp}</span>
        </div>
        <p style="color:#555;font-size:14px">Kode ini berlaku selama <strong>10 menit</strong>. Jangan bagikan kode ini kepada siapapun.</p>
        <p style="color:#555;font-size:14px">Jika Anda tidak meminta reset password, abaikan email ini.</p>
        <hr style="border:none;border-top:1px solid #eee;margin:24px 0"/>
        <p style="color:#aaa;font-size:12px">NexPos &mdash; Manajemen Outlet Laundry Digital</p>
      </div>
    `,
  };

  const response = await axios.post(BREVO_EMAIL_URL, body, {
    headers: { "api-key": apiKey, "Content-Type": "application/json" },
    timeout: 15_000,
  });

  console.info("[Email] OTP terkirim via Brevo API:", { to, messageId: response.data?.messageId });
}
