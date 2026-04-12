<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ReliefWebReport;
use App\Services\ReliefWebService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ObservatoryController extends Controller
{
    /**
     * GET /api/observatory/stats — Aggregated statistics for the observatory.
     */
    public function stats(): JsonResponse
    {
        $total = ReliefWebReport::count();

        if ($total === 0) {
            return response()->json([
                'total' => 0,
                'sources' => [],
                'themes' => [],
                'by_year' => [],
                'by_month' => [],
                'by_format' => [],
                'date_range' => null,
                'recent' => [],
                'last_sync' => null,
            ]);
        }

        // Reports by source
        $sources = ReliefWebReport::select('source', DB::raw('COUNT(*) as count'))
            ->whereNotNull('source')
            ->groupBy('source')
            ->orderByDesc('count')
            ->limit(20)
            ->pluck('count', 'source');

        // Reports by theme (themes are comma-separated, need to split)
        $allThemes = ReliefWebReport::whereNotNull('theme')->pluck('theme');
        $themeCounts = [];
        foreach ($allThemes as $themeStr) {
            foreach (explode(', ', $themeStr) as $t) {
                $t = trim($t);
                if ($t) {
                    $themeCounts[$t] = ($themeCounts[$t] ?? 0) + 1;
                }
            }
        }
        arsort($themeCounts);
        $themeCounts = array_slice($themeCounts, 0, 15, true);

        // Reports by year
        $byYear = ReliefWebReport::select(
                DB::raw("strftime('%Y', published_at) as year"),
                DB::raw('COUNT(*) as count')
            )
            ->whereNotNull('published_at')
            ->groupBy('year')
            ->orderBy('year')
            ->pluck('count', 'year');

        // Reports by month (last 24 months)
        $byMonth = ReliefWebReport::select(
                DB::raw("strftime('%Y-%m', published_at) as month"),
                DB::raw('COUNT(*) as count')
            )
            ->whereNotNull('published_at')
            ->where('published_at', '>=', now()->subMonths(24)->startOfMonth())
            ->groupBy('month')
            ->orderBy('month')
            ->pluck('count', 'month');

        // Reports by format
        $byFormat = ReliefWebReport::select('format', DB::raw('COUNT(*) as count'))
            ->whereNotNull('format')
            ->groupBy('format')
            ->orderByDesc('count')
            ->pluck('count', 'format');

        // Date range
        $dateRange = [
            'min' => ReliefWebReport::min('published_at'),
            'max' => ReliefWebReport::max('published_at'),
        ];

        // Recent reports
        $recent = ReliefWebReport::orderByDesc('published_at')
            ->limit(10)
            ->get(['id', 'rw_id', 'title', 'source', 'theme', 'published_at', 'url', 'format']);

        // Last sync
        $lastSync = ReliefWebReport::max('updated_at');

        return response()->json([
            'total' => $total,
            'sources' => $sources,
            'themes' => $themeCounts,
            'by_year' => $byYear,
            'by_month' => $byMonth,
            'by_format' => $byFormat,
            'date_range' => $dateRange,
            'recent' => $recent,
            'last_sync' => $lastSync,
        ]);
    }

    /**
     * GET /api/observatory/reports — Paginated list with filters.
     */
    public function reports(Request $request): JsonResponse
    {
        $query = ReliefWebReport::query();

        if ($search = $request->input('search')) {
            $query->where('title', 'like', '%' . $search . '%');
        }
        if ($source = $request->input('source')) {
            $query->where('source', $source);
        }
        if ($theme = $request->input('theme')) {
            $query->where('theme', 'like', '%' . $theme . '%');
        }
        if ($year = $request->input('year')) {
            $query->whereYear('published_at', $year);
        }
        if ($format = $request->input('format')) {
            $query->where('format', $format);
        }

        $reports = $query->orderByDesc('published_at')
            ->paginate($request->input('per_page', 20));

        return response()->json($reports);
    }

    /**
     * POST /api/observatory/sync — Trigger manual sync (admin only).
     */
    public function sync(ReliefWebService $service): JsonResponse
    {
        $count = $service->sync(5);

        return response()->json([
            'message' => "{$count} rapports synchronisés depuis ReliefWeb.",
            'count' => $count,
        ]);
    }
}
