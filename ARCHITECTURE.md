# DevoTranscribe Architecture

This document provides comprehensive architectural diagrams for the DevoTranscribe speech-to-text platform, built with Next.js, FastAPI, and Google Cloud Platform.

---

## 1. High-Level Architecture Overview

This diagram shows the main runtime components and data flow of the DevoTranscribe platform.

```mermaid
graph TB
    subgraph "Client Layer"
        User[👤 User Browser]
    end

    subgraph "Google Cloud Platform - europe-west1"
        subgraph "Application Layer - Cloud Run"
            Frontend["🌐 Frontend Service<br/>Next.js 15 + React<br/>1 CPU / 2GB RAM"]
            Backend["⚙️ Backend Service<br/>FastAPI + Python<br/>2 CPU / 4GB RAM<br/>FFmpeg for audio extraction"]
        end

        subgraph "Storage Layer"
            Uploads["📦 GCS Bucket<br/>audio-uploads<br/>Standard Storage"]
            Transcripts["📄 GCS Bucket<br/>transcripts<br/>Standard Storage"]
        end

        subgraph "AI/ML Services"
            SpeechAPI["🎤 Cloud Speech-to-Text API<br/>Chirp 3 Model<br/>Dutch (nl-NL)"]
            VertexAI["🤖 Vertex AI<br/>Gemini 2.5 Pro<br/>Speaker Identification"]
        end
    end

    User -->|"HTTPS"| Frontend
    User -.->|"WebSocket<br/>Real-time Updates"| Backend
    Frontend <-->|"REST API"| Backend
    Backend -->|"Upload Audio/Video<br/>Signed URLs"| Uploads
    Backend -->|"Store Results"| Transcripts
    Backend -->|"Transcribe Audio<br/>nl-NL Language"| SpeechAPI
    Backend -->|"Identify Speakers<br/>LLM Analysis"| VertexAI
    Backend -->|"Extract Audio<br/>FFmpeg"| Backend
    Uploads -->|"Read for Processing"| Backend
    Transcripts -->|"Retrieve Results"| Backend

    style User fill:#e1f5ff
    style Frontend fill:#4CAF50
    style Backend fill:#2196F3
    style Uploads fill:#FF9800
    style Transcripts fill:#FF9800
    style SpeechAPI fill:#9C27B0
    style VertexAI fill:#9C27B0
```

**Key Components:**
- **Frontend**: Serverless Next.js application handling UI, file uploads, and real-time progress display
- **Backend**: Async FastAPI service orchestrating transcription pipeline, WebSocket connections, and AI service integration
- **Cloud Storage**: Two buckets for uploaded files and completed transcripts
- **Speech-to-Text API**: Google's Chirp 3 model for high-accuracy Dutch transcription
- **Vertex AI Gemini**: Advanced LLM for intelligent speaker identification
- **FFmpeg**: Embedded in backend for automatic audio extraction from video files

---

## 2. Detailed System Architecture (Including CI/CD)

This comprehensive diagram includes the full development and deployment pipeline alongside runtime components.

```mermaid
graph TB
    subgraph "Development"
        Dev[👨‍💻 Developer]
        Git[📚 Git Repository<br/>GitHub]
    end

    subgraph "Google Cloud Platform - Project ID"
        subgraph "CI/CD Pipeline"
            CloudBuild["🔨 Cloud Build<br/>Build Triggers<br/>E2_HIGHCPU_8"]
            ArtifactRegistry["📦 Artifact Registry<br/>europe-west1-docker.pkg.dev<br/>Container Images"]
            Terraform["🏗️ Terraform<br/>Infrastructure as Code<br/>Cloud Run + Storage + Build"]
        end

        subgraph "europe-west1 Region"
            subgraph "Cloud Run Services"
                FrontendService["🌐 Frontend<br/>speech-frontend<br/>Next.js Container<br/>Min: 0 | Max: 10<br/>Concurrency: 100"]
                BackendService["⚙️ Backend<br/>speech-backend<br/>FastAPI Container<br/>Min: 1 | Max: 10<br/>Timeout: 3600s"]
            end

            subgraph "Cloud Storage Buckets"
                UploadBucket["📤 audio-uploads<br/>5GB limit<br/>Uniform Access<br/>Lifecycle: 7 days"]
                TranscriptBucket["📥 transcripts<br/>Processed Results<br/>Uniform Access"]
            end

            subgraph "Identity & Access"
                FrontendSA["🔐 Frontend SA<br/>Storage Object Creator"]
                BackendSA["🔐 Backend SA<br/>Storage Admin<br/>Speech Client<br/>Vertex AI User"]
            end
        end

        subgraph "AI Services - Multi-Region"
            SpeechV2["🎤 Speech-to-Text v2<br/>Chirp 3 Model<br/>nl-NL Configuration<br/>Auto Punctuation"]
            Gemini["🤖 Vertex AI Gemini 2.5 Pro<br/>Temperature: 0.3<br/>Speaker Analysis<br/>2-10 Speakers"]
        end

        subgraph "Monitoring & Logging"
            CloudLogging["📊 Cloud Logging<br/>Application Logs"]
            HealthChecks["💓 Health Checks<br/>/ endpoint every 30s"]
        end
    end

    subgraph "Users"
        Browser["🌐 Web Browser<br/>Desktop/Mobile"]
    end

    Dev -->|"git push"| Git
    Git -->|"Webhook Trigger"| CloudBuild
    CloudBuild -->|"Build Docker Images"| ArtifactRegistry
    CloudBuild -->|"Deploy Containers"| FrontendService
    CloudBuild -->|"Deploy Containers"| BackendService
    Terraform -.->|"Provision & Configure"| FrontendService
    Terraform -.->|"Provision & Configure"| BackendService
    Terraform -.->|"Create Buckets"| UploadBucket
    Terraform -.->|"Create Buckets"| TranscriptBucket
    Terraform -.->|"Create & Bind"| FrontendSA
    Terraform -.->|"Create & Bind"| BackendSA
    Terraform -.->|"Configure Triggers"| CloudBuild

    Browser -->|"HTTPS Requests"| FrontendService
    Browser -.->|"WebSocket /ws/{job_id}"| BackendService
    FrontendService -->|"API Calls"| BackendService
    FrontendService -.->|"Uses Identity"| FrontendSA
    BackendService -.->|"Uses Identity"| BackendSA
    BackendService -->|"Signed URLs<br/>Upload/Download"| UploadBucket
    BackendService -->|"Store Transcripts"| TranscriptBucket
    BackendService -->|"Transcribe Request<br/>Long-Running Recognize"| SpeechV2
    BackendService -->|"Speaker ID Request<br/>GenerateContent"| Gemini

    FrontendService -->|"Logs"| CloudLogging
    BackendService -->|"Logs"| CloudLogging
    HealthChecks -->|"Check"| FrontendService
    HealthChecks -->|"Check"| BackendService

    style Dev fill:#e1f5ff
    style Git fill:#f0f0f0
    style CloudBuild fill:#4CAF50
    style ArtifactRegistry fill:#FF9800
    style Terraform fill:#7B1FA2
    style FrontendService fill:#4CAF50
    style BackendService fill:#2196F3
    style UploadBucket fill:#FF9800
    style TranscriptBucket fill:#FF9800
    style FrontendSA fill:#FFC107
    style BackendSA fill:#FFC107
    style SpeechV2 fill:#9C27B0
    style Gemini fill:#9C27B0
    style CloudLogging fill:#607D8B
    style HealthChecks fill:#607D8B
    style Browser fill:#e1f5ff
```

**Infrastructure Details:**

**Cloud Run Configuration:**
- **Frontend**: Scales to zero when idle, handles static assets and Next.js SSR
- **Backend**: Always-warm (min 1 instance), handles long-running transcription jobs up to 1 hour

**CI/CD Pipeline:**
- Automated builds triggered on git push
- Multi-stage Docker builds with UV package manager (backend) and Next.js standalone mode (frontend)
- Deployment to Cloud Run with zero-downtime rolling updates

**Security:**
- Service accounts with least-privilege IAM roles
- Signed URLs for secure file uploads (1-hour expiration)
- CORS configured per environment
- Non-root containers (UID 1001)

**Storage:**
- Audio uploads bucket: 7-day lifecycle policy for automatic cleanup
- Transcripts bucket: Persistent storage for completed transcriptions
- Uniform bucket-level access for simplified IAM

---

## 3. User Flow Sequence Diagram

This diagram illustrates the complete journey from file upload to receiving a transcription with speaker identification.

```mermaid
sequenceDiagram
    actor User
    participant Browser
    participant Frontend as Frontend Service<br/>(Next.js)
    participant Backend as Backend Service<br/>(FastAPI)
    participant GCS as Cloud Storage
    participant FFmpeg
    participant Speech as Speech-to-Text API<br/>(Chirp 3)
    participant Gemini as Vertex AI Gemini<br/>(Speaker ID)

    User->>Browser: Select audio/video file
    Browser->>Frontend: Upload file via drag-and-drop

    Note over Frontend,Backend: Phase 1: File Upload
    Frontend->>Backend: POST /api/v1/signed-url<br/>{filename, content_type, file_size}
    Backend->>GCS: Generate signed upload URL
    GCS-->>Backend: Signed URL (1-hour expiration)
    Backend-->>Frontend: {upload_url, gcs_uri}

    alt Large File (>100MB)
        Frontend->>GCS: Resumable Upload (chunked)
    else Small File (<100MB)
        Frontend->>GCS: Direct Upload via signed URL
    end

    Frontend->>Browser: Update progress bar (0-100%)
    GCS-->>Frontend: Upload complete

    Note over Frontend,Backend: Phase 2: Transcription Request
    User->>Browser: Click "Start Transcription"
    Browser->>Frontend: Initiate transcription
    Frontend->>Backend: POST /api/v1/transcribe<br/>{gcs_uri, enable_speaker_id, language_code}
    Backend->>Backend: Create job_id<br/>Store job status: "pending"
    Backend-->>Frontend: {job_id, status: "pending"}

    Frontend->>Backend: WebSocket connect /ws/{job_id}
    Backend-->>Frontend: WebSocket connection established

    Note over Backend,GCS: Phase 3: Background Processing
    Backend->>Backend: Update status: "processing"
    Backend->>Frontend: WebSocket: {status: "processing", progress: 20%}

    Backend->>GCS: Download file from gcs_uri
    GCS-->>Backend: Audio/Video file bytes

    alt Video File (MP4, MOV, WEBM)
        Backend->>Backend: Update status: "extracting_audio"
        Backend->>Frontend: WebSocket: {status: "extracting_audio", progress: 30%}
        Backend->>FFmpeg: Extract audio track<br/>Convert to PCM 16-bit mono 16kHz
        FFmpeg-->>Backend: Extracted audio bytes
        Backend->>GCS: Upload extracted audio
    end

    Note over Backend,Speech: Phase 4: Speech Recognition
    Backend->>Backend: Update status: "transcribing"
    Backend->>Frontend: WebSocket: {status: "transcribing", progress: 50%}

    Backend->>Speech: LongRunningRecognize<br/>{gcs_uri, language_code: "nl-NL",<br/>enable_automatic_punctuation: true}
    Speech->>Speech: Process audio with Chirp 3 model
    Speech-->>Backend: Transcription results<br/>{transcript, word_timings, confidence}

    Backend->>Backend: Parse results into segments<br/>Extract word-level timestamps

    alt Speaker Identification Enabled
        Note over Backend,Gemini: Phase 5: Speaker Analysis
        Backend->>Backend: Update status: "identifying_speakers"
        Backend->>Frontend: WebSocket: {status: "identifying_speakers", progress: 80%}

        Backend->>Backend: Segment transcript into chunks<br/>(35-320 characters, max 60 segments)

        loop For each batch of segments
            Backend->>Gemini: GenerateContent<br/>{transcript_chunks, num_speakers: 2-6,<br/>temperature: 0.3}
            Gemini->>Gemini: Analyze conversation patterns<br/>Identify speaker changes
            Gemini-->>Backend: Speaker labels with confidence
        end

        Backend->>Backend: Aggregate speaker labels<br/>Assign to transcript segments
    end

    Note over Backend,GCS: Phase 6: Results Storage
    Backend->>Backend: Update status: "completed"
    Backend->>GCS: Store transcript JSON<br/>(transcripts bucket)
    GCS-->>Backend: Storage confirmed

    Backend->>Frontend: WebSocket: {status: "completed",<br/>progress: 100%, result_uri}

    Frontend->>Backend: GET /api/v1/transcriptions/{job_id}
    Backend->>GCS: Fetch transcript
    GCS-->>Backend: Transcript JSON
    Backend-->>Frontend: {segments, speakers, timestamps,<br/>confidence_scores}

    Frontend->>Browser: Display transcript with speakers
    Browser->>User: Show results + download option

    Note over Frontend,Backend: Phase 7: Session Persistence
    Frontend->>Browser: Save job to localStorage<br/>(48-hour TTL)

    alt User Returns Later
        User->>Browser: Reload page
        Browser->>Frontend: Retrieve jobs from localStorage
        Frontend->>Backend: GET /api/v1/transcriptions/{job_id}
        Backend-->>Frontend: Cached/Stored results
        Frontend->>Browser: Restore previous session
    end
```

**Flow Phases:**

1. **File Upload** (0-100% of upload progress)
   - Request signed URL from backend
   - Upload directly to GCS using signed URL (resumable for large files)
   - No file data passes through backend (efficient for large files)

2. **Transcription Request**
   - Create job with unique ID
   - Establish WebSocket for real-time updates
   - Return immediately (async processing)

3. **Background Processing**
   - Download file from GCS
   - Extract audio if video format (FFmpeg)
   - Update status via WebSocket

4. **Speech Recognition**
   - Call Speech-to-Text API with Chirp 3
   - Automatic Dutch language processing
   - Word-level timing and confidence scores

5. **Speaker Analysis** (Optional)
   - Segment transcript intelligently (35-320 chars)
   - Batch process with Gemini (up to 60 segments/request)
   - Maintain speaker consistency across conversation

6. **Results Storage**
   - Save to GCS transcripts bucket
   - Cache in backend memory
   - Send completion event via WebSocket

7. **Session Persistence**
   - Store job metadata in browser localStorage
   - 48-hour TTL for automatic cleanup
   - Restore sessions across browser reloads

**Timing Estimates:**
- Upload: Varies by file size and connection (5MB = ~10s, 500MB = ~5 min)
- Audio Extraction: ~10-30 seconds for typical video files
- Transcription: ~1/3 to 1/2 of audio duration (30-min audio = ~10-15 min processing)
- Speaker ID: ~2-5 seconds per minute of audio
- **Total**: 5-minute audio typically processes in 3-5 minutes end-to-end

---

## Technology Stack Summary

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Next.js 15 + React 18 | Server-side rendering and modern UI |
| **Frontend Styling** | Tailwind CSS 3.4 | Responsive, utility-first styling |
| **Frontend State** | SWR + Custom Hooks | Data fetching and state management |
| **Backend** | FastAPI 0.115 | High-performance async API framework |
| **Backend Language** | Python 3.11+ | Core business logic and AI integration |
| **Package Manager** | UV (Rust-based) | Ultra-fast Python dependency resolution |
| **Audio Processing** | FFmpeg | Audio extraction and format conversion |
| **Transcription** | Google Cloud Speech-to-Text v2 (Chirp 3) | State-of-the-art multilingual speech recognition |
| **Speaker ID** | Google Vertex AI Gemini 2.5 Pro | Advanced LLM for conversation analysis |
| **Storage** | Google Cloud Storage | Scalable object storage for audio/transcripts |
| **Hosting** | Google Cloud Run | Serverless container platform |
| **CI/CD** | Cloud Build | Automated build and deployment |
| **IaC** | Terraform | Infrastructure as code |
| **Containerization** | Docker | Application packaging and isolation |
| **Real-time** | WebSockets | Live progress updates to frontend |
| **API Docs** | OpenAPI/Swagger | Interactive API documentation |
| **Monitoring** | Cloud Logging | Centralized application logging |

---

## Architecture Principles

**Cloud-Native**: Built for the cloud from day one, leveraging serverless architecture for automatic scaling and cost efficiency.

**Async-First**: FastAPI and Python asyncio enable efficient handling of long-running transcription jobs without blocking.

**API-Driven**: Clean REST API design enables future integrations and client applications beyond the web interface.

**Separation of Concerns**: Frontend handles presentation, backend orchestrates business logic, cloud services provide specialized capabilities.

**Infrastructure as Code**: Terraform manages all infrastructure, ensuring reproducible deployments and version-controlled infrastructure.

**Security by Design**: Service accounts with least privilege, signed URLs for time-limited access, non-root containers, and CORS protection.

**Developer Experience**: Type safety (TypeScript + Pydantic), automated testing, hot reload in development, comprehensive API documentation.

**Observability**: Structured logging, health checks, and Cloud Monitoring integration for production visibility.

---

**Last Updated**: 2025
**Architecture Version**: 1.0
**Built by**: Joshua Vink | Devoteam
