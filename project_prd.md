Product Requirements Document (PRD)
Project Name: SenseLite — Offline Image Annotation Tool
Version: 1.0
1. Product Overview

SenseLite is a cross-platform desktop application (Windows, macOS, Linux) built using Flutter. It allows users to annotate images for computer vision datasets fully offline.
Unlike MakeSense.ai, which stores temporary data in browsers and vanishes with refreshes, SenseLite stores projects locally and supports offline workflows for researchers, students, and machine learning developers.

2. Problem Statement

Existing online annotation tools require internet connectivity and don’t persist user data locally. Users lose progress when sessions end or browsers refresh. Organizations also face privacy concerns when uploading proprietary datasets to cloud-based platforms.

3. Objectives & Success Metrics
Objective	Success Metric
Enable offline image annotation	App runs with no internet dependency
Preserve annotations locally	Data saved to local storage in real time
Support standard export formats	Export annotations as JSON, COCO, Pascal VOC
Easy to use UI	User can label an image within 2 minutes of first launch
4. Target Users / Personas

ML Engineers: Annotating data for model training.

Students: Learning dataset creation and labeling.

Researchers: Handling confidential data offline.

Freelancers: Annotating client-provided datasets without risking upload.

5. User Stories / Use Cases

As a user, I can load a folder of images to start annotation.

As a user, I can draw bounding boxes, polygons, and keypoints.

As a user, I can assign class labels to annotations.

As a user, I can save my project locally (autosave).

As a user, I can export my annotations in JSON, COCO, or Pascal VOC format.

As a user, I can reopen previous projects and continue labeling.

6. Functional Requirements
Module	Description
Image Import	Load single or batch of images from local folder
Annotation Tools	Bounding box, polygon, keypoint, eraser
Label Management	Create, edit, and delete label classes
Autosave	Save annotations locally in SQLite or local file system
Export	JSON, COCO, Pascal VOC
Project Manager	Manage multiple annotation projects
Settings	Dark/light mode, keyboard shortcuts
Undo/Redo	Step-based editing history
7. Non-Functional Requirements
Category	Requirement
Platform	Cross-platform via Flutter desktop
Performance	Load 1000+ images smoothly
Security	No internet access required
Data Storage	SQLite or local file JSON-based storage
UI	Responsive layout (Material 3, Flutter desktop UI)
File Handling	Supports drag-and-drop folders
8. Technical Architecture

Frontend: Flutter (desktop)
State Management: Riverpod / Bloc
Database: SQLite (via sqflite plugin)
File Storage: Local file system (annotations saved in project folder)
Export Service: Dart backend module for converting annotations
Offline Support: No network dependency

9. Milestones / Timeline
Phase	Description	Duration
Phase 1	Core UI & project setup (menus, layout, file import)	2 weeks
Phase 2	Annotation tools (bounding box, polygon, etc.)	3 weeks
Phase 3	Local save & project management	2 weeks
Phase 4	Export functionality & testing	2 weeks
Phase 5	Packaging for Windows, macOS, Linux	1 week
10. Future Enhancements (Post v1.0)

Multi-user local profiles

Video annotation support

Model-assisted labeling (integrate TensorFlow Lite)

Cloud sync (optional, toggleable)

Version control for annotations

Summary Table
Category	Highlights
Type	Flutter desktop app
Offline	Fully offline, local storage
Core Tools	Bounding boxes, polygons, keypoints
Save Format	JSON, COCO, Pascal VOC
Database	SQLite or local JSON
Platforms	Windows, macOS, Linux
Goal	Replace MakeSense.ai with a local, permanent tool