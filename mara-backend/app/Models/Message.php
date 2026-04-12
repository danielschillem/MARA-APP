<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Message extends Model
{
    protected $fillable = ['conversation_id', 'sender_id', 'is_from_visitor', 'body', 'is_read', 'audio_path', 'audio_mime', 'audio_duration'];

    protected $appends = ['audio_url'];

    protected function casts(): array
    {
        return [
            'is_from_visitor' => 'boolean',
            'is_read' => 'boolean',
            'audio_duration' => 'integer',
        ];
    }

    public function getAudioUrlAttribute(): ?string
    {
        return $this->audio_path ? url('/api/messages/' . $this->id . '/audio') : null;
    }

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_id');
    }
}
