<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ConversationController extends Controller
{
    /**
     * List conversations (auth required).
     * - admin: all conversations
     * - conseiller: assigned to them OR unassigned (waiting)
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $status = $request->query('status'); // active, fermee, waiting

        $query = Conversation::with(['user:id,name', 'conseiller:id,name'])
            ->withCount('messages')
            ->withMax('messages', 'created_at');

        if ($user->role === 'conseiller') {
            $query->where(function ($q) use ($user) {
                $q->where('conseiller_id', $user->id)
                  ->orWhereNull('conseiller_id');
            });
        }

        if ($status === 'waiting') {
            $query->whereNull('conseiller_id')->where('status', 'active');
        } elseif ($status) {
            $query->where('status', $status);
        }

        $conversations = $query->latest()->paginate(20);

        // Add last message preview and unread count
        $conversations->getCollection()->transform(function ($conv) {
            $lastMsg = $conv->messages()->latest()->first();
            $conv->last_message_preview = $lastMsg ? Str::limit($lastMsg->body, 60) : null;
            $conv->last_message_at = $lastMsg?->created_at;
            $conv->unread_count = $conv->messages()->where('is_from_visitor', true)->where('is_read', false)->count();
            return $conv;
        });

        return response()->json($conversations);
    }

    /**
     * Create an authenticated conversation.
     */
    public function store(Request $request): JsonResponse
    {
        $conversation = Conversation::create([
            'user_id' => $request->user()->id,
            'session_token' => Str::uuid()->toString(),
            'status' => 'active',
        ]);

        return response()->json($conversation, 201);
    }

    /**
     * Start an anonymous conversation (no auth required).
     */
    public function startAnonymous(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'initial_message' => 'nullable|string|max:2000',
        ]);

        $conversation = Conversation::create([
            'session_token' => Str::uuid()->toString(),
            'status' => 'active',
        ]);

        // Auto welcome message from system
        $conversation->messages()->create([
            'body' => 'Bienvenue sur le chat confidentiel MARA. Un conseiller va vous répondre sous peu. Comment pouvons-nous vous aider ?',
            'is_from_visitor' => false,
        ]);

        // If visitor sent an initial message, save it
        if (!empty($validated['initial_message'])) {
            $conversation->messages()->create([
                'body' => $validated['initial_message'],
                'is_from_visitor' => true,
            ]);
        }

        return response()->json([
            'conversation_id' => $conversation->id,
            'session_token' => $conversation->session_token,
        ], 201);
    }

    /**
     * Show a conversation. Anonymous access via ?token= query param.
     */
    public function show(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorizeAccess($request, $conversation);

        return response()->json(
            $conversation->load(['messages.sender:id,name', 'user:id,name', 'conseiller:id,name'])
        );
    }

    /**
     * Send a message to a conversation.
     * Anonymous visitors must provide ?token= matching session_token.
     * Authenticated conseillers set is_from_visitor=false automatically.
     */
    public function sendMessage(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorizeAccess($request, $conversation);

        if ($conversation->status === 'fermee') {
            return response()->json(['message' => 'Cette conversation est fermée.'], 403);
        }

        $validated = $request->validate([
            'body' => 'nullable|string|max:5000',
            'audio' => 'nullable|file|mimes:webm,mp4,ogg,wav,m4a|max:10240',
        ]);

        // Require either body text or audio
        if (empty($validated['body']) && !$request->hasFile('audio')) {
            return response()->json(['message' => 'Un message texte ou vocal est requis.'], 422);
        }

        $user = $request->user();
        $isVisitor = !$user;

        // If authenticated conseiller sends a message, auto-assign if not yet assigned
        if ($user && !$isVisitor && !$conversation->conseiller_id) {
            $conversation->update(['conseiller_id' => $user->id]);
        }

        $msgData = [
            'sender_id' => $user?->id,
            'is_from_visitor' => $isVisitor,
            'body' => $validated['body'] ?? '',
        ];

        // Handle audio upload
        if ($request->hasFile('audio')) {
            $file = $request->file('audio');
            $path = $file->store('chat_audio/' . $conversation->id, 'local');
            $msgData['audio_path'] = $path;
            $msgData['audio_mime'] = $file->getClientMimeType();
            if ($request->filled('audio_duration')) {
                $msgData['audio_duration'] = (int) $request->input('audio_duration');
            }
        }

        $message = $conversation->messages()->create($msgData);

        return response()->json($message->load('sender:id,name'), 201);
    }

    /**
     * Get messages with polling support: ?after={id} returns only new messages.
     */
    public function messages(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorizeAccess($request, $conversation);

        $query = $conversation->messages()->with('sender:id,name');

        // Incremental polling: only return messages after a given ID
        if ($request->filled('after')) {
            $query->where('id', '>', (int) $request->query('after'));
        }

        // Mark messages as read depending on who is reading
        $user = $request->user();
        if ($user) {
            // Conseiller is reading → mark visitor messages as read
            $conversation->messages()
                ->where('is_from_visitor', true)
                ->where('is_read', false)
                ->update(['is_read' => true]);
        }

        $messages = $query->oldest()->get();

        return response()->json($messages);
    }

    /**
     * Assign a conseiller to a conversation.
     */
    public function assign(Request $request, Conversation $conversation): JsonResponse
    {
        if ($conversation->conseiller_id && $conversation->conseiller_id !== $request->user()->id) {
            return response()->json(['message' => 'Un conseiller est déjà assigné.'], 409);
        }

        $conversation->update(['conseiller_id' => $request->user()->id]);

        return response()->json([
            'message' => 'Conversation prise en charge',
            'conversation' => $conversation->fresh(['user:id,name', 'conseiller:id,name']),
        ]);
    }

    /**
     * Close a conversation.
     */
    public function close(Request $request, Conversation $conversation): JsonResponse
    {
        $conversation->messages()->create([
            'sender_id' => $request->user()->id,
            'is_from_visitor' => false,
            'body' => 'La conversation a été clôturée par un conseiller. N\'hésitez pas à nous recontacter.',
        ]);

        $conversation->update(['status' => 'fermee']);

        return response()->json(['message' => 'Conversation fermée']);
    }

    /**
     * Authorize access: auth user OR anonymous with valid session token.
     */
    private function authorizeAccess(Request $request, Conversation $conversation): void
    {
        $user = $request->user();

        // Authenticated users (admin, conseiller, professionnel) can access any conversation
        if ($user) {
            return;
        }

        // Anonymous visitor must provide a valid session token
        $token = $request->query('token') ?? $request->header('X-Session-Token');
        if (!$token || $token !== $conversation->session_token) {
            abort(403, 'Accès non autorisé à cette conversation.');
        }
    }
}
