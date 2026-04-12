<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ServiceDirectory;
use App\Models\SosNumber;
use App\Models\ViolenceType;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DirectoryController extends Controller
{
    public function services(Request $request): JsonResponse
    {
        $query = ServiceDirectory::query();

        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }
        if ($request->filled('region')) {
            $query->where('region', $request->region);
        }
        if ($request->filled('search')) {
            $s = $request->search;
            $query->where(function ($q) use ($s) {
                $q->where('name', 'like', "%{$s}%")
                  ->orWhere('address', 'like', "%{$s}%")
                  ->orWhere('phone', 'like', "%{$s}%");
            });
        }

        return response()->json($query->orderBy('name')->get());
    }

    public function sosNumbers(): JsonResponse
    {
        return response()->json(
            SosNumber::orderBy('sort_order')->get()
        );
    }

    public function violenceTypes(): JsonResponse
    {
        return response()->json(ViolenceType::all());
    }
}
