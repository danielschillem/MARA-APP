<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SosNumber extends Model
{
    protected $fillable = ['label', 'description', 'number', 'icon', 'sort_order'];
}
