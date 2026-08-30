<?php

namespace App\Http\Controllers\Admin;

use App\Domain\Audit\Auditor;
use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;
use Inertia\Response;

class AuthController extends Controller
{
    public function create(): Response
    {
        return Inertia::render('Admin/Auth/Login');
    }

    public function store(Request $request): RedirectResponse
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'remember' => ['sometimes', 'boolean'],
        ]);

        if (! Auth::attempt(['email' => $credentials['email'], 'password' => $credentials['password']], $request->boolean('remember'))) {
            Auditor::record('admin.login_failed', null, ['email' => $credentials['email']]);
            throw ValidationException::withMessages(['email' => 'These credentials do not match our records.']);
        }

        $request->session()->regenerate();
        $user = $request->user();

        if (! $user->isAdminOperator()) {
            Auth::logout();
            throw ValidationException::withMessages(['email' => 'This account cannot access the admin console.']);
        }

        if (in_array($user->status, ['banned', 'suspended', 'deactivated'], true)) {
            Auth::logout();
            throw ValidationException::withMessages(['email' => 'This account is not active.']);
        }

        Auditor::record('admin.login', $user, [], $user);

        return redirect()->intended('/admin');
    }

    public function twoFactor(): Response
    {
        return Inertia::render('Admin/Auth/TwoFactor');
    }

    public function destroy(Request $request): RedirectResponse
    {
        Auditor::record('admin.logout', $request->user(), [], $request->user());
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect('/admin/login');
    }
}
