<?php

use App\Http\Controllers\Admin\AuthController as AdminAuthController;
use App\Http\Controllers\Admin\ClaimAdminController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\NetworkAdminController;
use App\Http\Controllers\Admin\OperationsAdminController;
use App\Http\Controllers\Admin\PeopleAdminController;
use App\Http\Controllers\Admin\ReportAdminController;
use App\Http\Controllers\Admin\SystemAdminController;
use App\Http\Controllers\AgentDeployController;
use App\Http\Controllers\MediaController;
use App\Http\Controllers\PublicWebController;
use Illuminate\Support\Facades\Route;

Route::get('/', [PublicWebController::class, 'home']);
Route::get('/search', [PublicWebController::class, 'search']);
Route::get('/items/{report}', [PublicWebController::class, 'teaser']);
Route::get('/p/{slug}', [PublicWebController::class, 'cms']);
Route::get('/media/{media}', [MediaController::class, 'show'])->name('media.show')->middleware('signed');

// Autonomous Agent Deploy System
Route::get('/deploy', [AgentDeployController::class, 'webConsole'])->name('deploy.console');
Route::post('/deploy/agent', [AgentDeployController::class, 'deploy'])->name('deploy.agent');

Route::prefix('admin')->group(function () {
    Route::middleware('guest')->group(function () {
        Route::get('login', [AdminAuthController::class, 'create'])->name('admin.login');
        Route::post('login', [AdminAuthController::class, 'store'])->middleware('throttle:login');
    });

    Route::get('2fa', [AdminAuthController::class, 'twoFactor'])->name('admin.2fa');

    Route::middleware(['auth', 'admin'])->group(function () {
        Route::post('logout', [AdminAuthController::class, 'destroy'])->name('admin.logout');
        Route::get('/', DashboardController::class)->name('admin.dashboard');

        Route::get('review', [ReportAdminController::class, 'review']);
        Route::get('reports/lost', [ReportAdminController::class, 'lost']);
        Route::get('reports/found', [ReportAdminController::class, 'found']);
        Route::get('reports/{report}', [ReportAdminController::class, 'show']);
        Route::post('reports/{report}/decide', [ReportAdminController::class, 'decide']);

        Route::get('matches', [OperationsAdminController::class, 'matches']);
        Route::post('matches/{match}', [OperationsAdminController::class, 'updateMatch']);
        Route::get('claims', [ClaimAdminController::class, 'index']);
        Route::get('claims/{claim}', [ClaimAdminController::class, 'show']);
        Route::post('claims/{claim}/decide', [ClaimAdminController::class, 'decide']);
        Route::get('handovers', [OperationsAdminController::class, 'handovers']);
        Route::get('flags', [OperationsAdminController::class, 'flags']);
        Route::post('flags/{flag}', [OperationsAdminController::class, 'updateFlag']);
        Route::get('disputes', [OperationsAdminController::class, 'disputes']);
        Route::get('disputes/{dispute}', [OperationsAdminController::class, 'showDispute']);
        Route::post('disputes/{dispute}', [OperationsAdminController::class, 'resolveDispute']);
        Route::get('chats', [OperationsAdminController::class, 'chats']);
        Route::get('chats/{conversation}', [OperationsAdminController::class, 'showChat']);

        Route::get('users', [PeopleAdminController::class, 'users']);
        Route::get('users/{user}', [PeopleAdminController::class, 'showUser']);
        Route::post('users/{user}', [PeopleAdminController::class, 'updateUser']);
        Route::get('roles', [PeopleAdminController::class, 'roles']);
        Route::post('roles/{role}', [PeopleAdminController::class, 'updateRole']);
        Route::get('staff/invite', [PeopleAdminController::class, 'inviteForm']);
        Route::post('staff/invite', [PeopleAdminController::class, 'invite']);
        Route::get('account', [PeopleAdminController::class, 'account']);
        Route::post('account', [PeopleAdminController::class, 'updateAccount']);

        Route::get('hubs', [NetworkAdminController::class, 'hubs']);
        Route::get('hubs/create', [NetworkAdminController::class, 'createHub']);
        Route::post('hubs', [NetworkAdminController::class, 'storeHub']);
        Route::get('hubs/{hub}', [NetworkAdminController::class, 'showHub']);
        Route::get('hubs/{hub}/edit', [NetworkAdminController::class, 'editHub']);
        Route::post('hubs/{hub}', [NetworkAdminController::class, 'updateHub']);
        Route::post('hubs/{hub}/storage', [NetworkAdminController::class, 'storeStorage']);
        Route::get('categories', [NetworkAdminController::class, 'categories']);
        Route::post('categories', [NetworkAdminController::class, 'storeCategory']);
        Route::post('categories/{category}', [NetworkAdminController::class, 'updateCategory']);
        Route::post('categories/{category}/attributes', [NetworkAdminController::class, 'storeAttribute']);

        Route::get('notifications/compose', [SystemAdminController::class, 'composer']);
        Route::post('notifications/compose', [SystemAdminController::class, 'compose']);
        Route::get('notifications/logs', [SystemAdminController::class, 'deliveryLogs']);
        Route::get('cms', [SystemAdminController::class, 'cms']);
        Route::post('cms', [SystemAdminController::class, 'storeCms']);
        Route::post('cms/{page}', [SystemAdminController::class, 'updateCms']);
        Route::get('analytics', [SystemAdminController::class, 'analytics']);
        Route::get('exports', [SystemAdminController::class, 'exports']);
        Route::get('exports/reports.csv', [SystemAdminController::class, 'downloadExport']);
        Route::get('audit', [SystemAdminController::class, 'audit']);
        Route::get('settings', [SystemAdminController::class, 'settings']);
        Route::post('settings', [SystemAdminController::class, 'updateSettings']);
        Route::get('feature-flags', [SystemAdminController::class, 'flags']);
        Route::post('feature-flags', [SystemAdminController::class, 'updateFlags']);
        Route::get('maintenance', [SystemAdminController::class, 'maintenance']);
        Route::post('maintenance', [SystemAdminController::class, 'updateMaintenance']);
    });
});
