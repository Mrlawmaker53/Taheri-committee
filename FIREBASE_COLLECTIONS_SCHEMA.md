# Firebase Collections Schema - Taheri Committee App

## Overview
This document outlines the Firebase Firestore collections schema for the Taheri Committee Community Management App. The app manages community members, events, attendance, hierarchy, and various administrative functions.

## Collections

### 1. `users` Collection
**Purpose**: Store user profile information and authentication data

```javascript
users/{userId}
├── fullName: String (required)
├── email: String (required, unique)
├── role: String (required) - "leader" | "coreTeamLeader" | "captain" | "supervisor" | "monitor" | "member" | "admin"
├── teamId: String (optional) - Reference to teams collection
├── avatarUrl: String (optional)
├── isActive: Boolean (default: true)
├── mobile: String (optional)
├── createdAt: Timestamp (required)
├── lastLoginAt: Timestamp (optional)
├── fcmToken: String (optional) - For push notifications
├── address: String (optional)
├── gender: String - "male" | "female"
└── hierarchyParentId: String (optional) - Reference to another user for hierarchy
```

**Indexes**:
- Email (unique)
- role
- isActive
- teamId
- hierarchyParentId

---

### 2. `hierarchy` Collection
**Purpose**: Store organizational hierarchy structure

```javascript
hierarchy/{nodeId}
├── name: String (required)
├── email: String (required, unique)
├── phone: String (required)
├── role: String (required) - enum HierarchyRole
├── gender: String (required) - "male" | "female"
├── parentId: String (optional) - Reference to parent node
├── memberIds: Array<String> (default: []) - Direct member IDs
├── createdAt: Timestamp (required)
├── lastActive: Timestamp (optional)
├── isActive: Boolean (default: true)
├── address: String (optional)
└── avatarUrl: String (optional)
```

**Role Hierarchy**:
1. `leader` (Level 0) - Can have 2 coreTeamLeaders
2. `coreTeamLeader` (Level 1) - Can have 2 captains
3. `captain` (Level 2) - Can have 2 supervisors
4. `supervisor` (Level 3) - Can have 1 monitor + 10 members
5. `monitor` (Level 4) - Can have 10 members
6. `member` (Level 5) - No children

**Indexes**:
- parentId
- role
- gender
- isActive

---

### 3. `teams` Collection
**Purpose**: Team management and organization

```javascript
teams/{teamId}
├── name: String (required)
├── description: String (optional)
├── leaderId: String (required) - Reference to users
├── memberIds: Array<String> (default: [])
├── isActive: Boolean (default: true)
├── createdAt: Timestamp (required)
├── maxMembers: Number (default: 50)
├── gender: String - "male" | "female" | "mixed"
└── teamColor: String (optional) - Hex color code
```

**Indexes**:
- leaderId
- isActive
- gender

---

### 4. `events` Collection
**Purpose**: Event management and scheduling

```javascript
events/{eventId}
├── title: String (required)
├── description: String (optional)
├── createdBy: String (required) - Reference to users
├── eventDate: Timestamp (required)
├── location: String (required)
├── rsvpEnabled: Boolean (default: true)
├── attendanceEnabled: Boolean (default: true)
├── isActive: Boolean (default: true)
├── createdAt: Timestamp (required)
├── updatedAt: Timestamp (required)
├── maxAttendees: Number (optional)
├── imageUrl: String (optional)
├── eventType: String - "prayer" | "community" | "service" | "meeting" | "other"
├── priority: String - "low" | "medium" | "high"
└── Transport Fields:
    ├── transportRequired: Boolean (default: false)
    ├── transportCapacity: Number (default: 0)
    ├── transportStatus: String - "none" | "planning" | "active" | "completed"
    ├── transportNotes: String (optional)
    └── transportRegistrationDeadline: Timestamp (optional)
```

**Indexes**:
- eventDate
- createdBy
- isActive
- rsvpEnabled
- attendanceEnabled

---

### 5. `attendance` Collection
**Purpose**: Track event attendance

```javascript
attendance/{attendanceId}
├── eventId: String (required) - Reference to events
├── userId: String (required) - Reference to users
├── scannedAt: Timestamp (required)
├── method: String - "qr" | "manual" | "self"
├── verifiedBy: String (optional) - Reference to users (for manual check-in)
├── location: String (optional) - GPS coordinates
├── status: String - "present" | "late" | "excused"
└── notes: String (optional)
```

**Indexes**:
- eventId + userId (composite)
- userId
- scannedAt
- method

---

### 6. `rsvps` Collection
**Purpose**: Event RSVP management

```javascript
rsvps/{rsvpId}
├── eventId: String (required) - Reference to events
├── userId: String (required) - Reference to users
├── status: String - "attending" | "not_attending" | "maybe"
├── respondedAt: Timestamp (required)
├── guestsCount: Number (default: 0)
├── notes: String (optional)
├── transportNeeded: Boolean (default: false)
└── updatedAt: Timestamp (required)
```

**Indexes**:
- eventId + userId (composite)
- eventId
- userId
- status

---

### 7. `announcements` Collection
**Purpose**: Community announcements and notifications

```javascript
announcements/{announcementId}
├── title: String (required)
├── content: String (required)
├── authorId: String (required) - Reference to users
├── createdAt: Timestamp (required)
├── isActive: Boolean (default: true)
├── priority: String - "low" | "medium" | "high" | "urgent"
├── targetAudience: Array<String> - Role-based targeting
├── imageUrl: String (optional)
├── linkUrl: String (optional)
├── expiresAt: Timestamp (optional)
├── viewCount: Number (default: 0)
└── category: String - "general" | "event" | "service" | "urgent"
```

**Indexes**:
- createdAt
- authorId
- isActive
- priority
- expiresAt

---

### 8. `contributions` Collection
**Purpose**: Track financial contributions and donations

```javascript
contributions/{contributionId}
├── userId: String (required) - Reference to users
├── amount: Number (required)
├── currency: String (default: "USD")
├── type: String - "donation" | "service" | "volunteer" | "other"
├── description: String (optional)
├── date: Timestamp (required)
├── status: String - "pending" | "approved" | "rejected"
├── approvedBy: String (optional) - Reference to users
├── approvedAt: Timestamp (optional)
├── receiptUrl: String (optional)
├── isAnonymous: Boolean (default: false)
└── groupId: String (optional) - For group contributions
```

**Indexes**:
- userId
- date
- status
- type
- groupId

---

### 9. `activity_logs` Collection
**Purpose**: Audit trail and activity tracking

```javascript
activity_logs/{logId}
├── userId: String (required) - Reference to users
├── action: String (required) - "login" | "logout" | "check_in" | "rsvp" | "register" | etc.
├── resource: String (optional) - Resource type (event, user, etc.)
├── resourceId: String (optional) - Resource ID
├── timestamp: Timestamp (required)
├── ipAddress: String (optional)
├── userAgent: String (optional)
├── details: Map<String, dynamic> (optional)
└── severity: String - "info" | "warning" | "error"
```

**Indexes**:
- userId
- timestamp
- action
- severity

---

### 10. `notifications` Collection
**Purpose**: Push notification management

```javascript
notifications/{notificationId}
├── title: String (required)
├── body: String (required)
├── userId: String (required) - Reference to users
├── type: String - "event" | "announcement" | "reminder" | "system"
├── createdAt: Timestamp (required)
├── readAt: Timestamp (optional)
├── isRead: Boolean (default: false)
├── data: Map<String, dynamic> (optional) - Additional data
├── imageUrl: String (optional)
├── actionUrl: String (optional)
└── expiresAt: Timestamp (optional)
```

**Indexes**:
- userId
- isRead
- createdAt
- type

---

### 11. `seat_bookings` Collection
**Purpose**: Event seat reservations

```javascript
seat_bookings/{bookingId}
├── eventId: String (required) - Reference to events
├── userId: String (required) - Reference to users
├── seatNumber: String (required)
├── section: String (optional)
├── bookedAt: Timestamp (required)
├── status: String - "confirmed" | "pending" | "cancelled"
├── confirmedBy: String (optional) - Reference to users
├── specialRequests: String (optional)
└── qrCode: String (optional) - For check-in
```

**Indexes**:
- eventId
- userId
- seatNumber
- status

---

### 12. `transport_requests` Collection
**Purpose**: Transportation requests for events

```javascript
transport_requests/{requestId}
├── eventId: String (required) - Reference to events
├── userId: String (required) - Reference to users
├── pickupLocation: String (required)
├── dropoffLocation: String (required)
├── requestedAt: Timestamp (required)
├── status: String - "pending" | "approved" | "rejected" | "completed"
├── approvedBy: String (optional) - Reference to users
├── approvedAt: Timestamp (optional)
├── vehicleType: String (optional)
├── estimatedTime: String (optional)
├── specialNeeds: String (optional)
└── notes: String (optional)
```

**Indexes**:
- eventId
- userId
- status
- requestedAt

---

### 13. `group_requests` Collection
**Purpose**: Group contribution and service requests

```javascript
group_requests/{requestId}
├── title: String (required)
├── description: String (required)
├── requestedBy: String (required) - Reference to users
├── targetAmount: Number (optional)
├── currentAmount: Number (default: 0)
├── deadline: Timestamp (optional)
├── status: String - "active" | "completed" | "cancelled"
├── type: String - "contribution" | "service" | "volunteer"
├── createdAt: Timestamp (required)
├── contributors: Array<String> (default: []) - User IDs
├── category: String (optional)
└── imageUrl: String (optional)
```

**Indexes**:
- requestedBy
- status
- type
- deadline

---

### 14. `waiting_list` Collection
**Purpose**: Event waiting list management

```javascript
waiting_list/{waitlistId}
├── eventId: String (required) - Reference to events
├── userId: String (required) - Reference to users
├── joinedAt: Timestamp (required)
├── status: String - "waiting" | "notified" | "confirmed" | "cancelled"
├── position: Number (required)
├── notifiedAt: Timestamp (optional)
├── expiresAt: Timestamp (optional)
└── preferences: Map<String, dynamic> (optional)
```

**Indexes**:
- eventId
- userId
- status
- position

---

### 15. `transfer_requests` Collection
**Purpose**: Team transfer requests

```javascript
transfer_requests/{transferId}
├── requesterId: String (required) - Reference to users
├── fromTeamId: String (required) - Reference to teams
├── toTeamId: String (required) - Reference to teams
├── reason: String (required)
├── status: String - "pending" | "approved" | "rejected"
├── requestedAt: Timestamp (required)
├── reviewedBy: String (optional) - Reference to users
├── reviewedAt: Timestamp (optional)
├── reviewComments: String (optional)
└── priority: String - "low" | "medium" | "high"
```

**Indexes**:
- requesterId
- fromTeamId
- toTeamId
- status

---

## Security Rules Summary

### Basic Rules
- Users can only read/write their own documents unless they have admin/supervisor roles
- Hierarchical access based on user roles
- Sensitive fields (like mobile, email) have restricted access

### Role-Based Access
- **Admin**: Full access to all collections
- **Leader**: Access to their hierarchy subtree
- **Supervisor**: Access to their team members' data
- **Member**: Read-only access to public data, limited write access to personal data

## Data Relationships

### Key Relationships
1. `users` ↔ `hierarchy` (one-to-one via userId)
2. `users` ↔ `teams` (many-to-many via memberIds)
3. `events` ↔ `attendance` (one-to-many)
4. `events` ↔ `rsvps` (one-to-many)
5. `events` ↔ `seat_bookings` (one-to-many)
6. `events` ↔ `transport_requests` (one-to-many)

## Optimization Notes

### Indexes
- Composite indexes for frequently queried combinations
- Time-based indexes for reports and analytics
- Role-based indexes for hierarchical data access

### Denormalization
- User names and roles duplicated in some collections for read performance
- Event titles duplicated in attendance/rsvp collections

### Cleanup
- Soft delete pattern using `isActive` flags
- TTL indexes for temporary data (notifications, activity logs)

## Migration Strategy

### Phase 1: Core Collections
1. `users`
2. `hierarchy`
3. `teams`

### Phase 2: Event Management
1. `events`
2. `attendance`
3. `rsvps`

### Phase 3: Advanced Features
1. `contributions`
2. `notifications`
3. `activity_logs`

### Phase 4: Specialized Features
1. `seat_bookings`
2. `transport_requests`
3. `group_requests`

---

This schema provides a comprehensive foundation for the Taheri Committee app's data management needs while maintaining scalability, security, and performance.
