# Mintera — Flutter Web + Supabase

Веб‑приложение курсов (создавать и проходить курсы) в стилистике из макета. Домашний экран содержит шапку с логотипом, поиск и две секции с горизонтальными каруселями карточек курсов.

## Запуск

1) Установите Flutter 3.24+ и Chrome.
2) В корне проекта выполните:

```
flutter create .
flutter pub get
```

3) Если хотите сразу посмотреть мок‑данные (без Supabase):

```
flutter run -d chrome
```

4) С Supabase (используются `--dart-define`):

```
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT-ref.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR-ANON-KEY
```

Для production‑сборки:

```
flutter build web \
  --dart-define=SUPABASE_URL=https://... \
  --dart-define=SUPABASE_ANON_KEY=...
```

Логотип можно заменить: положите свой файл в `assets/logo.svg` и при необходимости подключите другой в UI.

## Структура

- `lib/main.dart` — запуск приложения и тема.
- `lib/pages/home_page.dart` — главный экран с поиском и секциями.
- `lib/widgets/*` — карточка курса, шапка, карусель.
- `lib/services/course_service.dart` — загрузка курсов из Supabase с фолбэком на мок‑данные.
- `lib/models/course.dart` — модель курса.
- `lib/supabase_manager.dart` и `lib/config.dart` — инициализация Supabase.

## Настройка Supabase

Включите RLS и создайте таблицы (SQL ниже). Для теста заполните несколько курсов.

### Auth: Email + пароль

- В Dashboard → Authentication → Providers включите Email. 
- При желании отключите требование подтверждения почты для dev (Optional email confirmations) или оставьте по умолчанию.
- Для magic link добавьте Redirect URL (http://localhost:PORT). Для входа по паролю Redirect не обязателен.

### SQL (таблицы и простые политики)

```sql
-- Профили
create table if not exists profiles (
  id uuid primary key references auth.users on delete cascade,
  username text unique,
  avatar_url text,
  bio text,
  created_at timestamp with time zone default now()
);
alter table profiles enable row level security;
create policy "Public read profiles" on profiles for select using (true);
create policy "Owner upsert" on profiles for insert with check (auth.uid() = id);
create policy "Owner update" on profiles for update using (auth.uid() = id);

-- Курсы
create table if not exists courses (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text default '',
  author text not null,
  price integer not null default 0,
  image_url text default '',
  views integer not null default 0,
  likes integer not null default 0,
  rating numeric not null default 0,
  category text not null default 'Остальные курсы',
  owner uuid references auth.users on delete set null,
  created_at timestamp with time zone default now()
);
alter table courses enable row level security;
create policy "Public read courses" on courses for select using (true);
create policy "Owners manage" on courses for all using (auth.uid() = owner) with check (auth.uid() = owner);

-- Уроки
create table if not exists course_lessons (
  id uuid primary key default gen_random_uuid(),
  course_id uuid references courses(id) on delete cascade,
  title text not null,
  content text default '',
  order_index int not null default 0
);
alter table course_lessons enable row level security;
create policy "Public read lessons" on course_lessons for select using (true);
create policy "Owners manage lessons" on course_lessons for all using (
  exists (select 1 from courses c where c.id = course_id and c.owner = auth.uid())
);

-- Записи о прохождении
create table if not exists enrollments (
  user_id uuid references auth.users on delete cascade,
  course_id uuid references courses(id) on delete cascade,
  progress int not null default 0,
  primary key (user_id, course_id)
);
alter table enrollments enable row level security;
create policy "Owner read/write" on enrollments for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Избранное (лайки)
create table if not exists favorites (
  user_id uuid references auth.users on delete cascade,
  course_id uuid references courses(id) on delete cascade,
  liked boolean not null default true,
  primary key (user_id, course_id)
);
alter table favorites enable row level security;
create policy "Owner favorites" on favorites for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Оценки
create table if not exists course_ratings (
  user_id uuid references auth.users on delete cascade,
  course_id uuid references courses(id) on delete cascade,
  rating numeric not null check (rating >= 0 and rating <= 5),
  primary key (user_id, course_id)
);
alter table course_ratings enable row level security;
create policy "Owner ratings" on course_ratings for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Простейшие RPC для подсчётов
create or replace function inc_likes(cid uuid, delta int) returns void as $$
begin
  update courses set likes = greatest(0, likes + delta) where id = cid;
end; $$ language plpgsql security definer;

create or replace function inc_views(cid uuid) returns void as $$
begin
  update courses set views = views + 1 where id = cid;
end; $$ language plpgsql security definer;

create or replace function recalc_course_rating(cid uuid) returns void as $$
begin
  update courses c set rating = coalesce((select avg(rating) from course_ratings r where r.course_id = cid), 0)
  where c.id = cid;
end; $$ language plpgsql security definer;

-- Хранилища для файлов (создайте бакеты в Storage):
-- avatars (public), course-covers (public)
-- В полисах Storage включите public read, а write только для аутентифицированных.
```

### Пример вставки

```sql
insert into courses (title, description, author, price, image_url, views, likes, rating, category)
values
('Тестовый курс', 'Описание...', 'Автор Алексеевич', 1600, '', 120, 43, 4.2, 'Онлайн-курсы');
```

## Дальнейшие шаги

- Экран профиля со статистикой пользователя.
- Экран курса и уроков, прогресс и отзывы.
- Аутентификация Supabase (email+пароль или magic link).
- Фильтрация/сортировка и создание курсов из UI.
-- Разделы и уроки внутри разделов (новая структура)
create table if not exists course_sections (
  id uuid primary key default gen_random_uuid(),
  course_id uuid references courses(id) on delete cascade,
  title text not null,
  description text default '',
  order_index int not null default 0
);
alter table course_sections enable row level security;
create policy "Public read sections" on course_sections for select using (true);
create policy "Owners manage sections" on course_sections for all using (
  exists (select 1 from courses c where c.id = course_id and c.owner = auth.uid())
);

create table if not exists section_lessons (
  id uuid primary key default gen_random_uuid(),
  section_id uuid references course_sections(id) on delete cascade,
  title text not null,
  content text default '',
  order_index int not null default 0
);
alter table section_lessons enable row level security;
create policy "Public read section lessons" on section_lessons for select using (true);
create policy "Owners manage section lessons" on section_lessons for all using (
  exists (select 1 from course_sections s join courses c on c.id=s.course_id where s.id = section_id and c.owner = auth.uid())
);

-- Интерактивные задания
create table if not exists course_tasks (
  id uuid primary key default gen_random_uuid(),
  section_id uuid references course_sections(id) on delete cascade,
  type text not null check (type in ('multiple_choice','free_text','code')),
  question text not null,
  options jsonb,
  answer text,
  code_language text,
  code_template text,
  order_index int not null default 0
);
alter table course_tasks enable row level security;
create policy "Public read tasks" on course_tasks for select using (true);
create policy "Owners manage tasks" on course_tasks for all using (
  exists (select 1 from course_sections s join courses c on c.id=s.course_id where s.id = section_id and c.owner = auth.uid())
);

-- Ответы пользователей на задания
create table if not exists task_submissions (
  id uuid primary key default gen_random_uuid(),
  task_id uuid references course_tasks(id) on delete cascade,
  user_id uuid references auth.users on delete cascade,
  answer text,
  code text,
  is_correct boolean,
  created_at timestamp with time zone default now()
);
alter table task_submissions enable row level security;
create policy "Owner manage submissions" on task_submissions for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
