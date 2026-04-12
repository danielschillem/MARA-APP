<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Resource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ResourceController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Resource::where('is_published', true);

        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }
        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }
        if ($request->filled('search')) {
            $s = $request->search;
            $query->where(function ($q) use ($s) {
                $q->where('title', 'like', "%{$s}%")
                  ->orWhere('description', 'like', "%{$s}%")
                  ->orWhere('tag', 'like', "%{$s}%");
            });
        }

        return response()->json($query->latest()->paginate($request->input('per_page', 12)));
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'type' => 'required|in:article,video,loi,guide,infographie,formation,audio',
            'category' => 'nullable|string',
            'icon' => 'nullable|string',
            'url' => 'nullable|url',
            'audio_url' => 'nullable|url',
            'duration' => 'nullable|string',
            'tag' => 'nullable|string',
        ]);

        $resource = Resource::create($validated);

        return response()->json($resource, 201);
    }

    public function show(Resource $resource): JsonResponse
    {
        return response()->json($resource);
    }

    public function update(Request $request, Resource $resource): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'type' => 'sometimes|in:article,video,loi,guide,infographie,formation,audio',
            'is_published' => 'sometimes|boolean',
            'audio_url' => 'nullable|url',
        ]);

        $resource->update($validated);

        return response()->json($resource);
    }

    public function destroy(Resource $resource): JsonResponse
    {
        $resource->delete();

        return response()->json(['message' => 'Ressource supprimée']);
    }
}
