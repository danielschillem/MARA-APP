<?php

namespace App\Services;

use App\Models\ReliefWebReport;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ReliefWebService
{
    private const API_URL = 'https://api.reliefweb.int/v2/reports';
    private const APP_NAME = 'mara-observatory-bf';

    /**
     * Fetch reports from ReliefWeb API for Burkina Faso / Protection theme.
     */
    public function fetchReports(int $limit = 200, int $offset = 0): array
    {
        $payload = [
            'appname' => self::APP_NAME,
            'limit' => min($limit, 1000),
            'offset' => $offset,
            'sort' => ['date:desc'],
            'filter' => [
                'operator' => 'AND',
                'conditions' => [
                    ['field' => 'country', 'value' => 'Burkina Faso'],
                    [
                        'field' => 'theme',
                        'operator' => 'OR',
                        'value' => [
                            'Protection and Human Rights',
                            'Gender-Based Violence',
                        ],
                    ],
                ],
            ],
            'fields' => [
                'include' => [
                    'title', 'body', 'url_alias', 'date.created',
                    'source.name', 'country.name', 'theme.name',
                    'disaster_type.name', 'format.name', 'language.name',
                ],
            ],
        ];

        $response = Http::timeout(30)
            ->withOptions(['verify' => false])
            ->post(self::API_URL . '?appname=' . self::APP_NAME, $payload);

        if (!$response->successful()) {
            Log::error('ReliefWeb API error', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
            return ['data' => [], 'totalCount' => 0];
        }

        $json = $response->json();

        return [
            'data' => $json['data'] ?? [],
            'totalCount' => $json['totalCount'] ?? 0,
        ];
    }

    /**
     * Sync ReliefWeb reports into local database.
     */
    public function sync(int $maxPages = 5): int
    {
        $imported = 0;
        $limit = 200;

        for ($page = 0; $page < $maxPages; $page++) {
            $result = $this->fetchReports($limit, $page * $limit);

            if (empty($result['data'])) {
                break;
            }

            foreach ($result['data'] as $item) {
                $fields = $item['fields'] ?? [];
                $rwId = $item['id'] ?? null;

                if (!$rwId) continue;

                ReliefWebReport::updateOrCreate(
                    ['rw_id' => $rwId],
                    [
                        'title' => mb_substr($fields['title'] ?? '', 0, 500),
                        'body' => mb_substr($fields['body'] ?? '', 0, 10000),
                        'url' => isset($fields['url_alias'])
                            ? 'https://reliefweb.int' . $fields['url_alias']
                            : null,
                        'source' => $this->extractFirst($fields, 'source'),
                        'country' => $this->extractFirst($fields, 'country'),
                        'theme' => $this->extractNames($fields, 'theme'),
                        'disaster_type' => $this->extractFirst($fields, 'disaster_type'),
                        'format' => $this->extractFirst($fields, 'format'),
                        'language' => $this->extractFirst($fields, 'language'),
                        'published_at' => isset($fields['date']['created'])
                            ? date('Y-m-d', strtotime($fields['date']['created']))
                            : null,
                    ]
                );
                $imported++;
            }

            // If we got fewer than requested, we've reached the end
            if (count($result['data']) < $limit) {
                break;
            }
        }

        return $imported;
    }

    private function extractFirst(array $fields, string $key): ?string
    {
        if (!isset($fields[$key])) return null;
        $items = is_array($fields[$key]) ? $fields[$key] : [$fields[$key]];
        $first = reset($items);
        return is_array($first) ? ($first['name'] ?? null) : $first;
    }

    private function extractNames(array $fields, string $key): ?string
    {
        if (!isset($fields[$key])) return null;
        $items = is_array($fields[$key]) ? $fields[$key] : [$fields[$key]];
        $names = array_map(fn($i) => is_array($i) ? ($i['name'] ?? '') : $i, $items);
        return implode(', ', array_filter($names));
    }
}
