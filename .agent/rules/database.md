---
trigger: always_on
---

Here is the **Markdown file** based on your schema definitions:

````markdown
# Database Schema Overview for Khuwar→Urdu + Khuwar→Roman Chitrali Translation Platform

This document provides an overview of the database schema for the **Khuwar→Urdu + Khuwar→Roman Chitrali Translation Platform**. The schema includes tables for managing **admin users**, **translations**, **reviews**, **leaderboards**, and **user profiles**.

## Tables Overview

### 1. **admin_users**
Manages **admin users** for the platform.

```sql
CREATE TABLE public.admin_users (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT admin_users_pkey PRIMARY KEY (id),
  CONSTRAINT admin_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
````

* **id**: Unique identifier for the admin user.
* **user_id**: Links to the **users** table.
* **is_active**: Indicates whether the admin account is active.
* **created_at**: Timestamp for when the admin account was created.

---

### 2. **app_logs**

Stores **logs** related to user actions and system events.

```sql
CREATE TABLE public.app_logs (
  log_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  event_type character varying NOT NULL,
  event_details jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  level character varying DEFAULT 'info'::character varying,
  message text,
  metadata jsonb DEFAULT '{}'::jsonb,
  version character varying,
  CONSTRAINT app_logs_pkey PRIMARY KEY (log_id),
  CONSTRAINT app_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(user_id)
);
```

* **log_id**: Unique identifier for each log.
* **user_id**: Links to the **profiles** table.
* **event_type**: Type of event (e.g., login, translation submission).
* **event_details**: JSON data providing details about the event.
* **level**: Log level (e.g., `info`, `error`).
* **message**: Description of the event.
* **metadata**: Additional data related to the event.
* **created_at**: Timestamp of when the event occurred.

---

### 3. **leaderboard_daily**

Tracks the daily **activity** of users, including translations, points, and streaks.

```sql
CREATE TABLE public.leaderboard_daily (
  leaderboard_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  city character varying,
  university_id uuid,
  daily_translations integer DEFAULT 0,
  streak integer DEFAULT 0,
  last_active date DEFAULT CURRENT_DATE,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  total_points integer DEFAULT 0,
  total_translations integer DEFAULT 0,
  approved_translations integer DEFAULT 0,
  longest_streak integer DEFAULT 0,
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT leaderboard_daily_pkey PRIMARY KEY (leaderboard_id),
  CONSTRAINT leaderboard_daily_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(user_id),
  CONSTRAINT leaderboard_daily_university_id_fkey FOREIGN KEY (university_id) REFERENCES public.universities(id)
);
```

* **leaderboard_id**: Unique identifier for the leaderboard entry.
* **user_id**: Links to the **profiles** table.
* **city**: The user’s city.
* **university_id**: Links to the **universities** table.
* **daily_translations**: The number of translations submitted today.
* **streak**: The user's current streak of consecutive translations.
* **total_points**: The total points accumulated by the user.
* **total_translations**: The total number of translations submitted by the user.
* **approved_translations**: The number of translations that have been approved.
* **longest_streak**: The longest streak the user has had.
* **updated_at**: Timestamp of the last update to the leaderboard.

---

### 4. **profiles**

Stores **user profile** data, including their full name, email, city, university, and GPS coordinates.

```sql
CREATE TABLE public.profiles (
  user_id uuid NOT NULL,
  full_name character varying,
  email character varying UNIQUE,
  mobile_number character varying,
  university_id uuid,
  city character varying,
  gps_coordinates USER-DEFINED,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  is_student boolean DEFAULT true,
  avatar_url text,
  CONSTRAINT profiles_pkey PRIMARY KEY (user_id),
  CONSTRAINT profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT profiles_university_id_fkey FOREIGN KEY (university_id) REFERENCES public.universities(id)
);
```

* **user_id**: Unique identifier for the user.
* **full_name**: The full name of the user.
* **email**: The user's email address.
* **mobile_number**: The user's mobile number.
* **university_id**: Links to the **universities** table.
* **city**: The user’s city.
* **gps_coordinates**: The user’s geographic coordinates (custom user-defined type).
* **is_student**: Indicates whether the user is a student.
* **avatar_url**: URL for the user’s profile picture.

---

### 5. **review_tasks**

Manages the **review tasks** assigned to reviewers for translating sentences.

```sql
CREATE TABLE public.review_tasks (
  task_id uuid NOT NULL DEFAULT gen_random_uuid(),
  attempt_id uuid NOT NULL,
  reviewer_id uuid,
  assigned_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT review_tasks_pkey PRIMARY KEY (task_id),
  CONSTRAINT review_tasks_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.translation_attempts(attempt_id),
  CONSTRAINT review_tasks_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES public.profiles(user_id)
);
```

* **task_id**: Unique identifier for the review task.
* **attempt_id**: Links to the **translation_attempts** table.
* **reviewer_id**: Links to the **profiles** table for the assigned reviewer.
* **assigned_at**: Timestamp when the task was assigned.

---

### 6. **reviews**

Stores the **reviews** provided by reviewers for each translation attempt.

```sql
CREATE TABLE public.reviews (
  review_id uuid NOT NULL DEFAULT gen_random_uuid(),
  task_id uuid NOT NULL,
  rating integer CHECK (rating >= 1 AND rating <= 5),
  notes text,
  reviewed_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT reviews_pkey PRIMARY KEY (review_id),
  CONSTRAINT reviews_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.review_tasks(task_id)
);
```

* **review_id**: Unique identifier for the review.
* **task_id**: Links to the **review_tasks** table.
* **rating**: The rating given by the reviewer (1-5).
* **notes**: Optional comments by the reviewer.
* **reviewed_at**: Timestamp when the review was completed.

---

### 7. **sentences**

Stores the **original sentences** in Khuwar that need to be translated.

```sql
CREATE TABLE public.sentences (
  sentence_id uuid NOT NULL DEFAULT gen_random_uuid(),
  khuwar_text text NOT NULL,
  tags ARRAY,
  is_translated boolean DEFAULT false,
  assigned_to uuid,
  assigned_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT sentences_pkey PRIMARY KEY (sentence_id),
  CONSTRAINT sentences_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.profiles(user_id)
);
```

* **sentence_id**: Unique identifier for the sentence.
* **khuwar_text**: The original Khuwar text.
* **tags**: Tags for categorizing the sentence.
* **is_translated**: Indicates whether the sentence has been translated.
* **assigned_to**: Links to the **profiles** table for the assigned user.

---

### 8. **skipped_sentences**

Tracks **skipped translations** and the reasons behind them.

```sql
CREATE TABLE public.skipped_sentences (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  sentence_id uuid NOT NULL,
  skipped_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  reason text,
  CONSTRAINT skipped_sentences_pkey PRIMARY KEY (id),
  CONSTRAINT skipped_sentences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(user_id),
  CONSTRAINT skipped_sentences_sentence_id_fkey FOREIGN KEY (sentence_id) REFERENCES public.sentences(sentence_id)
);
```

* **id**: Unique identifier for the skipped sentence.
* **user_id**: Links to the **profiles** table for the user who skipped the sentence.
* **sentence_id**: Links to the **sentences** table for the skipped sentence.
* **skipped_at**: Timestamp when the sentence was skipped.

---

### 9. **spatial_ref_sys**

Stores information about **spatial reference systems**.

```sql
CREATE TABLE public.spatial_ref_sys (
  srid integer NOT NULL CHECK (srid > 0 AND srid <= 998999),
  auth_name character varying,
  auth_srid integer,
  srtext character varying,
  proj4text character varying,
  CONSTRAINT spatial_ref_sys_pkey PRIMARY KEY (srid)
);
```

* **srid**: Unique identifier for the spatial reference system.
* **auth_name**: The authority name for the spatial reference system.
* **srtext**: The textual representation of the spatial reference system.

---

### 10. **translation_attempts**

Tracks the **user translations** for each sentence.

```sql
CREATE TABLE public.translation_attempts (
  attempt_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  sentence_id uuid NOT NULL,
  urdu_translation text,
  roman_chitrali_translation text,
  timestamp timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  gps_coordinates USER-DEFINED,
  device_metadata jsonb,
  status character varying DEFAULT 'pending'::character varying CHECK (status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'reviewed'::character varying]::text[])),
  city character varying,
  CONSTRAINT translation_attempts_pkey PRIMARY KEY (attempt_id),
  CONSTRAINT translation_attempts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(user_id),
  CONSTRAINT translation_attempts_sentence_id_fkey FOREIGN KEY (sentence_id) REFERENCES public.sentences(sentence_id)
);
```

* **attempt_id**: Unique identifier for the translation attempt.
* **user_id**: Links to the **profiles** table.
* **sentence_id**: Links to the **sentences** table.
* **urdu_translation**: The user’s Urdu translation.
* **roman_chitrali_translation**: The user’s Roman Chitrali translation.

---

### 11. **universities**

Stores data on **universities** for user affiliation.

```sql
CREATE TABLE public.universities (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name character varying NOT NULL UNIQUE,
  CONSTRAINT universities_pkey PRIMARY KEY (id)
);
```

* **id**: Unique identifier for the university.
* **name**: The university's name.

---

This schema defines the core database structure for the **Khuwar→Urdu + Khuwar→Roman Chitrali Translation Platform**. It includes tables for user management, translation tracking, content moderation, leaderboard statistics, and spatial data integration.
