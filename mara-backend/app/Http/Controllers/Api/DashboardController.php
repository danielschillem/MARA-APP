<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Report;
use App\Models\Conversation;
use App\Models\Resource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        // Core stats
        $reportsTotal = Report::count();
        $reportsUrgent = Report::where('priority', 'critique')->orWhere('status', 'urgent')->count();
        $reportsNew = Report::where('status', 'nouveau')->count();
        $reportsResolved = Report::where('status', 'resolu')->count();
        $conversationsActive = Conversation::where('status', 'active')->count();
        $conversationsWaiting = Conversation::where('status', 'active')->whereNull('conseiller_id')->count();
        $proOnline = User::where('is_online', true)->whereIn('role', ['professionnel', 'conseiller'])->count();

        // Breakdowns
        $byStatus = Report::selectRaw('status, count(*) as count')->groupBy('status')->pluck('count', 'status');
        $byRegion = Report::selectRaw('region, count(*) as count')->whereNotNull('region')->groupBy('region')->pluck('count', 'region');
        $byPriority = Report::selectRaw('priority, count(*) as count')->groupBy('priority')->pluck('count', 'priority');
        $byMonth = Report::selectRaw("strftime('%Y-%m', created_at) as month, count(*) as count")
            ->groupBy('month')->orderBy('month')->pluck('count', 'month');
        $byViolenceType = \DB::table('report_violence_type')
            ->join('violence_types', 'violence_types.id', '=', 'report_violence_type.violence_type_id')
            ->selectRaw('violence_types.label_fr as label, count(*) as count')
            ->groupBy('violence_types.label_fr')
            ->pluck('count', 'label');

        // Recent activity (last 10 reports)
        $recentReports = Report::with('violenceTypes:id,label_fr')
            ->select('id', 'reference', 'status', 'priority', 'region', 'created_at')
            ->latest()->limit(10)->get();

        // My assigned (for conseiller/professionnel)
        $myAssigned = null;
        if (in_array($user->role, ['conseiller', 'professionnel'])) {
            $myAssigned = Report::where('assigned_to', $user->id)
                ->whereNotIn('status', ['resolu', 'cloture'])
                ->select('id', 'reference', 'status', 'priority', 'region', 'created_at')
                ->latest()->limit(10)->get();
        }

        return response()->json([
            'reports_total' => $reportsTotal,
            'reports_urgent' => $reportsUrgent,
            'reports_new' => $reportsNew,
            'reports_resolved' => $reportsResolved,
            'conversations_active' => $conversationsActive,
            'conversations_waiting' => $conversationsWaiting,
            'professionals_online' => $proOnline,
            'resources_count' => Resource::where('is_published', true)->count(),
            'reports_by_status' => $byStatus,
            'reports_by_region' => $byRegion,
            'reports_by_priority' => $byPriority,
            'reports_by_month' => $byMonth,
            'reports_by_violence_type' => $byViolenceType,
            'recent_reports' => $recentReports,
            'my_assigned' => $myAssigned,
        ]);
    }
}
