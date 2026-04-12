<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Report;
use App\Models\ReportAttachment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ReportController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Report::with(['violenceTypes', 'assignedTo']);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('region')) {
            $query->where('region', $request->region);
        }
        if ($request->filled('priority')) {
            $query->where('priority', $request->priority);
        }
        if ($request->filled('assigned_to')) {
            $request->assigned_to === 'unassigned'
                ? $query->whereNull('assigned_to')
                : $query->where('assigned_to', $request->assigned_to);
        }
        if ($request->filled('search')) {
            $s = $request->search;
            $query->where(function ($q) use ($s) {
                $q->where('reference', 'like', "%{$s}%")
                  ->orWhere('description', 'like', "%{$s}%")
                  ->orWhere('region', 'like', "%{$s}%");
            });
        }
        if ($request->filled('date_from')) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }
        if ($request->filled('date_to')) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        $reports = $query->latest()->paginate($request->input('per_page', 15));

        return response()->json($reports);
    }

    public function store(Request $request): JsonResponse
    {
        // Description is required only if no voice note is uploaded
        $descriptionRule = $request->hasFile('voice_note')
            ? 'nullable|string|max:5000'
            : 'required|string|min:10|max:5000';

        $validated = $request->validate([
            'reporter_type' => 'required|in:victime,temoin,proche,professionnel',
            'victim_gender' => 'required|in:feminin,masculin,autre',
            'victim_age_range' => 'nullable|string|max:10',
            'perpetrator_relation' => 'nullable|string|max:50',
            'region' => 'nullable|string|max:100',
            'province' => 'nullable|string|max:100',
            'lieu_description' => 'nullable|string|max:500',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'incident_date' => 'nullable|date|before_or_equal:today',
            'description' => $descriptionRule,
            'victim_status' => 'nullable|in:en_securite,danger_immediat,hospitalisee,disparue,inconnu',
            'contact_phone' => 'nullable|string|max:20',
            'contact_time_pref' => 'nullable|string|max:50',
            'violence_type_ids' => 'required|array|min:1',
            'violence_type_ids.*' => 'exists:violence_types,id',
            'voice_note' => 'nullable|file|mimes:webm,mp4,ogg,wav,m4a|max:10240',
        ], [
            'description.required' => 'La description des faits est obligatoire.',
            'description.min' => 'La description doit contenir au moins 10 caractères.',
            'violence_type_ids.required' => 'Veuillez sélectionner au moins un type de violence.',
            'violence_type_ids.min' => 'Veuillez sélectionner au moins un type de violence.',
            'incident_date.before_or_equal' => 'La date ne peut pas être dans le futur.',
            'voice_note.max' => 'La note vocale ne doit pas dépasser 10 Mo.',
            'voice_note.mimes' => 'Format audio non supporté. Formats acceptés : webm, mp4, ogg, wav, m4a.',
        ]);

        $validated['reference'] = Report::generateReference();

        // Auto-escalade : danger immédiat → priorité critique
        if (($validated['victim_status'] ?? 'inconnu') === 'danger_immediat') {
            $validated['priority'] = 'critique';
            $validated['status'] = 'urgent';
        }

        $report = Report::create($validated);
        $report->violenceTypes()->sync($validated['violence_type_ids']);

        // Save voice note attachment if uploaded
        if ($request->hasFile('voice_note')) {
            $file = $request->file('voice_note');
            $path = $file->store('report_attachments/' . $report->id, 'local');

            ReportAttachment::create([
                'report_id' => $report->id,
                'filename' => $file->getClientOriginalName(),
                'path' => $path,
                'mime_type' => $file->getClientMimeType(),
                'size' => $file->getSize(),
            ]);
        }

        return response()->json([
            'message' => 'Signalement enregistré avec succès',
            'report' => $report->load('violenceTypes', 'attachments'),
        ], 201);
    }

    public function track(string $reference): JsonResponse
    {
        $report = Report::where('reference', $reference)
            ->select(['id', 'reference', 'status', 'priority', 'region', 'created_at', 'updated_at'])
            ->first();

        if (!$report) {
            return response()->json(['message' => 'Aucun signalement trouvé avec cette référence.'], 404);
        }

        $statusLabels = [
            'nouveau' => 'Reçu — En attente de traitement',
            'en_cours' => 'En cours de traitement',
            'urgent' => 'Marqué comme urgent — Traitement prioritaire',
            'resolu' => 'Résolu',
            'cloture' => 'Clôturé',
        ];

        return response()->json([
            'reference' => $report->reference,
            'status' => $report->status,
            'status_label' => $statusLabels[$report->status] ?? $report->status,
            'priority' => $report->priority,
            'region' => $report->region,
            'created_at' => $report->created_at,
            'updated_at' => $report->updated_at,
        ]);
    }

    public function show(Report $report): JsonResponse
    {
        return response()->json(
            $report->load(['violenceTypes', 'attachments', 'assignedTo'])
        );
    }

    public function update(Request $request, Report $report): JsonResponse
    {
        $validated = $request->validate([
            'status' => 'sometimes|in:nouveau,en_cours,resolu,urgent,cloture',
            'priority' => 'sometimes|in:basse,moyenne,haute,critique',
            'assigned_to' => 'sometimes|nullable|exists:users,id',
            'notes' => 'sometimes|nullable|string|max:5000',
        ]);

        $report->update($validated);

        return response()->json($report->fresh(['violenceTypes', 'assignedTo']));
    }

    public function stats(): JsonResponse
    {
        $total = Report::count();
        $byStatus = Report::selectRaw('status, count(*) as count')->groupBy('status')->pluck('count', 'status');
        $byRegion = Report::selectRaw('region, count(*) as count')->groupBy('region')->pluck('count', 'region');
        $byPriority = Report::selectRaw('priority, count(*) as count')->groupBy('priority')->pluck('count', 'priority');
        $byMonth = Report::selectRaw("strftime('%Y-%m', created_at) as month, count(*) as count")
            ->groupBy('month')->orderBy('month')->pluck('count', 'month');

        return response()->json(compact('total', 'byStatus', 'byRegion', 'byPriority', 'byMonth'));
    }
}
