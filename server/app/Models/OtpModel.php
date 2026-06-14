<?php

namespace App\Models;

use CodeIgniter\Model;

class OtpModel extends Model
{
    protected $table      = 'otp_codes';
    protected $primaryKey = 'id';
    protected $returnType = 'array';

    protected $allowedFields = [
        'email',
        'code',
        'expires_at',
        'used',
        'created_at',
    ];

    protected $useTimestamps = false; // managed manually

    // ── Helpers ───────────────────────────────────────────────────────────

    /**
     * Invalidate all existing (unused, unexpired) OTPs for a given email.
     */
    public function invalidateForEmail(string $email): void
    {
        $this->where('email', $email)->where('used', 0)->set(['used' => 1])->update();
    }

    /**
     * Create a new OTP for the given email (valid for $ttlMinutes minutes).
     * Returns the generated code.
     */
    public function createOtp(string $email, int $ttlMinutes = 5): string
    {
        $this->invalidateForEmail($email);

        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        $this->insert([
            'email'      => $email,
            'code'       => $code,
            'expires_at' => date('Y-m-d H:i:s', time() + ($ttlMinutes * 60)),
            'used'       => 0,
            'created_at' => date('Y-m-d H:i:s'),
        ]);

        return $code;
    }

    /**
     * Verify an OTP for the given email.
     * Returns true and marks the OTP as used on success, false otherwise.
     */
    public function verifyOtp(string $email, string $code): bool
    {
        $record = $this
            ->where('email', $email)
            ->where('code', $code)
            ->where('used', 0)
            ->where('expires_at >=', date('Y-m-d H:i:s'))
            ->first();

        if (! $record) {
            return false;
        }

        $this->update($record['id'], ['used' => 1]);
        return true;
    }
}
