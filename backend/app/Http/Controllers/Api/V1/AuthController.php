<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Audit\Auditor;
use App\Domain\Auth\TokenService;
use App\Http\Controllers\Controller;
use App\Models\OtpCode;
use App\Models\User;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Auth\Events\Verified;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password as PasswordRule;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function __construct(private readonly TokenService $tokens) {}

    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'display_name' => ['nullable', 'string', 'max:80'],
            'email' => ['required', 'email', 'max:190', 'unique:users,email'],
            'password' => ['required', 'confirmed', PasswordRule::min(8)],
            'city' => ['nullable', 'string', 'max:120'],
            'terms' => ['accepted'],
        ]);

        $user = User::query()->create([
            'name' => $data['name'],
            'display_name' => $data['display_name'] ?? $data['name'],
            'email' => $data['email'],
            'password' => $data['password'],
            'city' => $data['city'] ?? null,
            'status' => 'pending_verification',
            'verification_level' => 1,
            'locale' => $request->getPreferredLanguage(['en', 'sw']) ?: 'en',
        ]);
        $user->assignRole('user');
        $user->sendEmailVerificationNotification();

        Auditor::record('auth.register', $user, [], $user);

        return response()->json($this->tokens->issue($user, $request->input('device_name', 'mobile'), $request->ip(), $request->input('os')), 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['required', 'string', 'max:80'],
            'os' => ['nullable', 'string', 'max:40'],
        ]);

        $user = User::query()->where('email', $data['email'])->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            Auditor::record('auth.login_failed', $user, ['email' => $data['email']]);
            throw ValidationException::withMessages(['email' => __('auth.failed')]);
        }

        if (in_array($user->status, ['banned', 'deactivated'], true)) {
            throw ValidationException::withMessages(['email' => 'This account is not allowed to sign in.']);
        }

        Auditor::record('auth.login', $user, ['device' => $data['device_name']], $user);

        return response()->json($this->tokens->issue($user, $data['device_name'], $request->ip(), $data['os'] ?? null));
    }

    public function refresh(Request $request): JsonResponse
    {
        $data = $request->validate([
            'refresh_token' => ['required', 'string'],
        ]);

        $issued = $this->tokens->rotate($data['refresh_token']);
        if (! $issued) {
            return response()->json(['message' => 'Invalid refresh token.'], 401);
        }

        return response()->json($issued);
    }

    public function logout(Request $request): JsonResponse
    {
        $this->tokens->revokeCurrent($request->user());
        Auditor::record('auth.logout', $request->user(), [], $request->user());

        return response()->json(['message' => 'Logged out.']);
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $request->validate(['email' => ['required', 'email']]);
        Password::sendResetLink($request->only('email'));

        return response()->json(['message' => 'If that email exists, a reset link was sent.']);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $request->validate([
            'email' => ['required', 'email'],
            'token' => ['required', 'string'],
            'password' => ['required', 'confirmed', PasswordRule::min(8)],
        ]);

        $status = Password::reset($request->only('email', 'password', 'password_confirmation', 'token'), function (User $user, string $password) {
            $user->forceFill(['password' => $password, 'remember_token' => Str::random(60)])->save();
            $this->tokens->revokeAll($user);
            event(new PasswordReset($user));
        });

        if ($status !== Password::PASSWORD_RESET) {
            throw ValidationException::withMessages(['email' => __($status)]);
        }

        return response()->json(['message' => 'Password reset.']);
    }

    public function verifyEmail(Request $request): JsonResponse
    {
        $data = $request->validate([
            'id' => ['required', 'integer'],
            'hash' => ['required', 'string'],
        ]);

        $user = User::query()->findOrFail($data['id']);
        if (! hash_equals(sha1($user->email), $data['hash'])) {
            return response()->json(['message' => 'Invalid verification hash.'], 403);
        }

        if (! $user->hasVerifiedEmail()) {
            $user->markEmailAsVerified();
            $user->forceFill([
                'status' => $user->status === 'pending_verification' ? 'active' : $user->status,
                'verification_level' => max($user->verification_level, 2),
            ])->save();
            event(new Verified($user));
        }

        return response()->json(['message' => 'Email verified.', 'user' => $user->fresh()->toPrivateDto()]);
    }

    public function sendPhoneOtp(Request $request): JsonResponse
    {
        $data = $request->validate(['phone' => ['required', 'string', 'max:32']]);
        $code = (string) random_int(100000, 999999);

        OtpCode::query()->create([
            'channel' => 'phone',
            'destination' => $data['phone'],
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addMinutes(10),
        ]);

        Log::info("Reunite OTP for {$data['phone']}: {$code}");

        return response()->json(['message' => 'OTP sent. In local environments the code is written to the log.']);
    }

    public function confirmPhoneOtp(Request $request): JsonResponse
    {
        $data = $request->validate([
            'phone' => ['required', 'string'],
            'code' => ['required', 'string'],
        ]);

        $otp = OtpCode::query()
            ->where('channel', 'phone')
            ->where('destination', $data['phone'])
            ->whereNull('consumed_at')
            ->latest()
            ->first();

        if (! $otp || ! $otp->isValid() || ! Hash::check($data['code'], $otp->code_hash)) {
            if ($otp) {
                $otp->increment('attempts');
            }

            throw ValidationException::withMessages(['code' => 'Invalid or expired code.']);
        }

        $otp->update(['consumed_at' => now()]);

        $user = $request->user() ?: User::query()->where('phone', $data['phone'])->first();
        if ($user) {
            $user->forceFill([
                'phone' => $data['phone'],
                'phone_verified_at' => now(),
                'verification_level' => max($user->verification_level, 3),
                'status' => $user->status === 'pending_verification' ? 'active' : $user->status,
            ])->save();
        }

        return response()->json(['message' => 'Phone verified.', 'user' => $user?->fresh()?->toPrivateDto()]);
    }
}
