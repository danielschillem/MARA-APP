<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ReportAttachment extends Model
{
    protected $fillable = ['report_id', 'filename', 'path', 'mime_type', 'size'];

    public function report(): BelongsTo
    {
        return $this->belongsTo(Report::class);
    }
}
