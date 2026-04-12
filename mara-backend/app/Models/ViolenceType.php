<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class ViolenceType extends Model
{
    protected $fillable = ['slug', 'label_fr', 'label_en', 'icon'];

    public function reports(): BelongsToMany
    {
        return $this->belongsToMany(Report::class);
    }
}
