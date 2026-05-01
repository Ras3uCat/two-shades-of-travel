# Backend Dev — Detailed Implementation Guide

## Migration Templates

### New Table with RLS
```sql
-- supabase/migrations/20260326000000_create_items_table.sql
-- Purpose: Create items table for [feature] with user-scoped RLS

CREATE TABLE IF NOT EXISTS public.items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  data        JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER items_updated_at
  BEFORE UPDATE ON public.items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_read_own_items" ON public.items
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "users_insert_own_items" ON public.items
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "users_update_own_items" ON public.items
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "users_delete_own_items" ON public.items
  FOR DELETE USING (auth.uid() = user_id);

-- Rollback: DROP TABLE public.items; DROP TRIGGER items_updated_at ON public.items;
```

### Adding a Column
```sql
-- supabase/migrations/20260326000001_add_status_to_items.sql
-- Purpose: Add status enum to items table

CREATE TYPE item_status AS ENUM ('draft', 'active', 'archived');

ALTER TABLE public.items
  ADD COLUMN status item_status NOT NULL DEFAULT 'draft';

-- No RLS change needed (existing policies cover all columns)

-- Rollback:
-- ALTER TABLE public.items DROP COLUMN status;
-- DROP TYPE item_status;
```

## BaseRepository (Dart)

```dart
// lib/core/base/base_repository.dart
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

/// Sealed failure type — all repositories return this on error
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ApiFailure extends Failure {
  final int? statusCode;
  const ApiFailure(super.message, {this.statusCode});

  factory ApiFailure.fromDioError(DioException e) {
    final code = e.response?.statusCode;
    final msg = switch (code) {
      400 => 'Invalid request',
      401 => 'Unauthorized',
      403 => 'Forbidden',
      404 => 'Not found',
      422 => 'Validation error',
      500 => 'Server error',
      _   => e.message ?? 'Unknown error',
    };
    return ApiFailure(msg, statusCode: code);
  }
}

abstract class BaseRepository {
  // Shared helper for safe JSON casting
  T cast<T>(dynamic value) => value as T;
}
```

## RLS Policy Patterns

### Premium Content (is_premium gate)
```sql
-- Only premium users can read premium content
CREATE POLICY "premium_content_read" ON public.premium_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_premium = true
    )
  );
```

### Admin Access
```sql
-- Admins can read everything
CREATE POLICY "admin_read_all" ON public.items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );
```

### Public Read, Owner Write
```sql
CREATE POLICY "public_read" ON public.posts
  FOR SELECT USING (true);

CREATE POLICY "owner_write" ON public.posts
  FOR ALL USING (auth.uid() = author_id);
```

## Supabase Client Setup (Dart)

```dart
// lib/core/services/supabase_service.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService extends GetxService {
  static SupabaseClient get client => Supabase.instance.client;

  Future<SupabaseService> init() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    return this;
  }
}
```

## Repository with Supabase (instead of REST)

```dart
class ItemsRepository extends BaseRepository {
  final _client = SupabaseService.client;

  Future<Either<Failure, List<ItemModel>>> getItems() async {
    try {
      final data = await _client
          .from('items')
          .select()
          .order('created_at', ascending: false);
      return Right(data.map(ItemModel.fromJson).toList());
    } on PostgrestException catch (e) {
      return Left(ApiFailure(e.message, statusCode: int.tryParse(e.code ?? '')));
    }
  }

  Future<Either<Failure, ItemModel>> createItem(CreateItemDto dto) async {
    try {
      final data = await _client
          .from('items')
          .insert(dto.toJson())
          .select()
          .single();
      return Right(ItemModel.fromJson(data));
    } on PostgrestException catch (e) {
      return Left(ApiFailure(e.message));
    }
  }
}
```

## Edge Function Template

```typescript
// supabase/functions/my-function/index.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface RequestBody {
  userId: string;
}

Deno.serve(async (req: Request) => {
  // Auth check
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response('Unauthorized', { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } }
  );

  // Verify the calling user
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return new Response('Unauthorized', { status: 401 });
  }

  const body: RequestBody = await req.json();

  // Business logic here (server-side, trusted)
  const { data, error } = await supabase
    .from('items')
    .select()
    .eq('user_id', user.id);

  if (error) return new Response(error.message, { status: 500 });

  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json' },
  });
});
```
