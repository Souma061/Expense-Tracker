<?php

namespace App\Controllers\Api;

use App\Libraries\JwtHelper;
use App\Libraries\ResendMailer;
use App\Models\OtpModel;
use App\Models\UserModel;
use CodeIgniter\HTTP\ResponseInterface;

class AuthController extends BaseApiController
{
    // ── POST /api/v1/auth/register ────────────────────────────────────────
    // Creates user, sends OTP via Resend. Does NOT return a JWT yet — that
    // is issued only after the user verifies their email in /verify-otp.

    public function register()
    {
        $rules = [
            'email'      => 'required|valid_email',
            'password'   => 'required|min_length[8]',
            'first_name' => 'permit_empty|max_length[100]',
            'last_name'  => 'permit_empty|max_length[100]',
        ];

        if (! $this->validate($rules)) {
            return $this->error('Validation failed.', ResponseInterface::HTTP_UNPROCESSABLE_ENTITY, $this->validator->getErrors());
        }

        $email     = $this->request->getVar('email');
        $model     = new UserModel();

        // Check for duplicate email
        if ($model->findByEmail($email)) {
            return $this->error('Email already registered.', ResponseInterface::HTTP_CONFLICT);
        }

        $userId = $this->uuid();

        $model->insert([
            'id'            => $userId,
            'email'         => $email,
            'password_hash' => password_hash($this->request->getVar('password'), PASSWORD_BCRYPT),
            'first_name'    => $this->request->getVar('first_name'),
            'last_name'     => $this->request->getVar('last_name'),
        ]);

        // Create default account
        $accountModel = new \App\Models\AccountModel();
        $accountModel->insert([
            'id'       => $this->uuid(),
            'user_id'  => $userId,
            'name'     => 'Main Wallet',
            'type'     => 'cash',
            'balance'  => 0,
            'currency' => 'INR',
        ]);

        // Create default categories
        $categoryModel = new \App\Models\CategoryModel();
        $categoryModel->insertBatch([
            ['id' => $this->uuid(), 'user_id' => $userId, 'name' => 'Salary',    'type' => 'income',  'icon' => 'money',         'color' => '#00C48C'],
            ['id' => $this->uuid(), 'user_id' => $userId, 'name' => 'Groceries', 'type' => 'expense', 'icon' => 'shopping_cart', 'color' => '#FF644B'],
            ['id' => $this->uuid(), 'user_id' => $userId, 'name' => 'Utilities', 'type' => 'expense', 'icon' => 'bolt',          'color' => '#F4A261'],
        ]);

        // Generate & send OTP via Resend
        $otpModel  = new OtpModel();
        $code      = $otpModel->createOtp($email);
        $firstName = $this->request->getVar('first_name') ?: 'there';

        $mailer = new ResendMailer();
        $sent   = $mailer->sendOtp($email, $firstName, $code);

        if (! $sent) {
            log_message('warning', "[AuthController] OTP email failed for {$email}. Code: {$code}");
        }

        return $this->success(
            ['email' => $email],
            'Registration successful. Please verify your email.',
            ResponseInterface::HTTP_CREATED
        );
    }

    // ── POST /api/v1/auth/verify-otp ─────────────────────────────────────
    // Verifies the OTP for an email. On success, issues a JWT.

    public function verifyOtp()
    {
        $rules = [
            'email' => 'required|valid_email',
            'otp'   => 'required|exact_length[6]|is_natural',
        ];

        if (! $this->validate($rules)) {
            return $this->error('Validation failed.', ResponseInterface::HTTP_UNPROCESSABLE_ENTITY, $this->validator->getErrors());
        }

        $email = $this->request->getVar('email');
        $otp   = $this->request->getVar('otp');

        $otpModel = new OtpModel();
        if (! $otpModel->verifyOtp($email, $otp)) {
            return $this->error('Invalid or expired OTP.', ResponseInterface::HTTP_UNAUTHORIZED);
        }

        $userModel = new UserModel();
        $user      = $userModel->findByEmail($email);
        if (! $user) {
            return $this->error('User not found.', ResponseInterface::HTTP_NOT_FOUND);
        }

        $token = JwtHelper::encode(['sub' => $user['id']]);

        return $this->success(['token' => $token], 'Email verified successfully.');
    }

    // ── POST /api/v1/auth/resend-otp ─────────────────────────────────────
    // Invalidates existing OTPs and sends a fresh one.

    public function resendOtp()
    {
        $rules = ['email' => 'required|valid_email'];

        if (! $this->validate($rules)) {
            return $this->error('Validation failed.', ResponseInterface::HTTP_UNPROCESSABLE_ENTITY, $this->validator->getErrors());
        }

        $email = $this->request->getVar('email');

        $userModel = new UserModel();
        if (! $userModel->findByEmail($email)) {
            // Respond with success to prevent email enumeration
            return $this->success([], 'If that email is registered, a new code has been sent.');
        }

        $otpModel  = new OtpModel();
        $code      = $otpModel->createOtp($email);

        $user      = $userModel->findByEmail($email);
        $firstName = $user['first_name'] ?: 'there';

        $mailer = new ResendMailer();
        $mailer->sendOtp($email, $firstName, $code);

        return $this->success([], 'A new verification code has been sent.');
    }

    // ── POST /api/v1/auth/login ───────────────────────────────────────────

    public function login()
    {
        $rules = [
            'email'    => 'required|valid_email',
            'password' => 'required',
        ];

        if (! $this->validate($rules)) {
            return $this->error('Validation failed.', ResponseInterface::HTTP_UNPROCESSABLE_ENTITY, $this->validator->getErrors());
        }

        $throttler = \Config\Services::throttler();
        if ($throttler->check($this->request->getIPAddress(), 5, MINUTE) === false) {
            return $this->error('Too many login attempts. Please try again later.', ResponseInterface::HTTP_TOO_MANY_REQUESTS);
        }

        $model = new UserModel();
        $user  = $model->findByEmail($this->request->getVar('email'));
        if (! $user) {
            return $this->error('Invalid credentials.', ResponseInterface::HTTP_UNAUTHORIZED);
        }
        if (! password_verify($this->request->getVar('password'), $user['password_hash'])) {
            return $this->error('Invalid credentials.', ResponseInterface::HTTP_UNAUTHORIZED);
        }

        $token = JwtHelper::encode(['sub' => $user['id']]);

        return $this->success([
            'token' => $token,
            'user'  => [
                'id'         => $user['id'],
                'email'      => $user['email'],
                'first_name' => $user['first_name'],
                'last_name'  => $user['last_name'],
            ],
        ], 'Login successful.');
    }

    // ── GET /api/v1/auth/me ───────────────────────────────────────────────

    public function me()
    {
        $model = new UserModel();
        $user  = $model->find($this->userId());

        if (! $user) {
            return $this->error('User not found.', ResponseInterface::HTTP_NOT_FOUND);
        }

        unset($user['password_hash']);

        return $this->success($user);
    }
}
