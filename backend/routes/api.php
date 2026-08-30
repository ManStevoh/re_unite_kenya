<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CatalogController;
use App\Http\Controllers\Api\V1\ClaimController;
use App\Http\Controllers\Api\V1\ConversationController;
use App\Http\Controllers\Api\V1\HandoverController;
use App\Http\Controllers\Api\V1\MeController;
use App\Http\Controllers\Api\V1\MiscController;
use App\Http\Controllers\Api\V1\ReportController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('auth/register', [AuthController::class, 'register']);
    Route::post('auth/login', [AuthController::class, 'login'])->middleware('throttle:login');
    Route::post('auth/refresh', [AuthController::class, 'refresh']);
    Route::post('auth/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('auth/reset-password', [AuthController::class, 'resetPassword']);
    Route::post('auth/email/verify', [AuthController::class, 'verifyEmail']);
    Route::post('auth/phone/otp/send', [AuthController::class, 'sendPhoneOtp'])->middleware('throttle:otp');
    Route::post('auth/phone/otp/confirm', [AuthController::class, 'confirmPhoneOtp'])->middleware('throttle:otp');

    Route::get('categories', [CatalogController::class, 'categories']);
    Route::get('hubs', [CatalogController::class, 'hubs']);
    Route::get('hubs/{hub}', [CatalogController::class, 'hub']);
    Route::get('cms', [CatalogController::class, 'cmsIndex']);
    Route::get('cms/{slug}', [CatalogController::class, 'cms']);
    Route::get('reports', [ReportController::class, 'index']);
    Route::get('reports/{report}', [ReportController::class, 'show']);
    Route::get('search', [MiscController::class, 'search'])->middleware('throttle:search');
    Route::get('tags/{code}', [MiscController::class, 'tag']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);

        Route::get('me', [MeController::class, 'show']);
        Route::patch('me', [MeController::class, 'update']);
        Route::post('me/password', [MeController::class, 'password']);
        Route::get('me/reports', [MeController::class, 'reports']);
        Route::get('me/drafts', [MeController::class, 'drafts']);
        Route::get('me/activity', [MeController::class, 'activity']);
        Route::post('me/block', [MeController::class, 'block']);
        Route::post('support', [MeController::class, 'support']);
        Route::get('me/devices', [MeController::class, 'devices']);
        Route::delete('me/devices/{device}', [MeController::class, 'destroyDevice']);
        Route::get('me/notification-preferences', [MeController::class, 'notificationPreferences']);
        Route::patch('me/notification-preferences', [MeController::class, 'updateNotificationPreferences']);
        Route::post('me/data-export', [MeController::class, 'dataExport']);
        Route::post('me/deactivate', [MeController::class, 'deactivate']);
        Route::post('me/delete', [MeController::class, 'destroy']);

        Route::post('reports', [ReportController::class, 'store']);
        Route::patch('reports/{report}', [ReportController::class, 'update']);
        Route::post('reports/{report}/submit', [ReportController::class, 'submit']);
        Route::post('reports/{report}/close', [ReportController::class, 'close']);
        Route::get('reports/{report}/matches', [ReportController::class, 'matches']);
        Route::post('reports/{report}/media', [ReportController::class, 'media']);

        Route::get('claims', [ClaimController::class, 'index']);
        Route::post('claims', [ClaimController::class, 'store'])->middleware('throttle:claims');
        Route::get('claims/{claim}', [ClaimController::class, 'show']);
        Route::post('claims/{claim}/review', [ClaimController::class, 'review']);
        Route::post('claims/{claim}/more-info', [ClaimController::class, 'requestMoreInfo']);
        Route::post('claims/{claim}/answers', [ClaimController::class, 'answers']);
        Route::post('claims/{claim}/evidence', [ClaimController::class, 'evidence']);
        Route::post('claims/{claim}/withdraw', [ClaimController::class, 'withdraw']);

        Route::get('conversations', [ConversationController::class, 'index']);
        Route::get('conversations/{conversation}/messages', [ConversationController::class, 'messages']);
        Route::post('conversations/{conversation}/messages', [ConversationController::class, 'storeMessage']);

        Route::post('handovers', [HandoverController::class, 'store']);
        Route::get('handovers/{handover}', [HandoverController::class, 'show']);
        Route::post('handovers/{handover}/confirm', [HandoverController::class, 'confirm']);

        Route::get('notifications', [MiscController::class, 'notifications']);
        Route::post('notifications/{id}/read', [MiscController::class, 'readNotification']);
        Route::post('flags', [MiscController::class, 'flag']);
        Route::post('tips', [MiscController::class, 'tip']);
    });
});
