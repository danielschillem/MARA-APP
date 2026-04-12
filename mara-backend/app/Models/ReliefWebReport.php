<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ReliefWebReport extends Model
{
    protected $table = 'reliefweb_reports';

    protected $fillable = [
        'rw_id', 'title', 'body', 'url', 'source',
        'country', 'theme', 'disaster_type', 'format',
        'language', 'published_at',
    ];

    protected $casts = [
        'published_at' => 'date',
    ];
}
