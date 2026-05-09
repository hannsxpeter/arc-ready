# File Management & Uploads

File uploads are one of the highest-friction interactions in any SaaS product. A drag-and-drop zone that doesn't respond, a progress bar that lies, a failed upload with no retry — any of these kills user trust. This file covers every surface from the drop zone to the file manager, with specific measurements and implementation patterns.

See `migration-and-data-import.md` for CSV import pipelines (column mapping, validation, the four-stage import flow). This file covers the upload UX layer — the drop zone, progress indicators, previews, and file management that wraps around any import flow.

---

## Upload UX patterns

### Drag-and-drop zones

The drop zone is the primary upload surface. It must support three input methods: drag-and-drop, click-to-browse, and paste from clipboard.

**Drop zone specs:**

```
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
│                                           │
│    [Upload cloud icon — 40px]             │
│                                           │
│    Drag files here, or browse             │
│                                           │
│    PNG, JPG, PDF — up to 10MB each        │
│                                           │
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
```

- **Minimum size:** 200px wide x 150px tall. Larger is better — 100% width of the container for full-width zones.
- **Border:** 2px dashed, `border-muted-foreground/30` at rest. Don't use a solid border — the dashed pattern is a universal visual signal for "drop here."
- **Border radius:** 8–12px (match your design system's `rounded-lg`)
- **Background:** transparent or `bg-muted/30` at rest
- **Icon:** upload/cloud icon, 40px, centered above the text, muted color
- **Primary text:** "Drag files here, or browse" — 14px, medium weight. "Browse" is a clickable link (underlined or primary color).
- **Secondary text:** accepted formats and size limit — 12px, muted. Be specific: "PNG, JPG, PDF — up to 10MB each" not "Upload files."
- **Padding:** 32px all sides minimum

**Drop zone states:**

| State | Visual change | Trigger |
|---|---|---|
| **Rest** | Dashed border, muted bg | Default |
| **Hover** (mouse over browse link) | Link underline, cursor pointer | Mouse enters the text link |
| **Drag over** | Border becomes solid + primary color, bg becomes `primary/5`, icon animates (subtle scale to 1.05) | File is dragged over the zone (`dragenter`) |
| **Drag over invalid** | Border becomes solid + destructive, bg becomes `destructive/5` | Dragged file type doesn't match `accept` |
| **Uploading** | Progress bar replaces drop zone content, or appears below it | File dropped or selected |
| **Error** | Red border, error message below the zone | Upload failed |
| **Disabled** | Reduced opacity (50%), no pointer events | Upload not allowed (quota reached, etc.) |

```typescript
// Drop zone with all three input methods
function DropZone({ accept, maxSize, onFiles }: DropZoneProps) {
  const [isDragOver, setDragOver] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const handleDrop = (e: DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    const files = Array.from(e.dataTransfer.files);
    validateAndSubmit(files);
  };

  const handlePaste = (e: ClipboardEvent) => {
    const files = Array.from(e.clipboardData.items)
      .filter((item) => item.kind === 'file')
      .map((item) => item.getAsFile()!)
      .filter(Boolean);
    if (files.length) validateAndSubmit(files);
  };

  // Listen for paste events on the document
  useEffect(() => {
    document.addEventListener('paste', handlePaste);
    return () => document.removeEventListener('paste', handlePaste);
  }, []);

  return (
    <div
      onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
      onDragLeave={() => setDragOver(false)}
      onDrop={handleDrop}
      onClick={() => inputRef.current?.click()}
      className={cn(
        'min-h-[150px] border-2 border-dashed rounded-lg p-8',
        'flex flex-col items-center justify-center gap-2 cursor-pointer',
        'transition-colors duration-150',
        isDragOver
          ? 'border-primary bg-primary/5'
          : 'border-muted-foreground/30 hover:border-muted-foreground/50'
      )}
    >
      <Upload className="h-10 w-10 text-muted-foreground" />
      <p className="text-sm font-medium">
        Drag files here, or <span className="text-primary underline">browse</span>
      </p>
      <p className="text-xs text-muted-foreground">
        {formatAcceptTypes(accept)} — up to {formatBytes(maxSize)} each
      </p>
      <input
        ref={inputRef}
        type="file"
        accept={accept}
        multiple
        className="sr-only"
        onChange={(e) => validateAndSubmit(Array.from(e.target.files ?? []))}
      />
    </div>
  );
}
```

### File type filtering

Always filter on both the `accept` attribute and client-side validation. The `accept` attribute controls the file picker dialog; client-side validation catches drag-and-drop.

```typescript
const FILE_TYPES = {
  images: {
    accept: 'image/png, image/jpeg, image/webp, image/gif',
    extensions: ['.png', '.jpg', '.jpeg', '.webp', '.gif'],
    label: 'PNG, JPG, WebP, or GIF',
  },
  documents: {
    accept: 'application/pdf, .doc, .docx',
    extensions: ['.pdf', '.doc', '.docx'],
    label: 'PDF, DOC, or DOCX',
  },
  spreadsheets: {
    accept: '.csv, .xlsx, application/json',
    extensions: ['.csv', '.xlsx', '.json'],
    label: 'CSV, XLSX, or JSON',
  },
};
```

**When the user drops an invalid file type:** don't silently ignore it. Show an inline error below the drop zone: "invoice.exe is not a supported file type. Accepted: PNG, JPG, PDF." Auto-dismiss after 5 seconds or on the next valid drop.

### Size limits

Standard limits by context:

| Context | Max single file | Max total per upload | Max total per account |
|---|---|---|---|
| Avatar/profile photo | 5MB | 5MB | N/A |
| Document attachment | 25MB | 100MB | Plan-dependent |
| Image upload (general) | 10MB | 50MB | Plan-dependent |
| CSV/data import | 100MB | 100MB | N/A |
| Video upload | 500MB–2GB | Plan-dependent | Plan-dependent |

**Show the limit in the drop zone UI.** Show it again as a validation error when exceeded: "logo.png is 12MB. Maximum file size is 10MB."

### Multiple file selection

- Allow `multiple` on the file input by default unless the context demands a single file (avatar upload)
- Show selected files as a list below the drop zone before upload starts
- Each file in the list shows: file name (truncated with ellipsis at 40 chars), file size, a remove button (X icon)
- The upload button is separate from the drop zone — don't auto-upload on drop unless the UX explicitly calls for it (avatar uploads can auto-upload)

---

## Upload progress

### Progress bar implementation

For files under 5MB on a fast connection, the upload finishes so quickly that a progress bar is unnecessary — show a spinner or brief loading state. For anything larger, show a determinate progress bar.

**Progress bar specs:**
- Height: 8px (4px for compact/inline)
- Border radius: full (pill-shaped)
- Background: `bg-muted`
- Fill: `bg-primary` during upload, `bg-green-500` on success, `bg-destructive` on failure
- Animation: smooth `transition-all duration-300` on width changes

**Per-file progress UI:**

```
┌──────────────────────────────────────────────┐
│  📄 quarterly-report.pdf          [✕]       │
│  ████████████████░░░░░░░░░  64%  2.1MB/3.3MB│
│  Estimated: 8 seconds remaining              │
├──────────────────────────────────────────────┤
│  🖼️ hero-image.png                [✕]       │
│  ██████████████████████████████  100%  ✓     │
├──────────────────────────────────────────────┤
│  📄 invoice.pdf                   [✕]       │
│  ████░░░░░░░░░░░░░░░░░░░░  12%  0.4MB/3.1MB│
│  Estimated: 24 seconds remaining             │
└──────────────────────────────────────────────┘
```

**What to show per file:**
- File type icon (or thumbnail for images)
- File name (truncated at 40 characters with ellipsis)
- Progress bar
- Percentage
- Bytes uploaded / total bytes (e.g., "2.1MB / 3.3MB")
- Estimated time remaining (calculate from average speed of last 3 seconds, update every 2 seconds — don't update every tick or it jitters)
- Cancel button (X) — available during upload
- Retry button — on failure, replaces the cancel button

### Chunked uploads for large files

Files over 10MB should use chunked uploads. This enables:
- **Resume on failure** — only re-upload the failed chunk, not the whole file
- **Real progress** — progress is per-chunk, not per-request
- **Timeout prevention** — individual chunks complete in seconds, not minutes

**Chunk size:** 5MB is the standard. Smaller chunks (1–2MB) for mobile/slow connections, larger (10MB) for guaranteed fast connections.

**The TUS protocol** is the industry standard for resumable uploads. Use `tus-js-client` in the browser with a TUS server (tusd, or built into Supabase, Cloudflare, Transloadit).

```typescript
import * as tus from 'tus-js-client';

function uploadWithTus(file: File, onProgress: (pct: number) => void) {
  return new Promise<string>((resolve, reject) => {
    const upload = new tus.Upload(file, {
      endpoint: '/api/uploads',
      retryDelays: [0, 1000, 3000, 5000],
      chunkSize: 5 * 1024 * 1024, // 5MB
      metadata: {
        filename: file.name,
        filetype: file.type,
      },
      onProgress: (bytesUploaded, bytesTotal) => {
        onProgress((bytesUploaded / bytesTotal) * 100);
      },
      onSuccess: () => resolve(upload.url!),
      onError: (error) => reject(error),
    });
    upload.start();
  });
}
```

**If TUS is too heavy,** implement manual chunking:

```typescript
async function uploadChunked(
  file: File,
  onProgress: (pct: number) => void,
  signal?: AbortSignal
) {
  const CHUNK_SIZE = 5 * 1024 * 1024;
  const totalChunks = Math.ceil(file.size / CHUNK_SIZE);
  const uploadId = await initiateUpload(file.name, file.size, file.type);

  for (let i = 0; i < totalChunks; i++) {
    if (signal?.aborted) throw new DOMException('Upload cancelled', 'AbortError');

    const start = i * CHUNK_SIZE;
    const chunk = file.slice(start, start + CHUNK_SIZE);

    await uploadChunk(uploadId, i, chunk, {
      retries: 3,
      backoff: [1000, 2000, 4000],
    });

    onProgress(((i + 1) / totalChunks) * 100);
  }

  return finalizeUpload(uploadId);
}
```

### Background uploads

When the user navigates away from the upload page, the upload should continue. This is critical for large files.

**Implementation approaches:**
1. **Upload in a shared context** (React context, Zustand/Jotai store, or a singleton service) that lives above the router — not inside the page component. The upload state persists across route changes.
2. **Show a global upload indicator** in the header or a floating widget: "Uploading 2 files..." with a mini progress bar. Clicking it expands to show per-file progress.
3. **Use the `beforeunload` event** to warn if the user tries to close the tab during upload: "Files are still uploading. Leave anyway?"

```typescript
// Global upload manager — lives outside of route components
const uploadStore = create<UploadStore>((set, get) => ({
  uploads: new Map<string, UploadState>(),
  
  addUpload: (file: File) => {
    const id = crypto.randomUUID();
    set((state) => ({
      uploads: new Map(state.uploads).set(id, {
        file,
        progress: 0,
        status: 'uploading',
      }),
    }));
    startUpload(id, file); // runs in background
    return id;
  },

  cancelUpload: (id: string) => {
    abortControllers.get(id)?.abort();
    set((state) => {
      const uploads = new Map(state.uploads);
      uploads.delete(id);
      return { uploads };
    });
  },
}));
```

### Retry on failure

- On chunk failure: auto-retry up to 3 times with exponential backoff (1s, 2s, 4s)
- On persistent failure: stop the upload, show the file in an "error" state with a "Retry" button
- On retry: resume from the last successful chunk, don't restart from the beginning
- **Never silently drop a failed upload.** The user must know it failed.

---

## Image handling

### Preview thumbnails

Show a thumbnail preview immediately after the user selects a file — before the upload even starts. Generate it client-side using `URL.createObjectURL()` or the Canvas API.

```typescript
function createThumbnail(file: File, maxSize = 200): Promise<string> {
  return new Promise((resolve) => {
    const img = new Image();
    img.onload = () => {
      const canvas = document.createElement('canvas');
      const scale = Math.min(maxSize / img.width, maxSize / img.height);
      canvas.width = img.width * scale;
      canvas.height = img.height * scale;

      const ctx = canvas.getContext('2d')!;
      ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
      resolve(canvas.toDataURL('image/jpeg', 0.7));

      URL.revokeObjectURL(img.src); // clean up
    };
    img.src = URL.createObjectURL(file);
  });
}
```

**Thumbnail specs:**
- Size: 80x80px (inline/list), 120x120px (grid), 200x200px (detail)
- Object-fit: `cover` for square thumbnails, `contain` for maintaining aspect ratio
- Border radius: 4–8px
- Background: `bg-muted` (visible while loading or for transparent images)
- Show a loading shimmer until the thumbnail generates (typically < 100ms for local files)

### Image cropping UI

For profile photos, cover images, and other constrained formats, provide a crop UI before upload.

**Crop UI components:**
- **Crop area:** a draggable, resizable rectangle overlaid on the image
- **Outside area:** darkened to 40% opacity
- **Drag handles:** 8px squares at corners (and optionally at midpoints) for resizing
- **Aspect ratio presets:** buttons for common ratios — 1:1 (square), 16:9 (cover), 4:3 (photo). Show which is selected.
- **Free crop:** optional, for when no ratio is required
- **Zoom slider:** 0.5x to 3x range, logarithmic scale, step 0.1
- **Preview:** show the cropped result at the target dimensions next to the crop area

```typescript
// Using react-image-crop (or react-easy-crop)
import ReactCrop, { type Crop } from 'react-image-crop';

function ImageCropper({ src, aspect, onCrop }: CropperProps) {
  const [crop, setCrop] = useState<Crop>({
    unit: '%',
    width: 80,
    aspect,
  });

  return (
    <div className="flex gap-6">
      <div className="flex-1">
        <ReactCrop crop={crop} onChange={setCrop} aspect={aspect}>
          <img src={src} alt="Crop preview" className="max-h-[400px]" />
        </ReactCrop>
      </div>
      <div className="w-48">
        <p className="text-xs text-muted-foreground mb-2">Preview</p>
        <CropPreview src={src} crop={crop} className="rounded-lg" />
      </div>
    </div>
  );
}
```

### Client-side compression

Compress images before upload to reduce upload time and storage costs. Do this transparently — the user doesn't need to know.

**Compression rules:**
- **Target:** reduce JPEG quality to 80–85% (visually indistinguishable for photos)
- **Max dimensions:** resize to 2048px on the longest side for general uploads, 512px for avatars, 1920px for cover images
- **Format conversion:** convert PNG screenshots to JPEG if they have no transparency (much smaller). Convert to WebP if the backend supports it.
- **Skip compression** for files already under 200KB — the savings aren't worth the processing time.

```typescript
async function compressImage(
  file: File,
  { maxWidth = 2048, quality = 0.82 } = {}
): Promise<Blob> {
  // Skip small files
  if (file.size < 200 * 1024) return file;

  const bitmap = await createImageBitmap(file);
  const scale = Math.min(1, maxWidth / Math.max(bitmap.width, bitmap.height));
  const width = Math.round(bitmap.width * scale);
  const height = Math.round(bitmap.height * scale);

  const canvas = new OffscreenCanvas(width, height);
  const ctx = canvas.getContext('2d')!;
  ctx.drawImage(bitmap, 0, 0, width, height);

  return canvas.convertToBlob({ type: 'image/jpeg', quality });
}
```

### EXIF data handling

Photos from cameras and phones contain EXIF metadata: GPS coordinates, device model, timestamps, camera settings. **Strip EXIF data before upload** for privacy. The exception is orientation data — apply it to the canvas rotation, then strip.

- **GPS data:** always strip. Never store user location metadata from uploaded photos.
- **Orientation:** read, apply to canvas, then strip. Without this, photos from phones display rotated.
- **Timestamp:** strip from the file, but you can store the upload timestamp server-side.
- **Camera model/settings:** strip for privacy.

Use `exif-js` or `piexifjs` to read, then strip by re-encoding through Canvas (which naturally drops EXIF).

---

## File previews

### When to use which preview method

| File type | Preview method | Notes |
|---|---|---|
| Images (JPG, PNG, WebP, GIF, SVG) | `<img>` tag, native | Direct src, lazy load for lists |
| PDF | Embedded viewer or `<iframe>` | `react-pdf` for custom viewer, `<object>` for simple embed |
| Video (MP4, WebM) | `<video>` tag, native | Show poster frame, controls, max 100MB for in-app preview |
| Audio (MP3, WAV, OGG) | `<audio>` tag, native | Waveform visualization optional, always show duration |
| Office docs (DOCX, XLSX, PPTX) | Microsoft Office Online viewer or Google Docs Viewer | Use `https://view.officeapps.live.com/op/embed.aspx?src={url}` |
| Text/code (TXT, JSON, MD, CSV) | Syntax-highlighted code block | Use Monaco editor (read-only) or Prism.js |
| All other types | File type icon + metadata | No preview — show icon, filename, size, download button |

### Preview placement: modal vs inline vs new tab

- **Modal (lightbox):** best for images and short documents. User stays on the current page. Close with Escape or click outside. Navigate between files with arrow keys. Common for galleries and attachment lists.
- **Inline:** best for small previews within a file list — thumbnail + expand on hover or click. Good for image-heavy contexts.
- **New tab / dedicated page:** best for long documents (PDFs, spreadsheets) that need full viewport. Open with middle-click or Ctrl+click for power users.

**Default behavior by type:**
- Images: modal (lightbox with arrow-key navigation)
- PDFs: modal for < 5 pages, new tab for longer documents
- Videos: modal with playback controls
- Everything else: download

### File type icons

For non-previewable files, show a recognizable icon per file type:

```typescript
const FILE_TYPE_ICONS: Record<string, { icon: LucideIcon; color: string }> = {
  pdf:  { icon: FileText, color: 'text-red-500' },
  doc:  { icon: FileText, color: 'text-blue-500' },
  docx: { icon: FileText, color: 'text-blue-500' },
  xls:  { icon: FileSpreadsheet, color: 'text-green-600' },
  xlsx: { icon: FileSpreadsheet, color: 'text-green-600' },
  csv:  { icon: FileSpreadsheet, color: 'text-green-600' },
  ppt:  { icon: Presentation, color: 'text-orange-500' },
  pptx: { icon: Presentation, color: 'text-orange-500' },
  zip:  { icon: FileArchive, color: 'text-amber-600' },
  mp4:  { icon: FileVideo, color: 'text-purple-500' },
  mp3:  { icon: FileAudio, color: 'text-pink-500' },
  json: { icon: FileCode, color: 'text-yellow-500' },
  // ... fallback
  default: { icon: File, color: 'text-muted-foreground' },
};
```

Icon size: 24px in lists, 40px in detail views, 64px in empty-state file representations.

---

## File management UI

### Table view vs grid view

Offer both. Table view is the default for document-heavy products (Google Drive, Dropbox). Grid view is the default for image-heavy products (design tools, media libraries). Let the user toggle.

**Table view columns:**

| Column | Width | Sortable | Notes |
|---|---|---|---|
| Checkbox | 40px fixed | No | Bulk selection |
| Icon/thumbnail | 40px fixed | No | File type icon or 40x40 thumbnail |
| Name | flex (fill remaining) | Yes (A-Z) | Truncate with ellipsis, tooltip for full name |
| Size | 100px | Yes (numeric) | Format: KB/MB/GB |
| Type | 100px | Yes (A-Z) | File extension or human-readable type |
| Modified | 160px | Yes (date, default desc) | Relative time < 7 days, absolute after |
| Actions | 80px fixed | No | Download, delete, more menu (three dots) |

**Grid view cards:**

```
┌────────────────────┐
│                    │
│   [Thumbnail]      │   Thumbnail: 100% width, aspect 4:3 or 1:1
│   160x120px        │   Object-fit: cover
│                    │
├────────────────────┤
│ report-q1.pdf      │   Filename: 14px, truncated, 1 line
│ 2.4 MB · Apr 10    │   Meta: 12px, muted
└────────────────────┘
```

- Card width: 180–220px, responsive grid with `auto-fill, minmax(180px, 1fr)`
- Gap: 16px
- Border radius: 8px
- Hover: subtle shadow or border highlight, show quick-action overlay (download, delete)
- Selected: primary ring (2px)

### Sorting

Default sort: **Modified date, descending** (newest first). Provide sort controls in the table header (click column to sort, click again to reverse) and a dropdown for grid view.

**Sortable fields:** Name (A-Z/Z-A), Modified date (newest/oldest), Size (largest/smallest), Type (A-Z).

### Search and filter

- **Search bar:** above the file list, full width or 50% width on desktop. Search by file name. Debounce 300ms.
- **Type filter:** dropdown or chip-based filter for file type (Images, Documents, Spreadsheets, Videos, All).
- **Date filter:** quick presets (Today, Last 7 days, Last 30 days, Custom range).
- **Clear all filters:** show a "Clear filters" link when any filter is active.

### Bulk selection

- **Checkbox in table header:** toggles all visible files
- **Individual checkboxes:** per row, visible at all times (don't hide until hover — that breaks keyboard users)
- **Shift+click:** select a range
- **Bulk action bar:** appears when 1+ files selected, floats above the list or replaces the toolbar

```
┌──────────────────────────────────────────────────┐
│  ☑ 5 files selected   [Download]  [Move]  [🗑️]  │
└──────────────────────────────────────────────────┘
```

- Show count of selected items
- Available actions: Download (zip if multiple), Move to folder, Delete, Copy link
- Destructive actions (Delete) require confirmation: "Delete 5 files? This cannot be undone."

### Folder organization and breadcrumbs

If the file system supports folders:

```
┌──────────────────────────────────────────────────┐
│  📁 Home  >  📁 Projects  >  📁 Q1 Reports      │
│                                                  │
│  [New Folder]  [Upload Files]   🔍 Search        │
├──────────────────────────────────────────────────┤
│  📁 Drafts           —    —       Apr 10         │
│  📁 Final            —    —       Apr 8          │
│  📄 summary.pdf    2.4MB  PDF     Apr 10         │
│  📄 data.xlsx      1.1MB  XLSX    Apr 9          │
└──────────────────────────────────────────────────┘
```

- **Breadcrumbs:** show the full path. Each segment is clickable. Truncate middle segments with "..." if the path is deep (> 4 levels).
- **Folders sort above files** in the list (common convention: Google Drive, Finder, Explorer).
- **Navigate into folder:** single-click on the folder row.
- **Drag files to folders:** drag a file row onto a folder row to move it. Show a blue highlight on the target folder during drag.

---

## Avatar / profile photo upload

Avatar upload is a special case: single file, circular crop, small dimensions, immediate preview.

### The flow

1. User clicks avatar or "Change photo" button
2. File picker opens (accept: `image/png, image/jpeg, image/webp`)
3. User selects image
4. **Crop modal opens** with circular crop overlay
5. User adjusts crop, clicks "Save"
6. Compressed image uploads
7. New avatar replaces old one immediately (optimistic update)

### Circular crop specs

- **Crop overlay:** circular mask, everything outside the circle at 60% opacity (dark overlay)
- **Minimum crop size:** 100x100px (to prevent microscopic avatars)
- **Target output:** 256x256px for standard, 512x512px for high-DPI
- **Max file size before crop:** 5MB
- **Max file size after crop+compress:** target < 100KB (JPEG at 85% quality)
- **Zoom control:** slider below the image, 1x–3x range

```
┌──────────────────────────────────────────┐
│           Upload Profile Photo           │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │         ╭──────────╮              │  │
│  │       ╭─╯          ╰─╮            │  │
│  │      │   [face area]  │           │  │
│  │       ╰─╮          ╭─╯            │  │
│  │         ╰──────────╯              │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Zoom:  ─────●──────────                 │
│                                          │
│        [Cancel]          [Save]          │
└──────────────────────────────────────────┘
```

### Fallback / default avatar

When no photo is uploaded, generate a default:

**Fallback priority order:**
1. Uploaded photo
2. Initials-based avatar (first letter of first name + first letter of last name)
3. Generic user icon (silhouette)

**Initials avatar rules:**
- **Background color:** derive deterministically from the user's name or ID using a hash. The same user always gets the same color. Choose from a palette of 8–10 distinct, medium-saturation colors.
- **Text:** initials in white, centered, font-weight 600
- **Text size relative to avatar:** 40% of avatar diameter (e.g., 13px text in a 32px avatar)

```typescript
const AVATAR_COLORS = [
  '#E57373', '#F06292', '#BA68C8', '#9575CD',
  '#7986CB', '#64B5F6', '#4FC3F7', '#4DB6AC',
  '#81C784', '#FFB74D',
];

function getAvatarColor(name: string): string {
  let hash = 0;
  for (const char of name) hash = char.charCodeAt(0) + ((hash << 5) - hash);
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

function InitialsAvatar({ name, size = 40 }: { name: string; size?: number }) {
  const initials = name
    .split(' ')
    .slice(0, 2)
    .map((n) => n[0])
    .join('')
    .toUpperCase();

  return (
    <div
      className="rounded-full flex items-center justify-center font-semibold text-white"
      style={{
        width: size,
        height: size,
        backgroundColor: getAvatarColor(name),
        fontSize: size * 0.4,
      }}
    >
      {initials}
    </div>
  );
}
```

---

## CSV / data file import

The four-stage pipeline (upload, map, validate, confirm) is covered in `migration-and-data-import.md`. This section covers the upload UX layer specifically.

### Preview first N rows

After upload, immediately parse and display the first 10 rows so the user can verify the file:

```
┌──────────────────────────────────────────────────────────┐
│  Preview: contacts.csv (2,847 rows)                      │
├──────┬──────────────┬────────────────┬───────────────────┤
│  Row │  Full Name   │  Email         │  Phone            │
├──────┼──────────────┼────────────────┼───────────────────┤
│  1   │  Jane Smith  │  jane@acme.co  │  555-0101         │
│  2   │  Bob Wilson  │  bob@corp.io   │  555-0102         │
│  3   │  ...         │  ...           │  ...              │
│  10  │  Amy Chen    │  amy@co.org    │  555-0110         │
├──────┴──────────────┴────────────────┴───────────────────┤
│  Showing 10 of 2,847 rows                                │
│                                                          │
│  ⚠ 12 rows have validation errors  [View errors]         │
│                                                          │
│  [Cancel]                            [Continue to Map →] │
└──────────────────────────────────────────────────────────┘
```

- Parse CSV client-side using PapaParse (handles encoding, delimiters, quoted fields)
- Show only the first 10 rows — don't render 50,000 rows in the browser
- Show total row count: "2,847 rows detected"
- Flag obvious issues early: "12 rows have empty email fields"

### Column mapping UI

Show a two-column mapping interface: source columns on the left, target fields on the right.

- **Auto-detect mappings** using header similarity (Levenshtein distance, common synonyms)
- **Confidence indicators:** checkmark for high confidence (>90%), yellow dot for medium (60–90%), red X for unmapped
- **Dropdown per source column:** user selects which target field it maps to, or "Skip this column"
- **Required fields indicator:** mark required target fields with an asterisk. Show error if unmapped.

### Validation errors display

After mapping, validate all rows and show errors:

- **Summary:** "2,835 rows valid, 12 rows have errors"
- **Error table:** show only the error rows with the problematic cells highlighted in red
- **Per-cell error message:** tooltip or inline — "Invalid email format," "Phone number too long," "Required field missing"
- **Options:** "Import valid rows only" (skip errors) or "Download error report" (CSV of failed rows with error descriptions) or "Fix and re-upload"

### Progress for large files

For files with >10,000 rows, processing takes noticeable time. Show a progress indicator:

- **Parsing phase:** "Parsing file... 45%" (based on bytes read)
- **Validation phase:** "Validating rows... 1,200 / 50,000"
- **Import phase:** "Importing... 3,400 / 48,800 rows"
- Use a progress bar with percentage and row count. Update every 100 rows, not every row.

---

## Security

File uploads are a major attack surface. Every file from the internet is hostile until proven otherwise.

### File type validation (defense in depth)

**Layer 1 — Client-side extension check:** fast feedback, easy to bypass. Do it for UX, not security.

**Layer 2 — MIME type from Content-Type header:** unreliable. Browsers set this from the extension.

**Layer 3 — Magic bytes (file signature):** read the first 4–8 bytes and verify the file signature. This is the real check.

```typescript
// Common magic bytes
const MAGIC_BYTES: Record<string, number[]> = {
  'image/jpeg': [0xFF, 0xD8, 0xFF],
  'image/png':  [0x89, 0x50, 0x4E, 0x47],
  'image/gif':  [0x47, 0x49, 0x46, 0x38],
  'image/webp': [0x52, 0x49, 0x46, 0x46], // + "WEBP" at offset 8
  'application/pdf': [0x25, 0x50, 0x44, 0x46],
  'application/zip': [0x50, 0x4B, 0x03, 0x04],
};

async function validateMagicBytes(file: File, expectedType: string): Promise<boolean> {
  const expected = MAGIC_BYTES[expectedType];
  if (!expected) return true; // no signature to check

  const buffer = await file.slice(0, expected.length).arrayBuffer();
  const bytes = new Uint8Array(buffer);
  return expected.every((byte, i) => bytes[i] === byte);
}
```

**Layer 4 — Server-side re-validation:** repeat magic byte check on the server. Never trust client-side validation alone.

**Layer 5 — Virus scanning:** scan uploaded files with ClamAV or a cloud scanning service (AWS Malware Protection for S3, Google Cloud DLP). Quarantine files until scan completes. Don't serve unscanned files to other users.

### Presigned URLs for direct-to-S3 uploads

Never route large files through your application server. Use presigned URLs to upload directly to S3 (or GCS, R2, etc.).

**Flow:**
1. Client requests a presigned upload URL from your API
2. API generates a presigned URL with constraints (file type, max size, expiration)
3. Client uploads directly to S3 using the presigned URL
4. S3 triggers a Lambda/webhook on upload complete
5. Lambda validates the file (magic bytes, virus scan, size check)
6. Lambda moves the file from a quarantine bucket to the production bucket
7. API is notified, updates the database with the file reference

```typescript
// Server — generate presigned URL
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

async function createPresignedUploadUrl(
  filename: string,
  contentType: string,
  maxSizeBytes: number
) {
  const key = `uploads/${crypto.randomUUID()}/${sanitizeFilename(filename)}`;

  const command = new PutObjectCommand({
    Bucket: 'my-app-quarantine',
    Key: key,
    ContentType: contentType,
    // S3 enforces content-length-range via presigned POST policies
  });

  const url = await getSignedUrl(s3Client, command, {
    expiresIn: 300, // 5 minutes
  });

  return { url, key };
}
```

**Presigned URL constraints:**
- **Expiration:** 5 minutes max. Short-lived to prevent link sharing.
- **Content-Type:** lock to the expected type.
- **Content-Length-Range:** enforce min/max size (use presigned POST with conditions for this).
- **One URL per file:** don't reuse presigned URLs.

### Preventing path traversal

Uploaded filenames are user-controlled input. Never use them directly in file paths.

```typescript
function sanitizeFilename(filename: string): string {
  return filename
    .replace(/[^a-zA-Z0-9._-]/g, '_')  // strip dangerous chars
    .replace(/\.{2,}/g, '.')             // prevent ../
    .replace(/^\./, '_')                 // prevent hidden files
    .slice(0, 255);                      // limit length
}

// Even better: generate your own filename
function generateStorageKey(originalName: string): string {
  const ext = path.extname(originalName).toLowerCase().slice(0, 10);
  const id = crypto.randomUUID();
  return `${id}${ext}`; // e.g., "a1b2c3d4-e5f6-7890-abcd-ef1234567890.pdf"
}
```

**Never construct file paths from user input.** Always generate your own keys. Store the original filename as metadata in the database, separate from the storage key.

### Max file size enforcement

Enforce at every layer:

| Layer | How | Why |
|---|---|---|
| HTML `<input>` | `accept` attribute | Filters file picker (not enforceable) |
| Client-side JS | `file.size` check | Fast feedback before upload starts |
| Presigned URL | `content-length-range` condition | S3/cloud enforces, rejects oversized |
| Reverse proxy | `client_max_body_size` (Nginx) | Prevents oversized requests hitting app |
| Application server | Request body size limit | Defense in depth |

Set limits slightly above the advertised max to account for multipart encoding overhead (add 5–10%).

---

## Don'ts

- **Don't auto-upload on file selection** without user confirmation (except for avatar uploads where this is expected).
- **Don't show an indeterminate spinner for file uploads.** Always show a progress bar with percentage.
- **Don't lose the upload** when the user navigates to another page. Use background uploads.
- **Don't trust client-side file type validation** as a security measure. Always re-validate server-side.
- **Don't store files on the application server filesystem.** Use object storage (S3, GCS, R2).
- **Don't serve uploaded files from the same domain** as your application. Use a separate domain or CDN to prevent cookie-based attacks.
- **Don't allow executable file uploads** (.exe, .bat, .sh, .cmd, .ps1, .msi) unless your product specifically requires it.
- **Don't expose the internal storage path or key** to end users. Use signed, time-limited download URLs.
- **Don't silently ignore failed uploads.** Every failure must surface to the user with a retry option.
- **Don't delete uploaded files immediately** on "delete" — soft-delete with a 30-day retention window, or use undo-toast pattern.
