# Product Requirements Document
## Mirai Atelier Hub — Creative Team Task Management Platform

**Version:** 1.0  
**Platform Target:** Web Application (Mobile-responsive)  
**Backend:** Supabase (PostgreSQL + Auth + Storage + Realtime)

---

## 1. Product Overview

**Mirai Atelier Hub** is an internal task management and collaboration platform built for a creative production team. It enables admins to assign and monitor tasks, while team members (developers) can track their workload, submit completed work, receive feedback, earn points, and chat in real-time.

### Target Users
- **Admin** — Project manager / team lead who creates tasks, reviews submissions, and communicates with the team
- **Team Members (Users)** — Creative professionals who receive tasks, submit work, and earn points

### Core Value Proposition
Replaces disconnected tools (spreadsheets + chat apps) with a single platform that connects task assignment → submission → review → feedback → reward in one unified flow.

---

## 2. User Roles & Permissions

### 2.1 Admin
- Full CRUD on all tasks
- Access to all sections: Overview, User Control, Create Task, All Tasks, Review Queue, Chat, Kanban Board, Leaderboard
- Can approve or request revision on submitted tasks
- Can send direct messages to any team member
- Receives notifications when users submit tasks

### 2.2 Team Member (User)
- Can view and work on tasks assigned to them or their role
- Can mark tasks as Done (submit) with optional file attachment and note
- Can unsubmit (cancel) a Done task back to revision status
- Receives notifications when admin approves or requests revision
- Can chat with admin (DM) and reply in task threads
- Can view leaderboard and own profile/points

### 2.3 User Roles (sub-types within Team Member)
| Role | Label | Icon |
|------|-------|------|
| `produser` | Produser | 🎭 |
| `director` | Director | 🎬 |
| `modeller` | Modeller | 🎨 |
| `programmer` | Programmer | 💻 |
| `animator` | Animator | ✨ |
| `admin` | Admin | 👑 |

---

## 3. Database Schema

### `profiles`
```
id            uuid (FK → auth.users)
full_name     text
username      text
role          text (admin | produser | director | modeller | programmer | animator)
avatar_url    text (nullable)
points        integer DEFAULT 0
is_active     boolean DEFAULT true
created_at    timestamptz
```

### `tasks`
```
id            uuid PK
title         text NOT NULL
description   text
status        text (ongoing | on_review | processed | revision)
priority      text (low | medium | high | urgent)
assigned_to   uuid (nullable, FK → profiles) — individual assignment
role_target   text (nullable) — assign to an entire role group or 'all'
due_date      timestamptz (nullable)
points_reward integer DEFAULT 10
created_by    uuid FK → profiles
created_at    timestamptz
updated_at    timestamptz
```

### `task_submissions`
```
id            uuid PK
task_id       uuid FK → tasks
submitted_by  uuid FK → profiles
file_url      text (nullable, Supabase Storage path)
file_name     text (nullable)
note          text (nullable)
submitted_at  timestamptz DEFAULT now()
```

### `notifications`
```
id            uuid PK
recipient_id  uuid FK → profiles
sender_id     uuid (nullable, FK → profiles)
type          text (task_submitted | task_unsubmitted | task_approved | task_revision | task_message)
task_id       uuid (nullable, FK → tasks)
title         text NOT NULL
message       text
is_read       boolean DEFAULT false
created_at    timestamptz
```

### `messages`
```
id            uuid PK
sender_id     uuid FK → profiles
recipient_id  uuid (nullable, FK → profiles) — set for DMs
task_id       uuid (nullable, FK → tasks) — set for task threads
content       text NOT NULL
is_read       boolean DEFAULT false
created_at    timestamptz
CHECK (recipient_id IS NOT NULL OR task_id IS NOT NULL)
```

### Database Automation
- **Trigger `award_task_points`**: fires on tasks UPDATE, when status changes to `processed` → adds `points_reward` to `profiles.points` for the assigned user

---

## 4. Task Status Flow

```
[Created] → ongoing
               ↓  (User clicks "✅ Done")
            on_review
               ↓                    ↓
          (Admin Approve)    (Admin Request Revision)
               ↓                    ↓
           processed              revision
               ↓                    ↓
        (end / can still     (User re-submits)
         request revision)     → on_review
```

- `processed` tasks can still be sent back to `revision` by admin
- User can "unsubmit" an `on_review` task (returns to `revision`)

---

## 5. Feature Specifications

---

### 5.1 Authentication
**Pages:** Login, Register (optional: handled by Supabase Auth)

- Email + password login
- Session persistence (auto-redirect based on role)
- After login: if role = `admin` → redirect to `admin.html`; else → redirect to `dashboard.html`
- Logout button in all sidebars

---

### 5.2 Admin Dashboard

#### 5.2.1 Overview Section
- **4 stat cards:** Total Developers, Total Tasks, On Going tasks, Processed tasks
- **3 featured action cards:** On Going (→ All Tasks), On Review (→ Review Queue), Processed (→ All Tasks)
- **Review Banner:** Highlighted alert strip shown when there are `on_review` tasks — "Ada X task menunggu review! →"
- **Activity Feed:** 10 most recent task updates in a scrollable list (task name, assigned user, time ago)
- **Upcoming Due tasks:** Tasks due in the next 7 days

#### 5.2.2 User Control Section
- Table listing all non-admin users
- Columns: Avatar, Full Name, Role badge, Points, Status (active/inactive)
- Search by name or username
- Click a user to see their task summary

#### 5.2.3 Create Task Section
Form fields:
- Title (required)
- Description (textarea)
- Assign To: dropdown of active users OR leave blank
- Role Target: dropdown (Produser / Director / Modeller / Programmer / Animator / All Team / None)
- Due Date (date picker)
- Priority (Low / Medium / High / Urgent) — color coded
- Points Reward (number, default 10)

On submit: creates task with status `ongoing`, notifies assigned user.

#### 5.2.4 All Tasks Section
- Full task table with columns: Title, Assigned To / Role, Status badge, Priority badge, Due Date, Points, Actions
- Filter by: status, role_target, priority, search query
- Row actions: ✏️ Edit (opens modal), 🗑️ Delete (confirm), 🔄 Revision (opens revision modal for processed tasks)
- Edit modal: change any field + change status
- When status changes to `processed` or `revision` via edit → send notification to user with points info (if processed)

#### 5.2.5 Review Queue Section
- Shows **ALL tasks** (not just on_review) — permanent list, cards never disappear
- Cards sorted by updated_at DESC
- Each card shows:
  - Task title, assigned user avatar + name + role badge
  - Priority badge, due date
  - Status badge (color-coded)
  - Latest submission preview: submitter name, time ago, note, file (image preview or download link), submission count
- Per-status action buttons:
  - `on_review`: **✅ Setujui** + **🔄 Revisi**
  - `processed`: **🔄 Revisi** (amber style)
  - Other statuses: no action buttons
- **💬 Thread** button on every card → toggles inline task thread chat
- Inline revision form (textarea + send) — hidden by default, toggled by Revisi button
- Approve action: status → `processed`, sends "🎉 Hore!" notification with points to user
- Revision action: status → `revision`, sends notification + auto-posts revision note to task thread
- Review Queue badge on sidebar: count of `on_review` tasks

#### 5.2.6 Kanban Board Section
- 4 columns: On Going | On Review | Processed | Revision
- Task cards draggable between columns
- Card shows: title, assigned user, priority, due date, points
- On drop to `processed` or `revision`: notify assigned user
- Overdue tasks highlighted in red

#### 5.2.7 Leaderboard Section
- Ranked list of all users by points (highest first)
- Shows: rank number, avatar, full name, role badge, points
- Top 3 highlighted with gold/silver/bronze styling

---

### 5.3 User Dashboard

#### 5.3.1 Home Section
- Greeting: "Halo, [Name] 👋"
- Progress bar: completed tasks / total tasks
- Date display
- 3 featured stat cards: On Going, On Review, Completed
- Tabbed task list: All | On Going | On Review | Completed | Revision
- Each task card shows: title, description preview, priority, due date, status, points reward
- Click task card → opens Task Detail Modal

#### 5.3.2 Task Detail Modal
- Full task info: title, description, priority, due date, points reward, status, role target
- Action buttons change based on status:
  - `ongoing` or `revision`: **✅ Done** button + **📎 + File** (submit with file)
  - `on_review`: "Menunggu review admin..." label + **↩ Batalkan** (unsubmit)
  - `processed`: "Task selesai ✅" label
- Clicking Done: triggers confetti particle animation + marks task `on_review` + notifies admin

#### 5.3.3 Quick Submit Panel (Submit Section)
- Dropdown to select a task (only ongoing/revision tasks)
- Note textarea
- File upload (image, video, pdf, zip, etc.)
- Submit button → submits with file stored in Supabase Storage

#### 5.3.4 Kanban Board (User view)
- Same 4-column kanban as admin but read-only (no drag)
- Shows only tasks assigned to the user

#### 5.3.5 Leaderboard Section
- Same as admin leaderboard view

#### 5.3.6 Profile Section
- Shows user avatar, name, role, total points
- Stats: tasks completed, tasks in progress

---

### 5.4 Notification System

#### Notification Bell (both Admin & User)
- Bell icon button in header/sidebar
- Red badge showing unread count (updated every 30 seconds)
- Badge turns gold/colored when unread > 0
- Click bell → slide-in notification panel from right (340px wide)
- "Mark all read" button in panel header

#### Notification Types & Display
| Type | Who receives | Title | Special UI |
|------|-------------|-------|------------|
| `task_submitted` | Admin | "✅ Task Done" | Quick action buttons: ✅ Setujui + 🔄 Revisi |
| `task_unsubmitted` | Admin | "↩ Task Unsubmit" | Quick action buttons |
| `task_approved` | User | "🎉 Hore! Task kamu selesai!" | Teal celebration style |
| `task_revision` | User | "🔄 Task Perlu Revisi" | "💬 Balas" button → opens task thread |
| `task_message` | Admin or User | "💬 Pesan baru" | "💬 Balas" button → opens task thread |

- Clicking a notification marks it as read
- Clicking `task_approved` notification → triggers confetti particle animation
- Clicking `task_revision` / `task_message` → opens chat panel on that task's thread

#### Confetti Particle Animation
- 160 colorful particles (rectangles, circles, ribbons)
- Colors: gold, purple, teal, pink, amber, red, white
- Physics: gravity + fade-out over ~220 frames (~3.6 seconds)
- Canvas overlay, pointer-events: none (non-blocking)
- Triggers on: Done button click + task_approved notification click

---

### 5.5 Real-time Chat System

#### Admin Chat Section
- Dedicated **Chat** page accessible from sidebar (💬 icon)
- Left panel: list of all team members with unread DM count badge
- Right panel: chat thread with selected user
- Real-time via Supabase Realtime (postgres_changes INSERT subscription)
- Enter to send, Shift+Enter for new line
- Auto-scroll to latest message
- Chat unread badge on sidebar button (polling every 30s)

#### Task Thread (inline in Review Queue)
- Every Review Queue card has a **💬** toggle button
- Opens inline collapsible thread section below the card
- Shows all messages related to that task (from `messages` table with `task_id`)
- Admin can type and send messages to the thread
- Sending a thread message also notifies the assigned user (`task_message` notification)
- When admin sends revision, the revision note is auto-posted to the task thread

#### User Chat Panel (Dashboard)
- Chat button (💬) in sidebar bottom next to notifications bell
- Slide-in panel (same style as notification panel)
- **Conversation list view** shows:
  - "Chat dengan Admin" (DM) with unread count badge
  - All task threads the user is involved in
- Click conversation → switches to **Thread view** with messages + input
- Back button returns to conversation list
- Real-time via Supabase Realtime subscription

#### Message Bubble Design
- **Mine (sender):** Purple background, right-aligned, rounded top-left-bottom
- **Theirs (received):** Dark card background, left-aligned with avatar initials, rounded top-right-bottom
- Timestamp below each bubble (relative time: "2 menit lalu")

---

### 5.6 Points System
- Each task has a `points_reward` value (set by admin, default 10)
- Points are automatically awarded when task status changes to `processed` via database trigger
- Points visible on: user profile, leaderboard, task cards, notifications
- Leaderboard sorts users by total points descending

---

## 6. UI/UX Design Specifications

### Color Palette (Dark Theme)
```
Background:   #0e1116
Surface:      #161b22
Card:         #1c2130
Card Alt:     #212840
Border:       #2a3040
Border Alt:   #353f55
Gold Accent:  #e8b84b
Purple:       #7c6fff
Teal:         #3dd9ad
Pink:         #ff6584
Amber:        #fbbf24
Red:          #f87171
Text Primary: #f0f4ff
Text Muted:   #7a8aaa
Text Faint:   #3a4560
```

### Layout
- **Admin:** Fixed icon-only sidebar (48px) + scrollable main content area
- **User Dashboard:** Fixed icon-only sidebar (54px) + main content + optional right panel
- Font: Inter (300, 400, 500, 600, 700, 800)
- Border radius: 8px (small), 14px (standard), 18px (large)
- Transitions: 0.18s ease

### Status Color Coding
| Status | Color |
|--------|-------|
| ongoing | Purple |
| on_review | Amber |
| processed | Teal |
| revision | Pink/Red |

### Priority Color Coding
| Priority | Color |
|----------|-------|
| low | Muted gray |
| medium | Amber |
| high | Orange |
| urgent | Red |

### Component Library
- **Buttons:** btn-primary (gold), btn-secondary (dark), btn-danger (red), btn-ghost (transparent), btn-sm
- **Badges:** Colored pill labels for status, priority, role
- **Modals:** Centered overlay with dark backdrop, close X button
- **Toast notifications:** Bottom-right, 3 types: success (teal), warning (amber), error (red)
- **Spinner:** CSS animation loading indicator
- **Empty state:** Centered emoji + text for empty lists

---

## 7. Key User Flows

### Flow 1: Task Submission (User)
1. User opens dashboard → sees task in "On Going" tab
2. Clicks task card → Task Detail Modal opens
3. Clicks "✅ Done" → Confetti fires + task status → `on_review`
4. Admin receives notification in bell panel + Review Queue badge updates
5. Admin clicks notification OR navigates to Review Queue
6. Admin sees submission preview (file/note if uploaded via Quick Submit)
7. Admin clicks "✅ Setujui" → task status → `processed`
8. User receives "🎉 Hore! Kamu mendapatkan X poin 🎊" notification
9. User clicks notification → Confetti fires again
10. Points auto-credited to user's profile via DB trigger

### Flow 2: Revision Feedback with Thread Reply
1. Admin sends revision from Review Queue (writes note + clicks "🔄 Kirim Revisi")
2. Task status → `revision`
3. Revision note auto-posted to task thread (messages table)
4. User receives "🔄 Task Perlu Revisi" notification with "💬 Balas" button
5. User clicks "💬 Balas" → Chat panel opens on task thread
6. User reads revision note, types reply, sends
7. Admin sees reply badge on chat button
8. Admin opens Review Queue → clicks 💬 on task card → sees thread inline
9. Admin and user continue real-time conversation in thread
10. User revises work, clicks "✅ Done" again → cycle repeats

### Flow 3: Admin ↔ User Direct Message
1. Admin navigates to Chat section
2. Sees list of team members
3. Clicks a user → DM thread opens
4. Types message → Enter to send
5. User sees chat badge (💬) in dashboard sidebar
6. User clicks 💬 → Chat panel opens showing "Chat dengan Admin"
7. Real-time messages appear without page refresh

---

## 8. Technical Requirements

### Frontend
- Vanilla HTML/CSS/JavaScript (no framework required, but React/Vue acceptable)
- Supabase JS SDK v2 (`@supabase/supabase-js`)
- Supabase Realtime for live chat (postgres_changes subscriptions)
- Canvas API for confetti animation
- No external UI library required (custom component system)

### Backend (Supabase)
- **Auth:** Supabase Auth (email/password)
- **Database:** PostgreSQL via Supabase
- **Storage:** Supabase Storage bucket (`task-files`) for submission uploads
- **Realtime:** Enabled on `messages` table (`ALTER PUBLICATION supabase_realtime ADD TABLE messages`)
- **Row Level Security (RLS):** Enabled on all tables

### RLS Policy Summary
| Table | Policy |
|-------|--------|
| profiles | Read: authenticated; Update: own row |
| tasks | Select: assigned user or role match or admin; Update: admin or assigned user or role match; Insert/Delete: admin only |
| task_submissions | Select: admin or submitted_by = user; Insert: authenticated |
| notifications | Select: recipient = user; Insert: sender = user; Update: recipient = user |
| messages | Select: sender/recipient = user OR task assigned to user OR admin; Insert: sender = user; Update: recipient/admin |

### Database Trigger
```sql
CREATE OR REPLACE FUNCTION award_task_points()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.status = 'processed' AND OLD.status <> 'processed' AND NEW.assigned_to IS NOT NULL THEN
    UPDATE profiles SET points = points + COALESCE(NEW.points_reward, 10)
    WHERE id = NEW.assigned_to;
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER trg_award_points AFTER UPDATE ON tasks
FOR EACH ROW EXECUTE FUNCTION award_task_points();
```

---

## 9. Non-Functional Requirements

- **Performance:** Dashboard loads in < 2 seconds; notification polling every 30 seconds
- **Real-time:** Chat messages appear within 1 second via Supabase Realtime
- **Security:** All DB access through RLS policies; no client-side privilege escalation
- **Responsive:** Mobile-friendly layout (sidebar collapses on small screens)
- **Accessibility:** Keyboard navigation supported; ARIA labels on interactive elements

---

## 10. Out of Scope (v1.0)

- Push notifications (browser/mobile)
- Email notifications
- Task comments outside the chat thread system
- File versioning / submission diff
- Calendar view
- Time tracking
- Multi-project / workspace support

---

## 11. Glossary

| Term | Meaning |
|------|---------|
| Done | User action to submit a completed task for admin review |
| on_review | Task status after user marks it Done, awaiting admin action |
| processed | Task approved by admin; points awarded |
| revision | Task sent back by admin for rework |
| Thread | Task-specific chat conversation visible to admin + assigned user |
| DM | Direct Message between admin and a specific user |
| role_target | Task assigned to all users of a specific role (or all roles) |
| points_reward | Points the user earns when this task is approved |
