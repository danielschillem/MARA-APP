<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ServiceDirectory extends Model
{
    protected $fillable = [
        'name', 'type', 'description', 'address', 'region',
        'phone', 'email', 'website', 'hours', 'is_free', 'is_24h',
        'latitude', 'longitude',
    ];

    protected function casts(): array
    {
        return [
            'is_free' => 'boolean',
            'is_24h' => 'boolean',
        ];
    }
}
