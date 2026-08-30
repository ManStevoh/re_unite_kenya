<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConversationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $rows = Conversation::query()
            ->whereHas('participants', fn ($q) => $q->where('users.id', $request->user()->id))
            ->with(['itemReport', 'messages' => fn ($q) => $q->latest()->limit(1)])
            ->latest()
            ->paginate(20);

        return response()->json([
            'data' => $rows->map(fn (Conversation $c) => [
                'id' => $c->id,
                'status' => $c->status,
                'flagged' => $c->flagged,
                'item' => $c->itemReport?->toTeaserDto(),
                'last_message' => $c->messages->first(),
            ]),
        ]);
    }

    public function messages(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('view', $conversation);
        $messages = $conversation->messages()->with('user')->orderBy('created_at')->paginate(50);

        return response()->json([
            'data' => $messages->map(fn (Message $m) => [
                'id' => $m->id,
                'body' => $m->body,
                'image_path' => $m->image_path,
                'created_at' => $m->created_at?->toIso8601String(),
                'user' => $m->user?->toUserDto(),
            ]),
        ]);
    }

    public function storeMessage(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('message', $conversation);
        $data = $request->validate([
            'body' => ['required', 'string', 'max:2000'],
            'image_path' => ['nullable', 'string'],
        ]);

        $message = $conversation->messages()->create([
            'user_id' => $request->user()->id,
            'body' => $data['body'],
            'image_path' => $data['image_path'] ?? null,
        ]);

        return response()->json(['data' => $message], 201);
    }
}
