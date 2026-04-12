<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ConversationController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\DirectoryController;
use App\Http\Controllers\Api\ObservatoryController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\ResourceController;
use App\Models\Announcement;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

// Auth routes with rate limiting (20 attempts per minute per IP)
Route::middleware('throttle:20,1')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
});

// Public data
Route::get('/violence-types', [DirectoryController::class, 'violenceTypes']);
Route::get('/sos-numbers', [DirectoryController::class, 'sosNumbers']);
Route::get('/services', [DirectoryController::class, 'services']);
Route::get('/resources', [ResourceController::class, 'index']);
Route::get('/resources/{resource}', [ResourceController::class, 'show']);
Route::get('/announcements', function () {
    return response()->json(Announcement::active()->orderBy('sort_order')->get());
});

// Public report (anonymous reporting) — rate limited
Route::middleware('throttle:20,1')->group(function () {
    Route::post('/reports', [ReportController::class, 'store']);
});
Route::get('/reports/track/{reference}', [ReportController::class, 'track']);

// Anonymous chat
Route::post('/conversations/anonymous', [ConversationController::class, 'startAnonymous']);
Route::get('/conversations/{conversation}', [ConversationController::class, 'show']);
Route::get('/conversations/{conversation}/messages', [ConversationController::class, 'messages']);
Route::post('/conversations/{conversation}/messages', [ConversationController::class, 'sendMessage']);

// Serve audio messages (public, access controlled by conversation token in referrer)
Route::get('/messages/{message}/audio', function (\App\Models\Message $message) {
    if (!$message->audio_path || !Storage::disk('local')->exists($message->audio_path)) {
        abort(404);
    }
    return response()->file(
        Storage::disk('local')->path($message->audio_path),
        ['Content-Type' => $message->audio_mime ?? 'audio/webm']
    );
});

// Observatory — public stats, protected sync
Route::get('/observatory/stats', [ObservatoryController::class, 'stats']);
Route::get('/observatory/reports', [ObservatoryController::class, 'reports']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/change-password', [AuthController::class, 'changePassword']);

    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index']);
    Route::get('/reports/stats', [ReportController::class, 'stats']);

    // Reports management
    Route::get('/reports', [ReportController::class, 'index']);
    Route::get('/reports/{report}', [ReportController::class, 'show']);
    Route::put('/reports/{report}', [ReportController::class, 'update']);

    // Conversations management
    Route::get('/conversations', [ConversationController::class, 'index']);
    Route::post('/conversations', [ConversationController::class, 'store']);
    Route::post('/conversations/{conversation}/assign', [ConversationController::class, 'assign']);
    Route::post('/conversations/{conversation}/close', [ConversationController::class, 'close']);

    // Resources management
    Route::post('/resources', [ResourceController::class, 'store']);
    Route::put('/resources/{resource}', [ResourceController::class, 'update']);
    Route::delete('/resources/{resource}', [ResourceController::class, 'destroy']);

    // Observatory sync (admin)
    Route::post('/observatory/sync', [ObservatoryController::class, 'sync']);
});
