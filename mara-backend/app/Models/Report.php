<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Report extends Model
{
    protected $fillable = [
        'reference', 'reporter_type', 'victim_gender', 'victim_age_range',
        'perpetrator_relation', 'region', 'province', 'lieu_description',
        'latitude', 'longitude', 'incident_date', 'description',
        'victim_status', 'contact_phone', 'contact_time_pref',
        'status', 'priority', 'assigned_to', 'notes',
    ];

    protected function casts(): array
    {
        return [
            'incident_date' => 'date',
            'latitude' => 'float',
            'longitude' => 'float',
        ];
    }

    public static function generateReference(): string
    {
        $year = now()->year;
        $last = static::whereYear('created_at', $year)->count() + 1;
        return sprintf('MARA-%d-%04d', $year, $last);
    }

    public function violenceTypes(): BelongsToMany
    {
        return $this->belongsToMany(ViolenceType::class);
    }

    public function attachments(): HasMany
    {
        return $this->hasMany(ReportAttachment::class);
    }

    public function assignedTo(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_to');
    }
}
