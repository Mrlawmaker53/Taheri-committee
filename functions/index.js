/* eslint-disable no-console */
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ─── Helpers ────────────────────────────────────────────────────────────────

/** Chunk array into N-size groups (Firestore `in` query supports max 10). */
function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) {
    out.push(arr.slice(i, i + size));
  }
  return out;
}

/** Active FCM tokens for the given list of userIds. */
async function getTokensForUsers(userIds) {
  if (!userIds || userIds.length === 0) return [];
  const tokens = [];
  for (const group of chunk(userIds, 10)) {
    const snap = await db
      .collection('fcm_tokens')
      .where('userId', 'in', group)
      .where('isActive', '==', true)
      .get();
    snap.docs.forEach((doc) => {
      const t = doc.data().token;
      if (t) tokens.push(t);
    });
  }
  return tokens;
}

async function getUserIdsInTeam(teamId) {
  const snap = await db
    .collection('users')
    .where('teamId', '==', teamId)
    .where('isActive', '==', true)
    .get();
  return snap.docs.map((d) => d.id);
}

async function getUserIdsByRole(role) {
  const snap = await db
    .collection('users')
    .where('role', '==', role)
    .where('isActive', '==', true)
    .get();
  return snap.docs.map((d) => d.id);
}

async function getAllActiveUserIds() {
  const snap = await db
    .collection('users')
    .where('isActive', '==', true)
    .get();
  return snap.docs.map((d) => d.id);
}

/** Resolve target audience from a doc with targetType / targetTeamId / targetRole / targetUserId. */
async function resolveAudience(data) {
  const t = data.targetType || 'all';
  if (t === 'team' && data.targetTeamId) {
    return getUserIdsInTeam(data.targetTeamId);
  }
  if (t === 'role' && data.targetRole) {
    return getUserIdsByRole(data.targetRole);
  }
  if (t === 'individual' && data.targetUserId) {
    return [data.targetUserId];
  }
  return getAllActiveUserIds();
}

/** Send FCM in batches of 500 tokens (Admin SDK multicast cap). */
async function sendMulticast(tokens, payload) {
  if (!tokens || tokens.length === 0) return { successCount: 0, failureCount: 0 };
  let successCount = 0;
  let failureCount = 0;
  for (const group of chunk(tokens, 500)) {
    try {
      const res = await messaging.sendEachForMulticast({
        tokens: group,
        ...payload,
      });
      successCount += res.successCount || 0;
      failureCount += res.failureCount || 0;
    } catch (e) {
      console.error('sendEachForMulticast error', e);
      failureCount += group.length;
    }
  }
  return { successCount, failureCount };
}

/** Write per-user notification docs in chunked batches (Firestore batch limit 500). */
async function writePerUserNotifications(userIds, base) {
  for (const group of chunk(userIds, 400)) {
    const batch = db.batch();
    for (const uid of group) {
      const ref = db.collection('notifications').doc();
      batch.set(ref, {
        notifId: ref.id,
        userId: uid,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        ...base,
      });
    }
    await batch.commit();
  }
}

// ─── TRIGGER 1: Event created → notify target audience ──────────────────────
exports.onEventCreated = functions.firestore
  .document('events/{eventId}')
  .onCreate(async (snap, context) => {
    const event = snap.data();
    const eventId = context.params.eventId;
    if (!event) return null;

    let userIds = await resolveAudience(event);
    userIds = userIds.filter((id) => id !== event.createdBy);
    if (userIds.length === 0) return null;

    const tokens = await getTokensForUsers(userIds);

    const title = `New Event: ${event.title || 'Untitled'}`;
    const body = `${event.location || 'Location TBD'} — Are you coming?`;

    await writePerUserNotifications(userIds, {
      title,
      body,
      type: 'event_rsvp',
      notifType: 'event_rsvp',
      requiresResponse: true,
      responseOptions: ['Yes', 'No', 'Maybe'],
      targetType: event.targetType || 'all',
      sentBy: event.createdBy || '',
      sentByName: event.createdByName || '',
      eventId,
      responseCount: 0,
    });

    if (tokens.length > 0) {
      await sendMulticast(tokens, {
        notification: { title, body },
        data: {
          type: 'event_rsvp',
          eventId,
          requiresResponse: 'true',
          responseOptions: 'Yes,No,Maybe',
        },
        webpush: {
          notification: {
            icon: '/icons/Icon-192.png',
            badge: '/icons/Icon-192.png',
            requireInteraction: true,
            actions: [
              { action: 'yes', title: 'Yes, Coming' },
              { action: 'no', title: 'Cannot Come' },
            ],
          },
        },
      });
    }
    return null;
  });

// ─── TRIGGER 2: Contribution status changed → notify member ─────────────────
exports.onContributionUpdated = functions.firestore
  .document('contributions/{contribId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    if (before.status === after.status) return null;
    if (!['approved', 'declined'].includes(after.status)) return null;
    if (!after.memberId) return null;

    const tokens = await getTokensForUsers([after.memberId]);
    const statusLabel =
      after.status === 'approved' ? 'Approved ✓' : 'Declined ✗';
    const title = `Contribution ${statusLabel}`;
    const amount = after.amount != null ? after.amount : '';
    const body = `Your contribution${amount ? ` of ${amount}` : ''} has been ${after.status}.`;

    await writePerUserNotifications([after.memberId], {
      title,
      body,
      type: 'contribution',
      notifType: 'contribution',
      requiresResponse: false,
      contribId: context.params.contribId,
    });

    if (tokens.length > 0) {
      await sendMulticast(tokens, {
        notification: { title, body },
        data: {
          type: 'contribution',
          contribId: context.params.contribId,
          requiresResponse: 'false',
        },
      });
    }
    return null;
  });

// ─── TRIGGER 3: Transfer status changed → notify member ─────────────────────
exports.onTransferUpdated = functions.firestore
  .document('transfer_requests/{transferId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    if (before.status === after.status) return null;
    if (!after.memberId) return null;

    const statusMap = {
      pending_leader: 'forwarded to Leader for approval',
      completed: 'approved. You have been moved.',
      declined: 'declined.',
      approved: 'approved.',
    };
    const statusText = statusMap[after.status];
    if (!statusText) return null;

    const tokens = await getTokensForUsers([after.memberId]);
    const title = 'Transfer Request Update';
    const body = `Your transfer request has been ${statusText}`;

    await writePerUserNotifications([after.memberId], {
      title,
      body,
      type: 'transfer',
      notifType: 'transfer',
      requiresResponse: false,
      transferId: context.params.transferId,
    });

    if (tokens.length > 0) {
      await sendMulticast(tokens, {
        notification: { title, body },
        data: {
          type: 'transfer',
          transferId: context.params.transferId,
          requiresResponse: 'false',
        },
      });
    }
    return null;
  });

// ─── TRIGGER 4: Announcement created → fan out to recipients ────────────────
exports.onAnnouncementCreated = functions.firestore
  .document('announcements/{announcementId}')
  .onCreate(async (snap, context) => {
    const ann = snap.data();
    const annId = context.params.announcementId;
    if (!ann) return null;

    let userIds = await resolveAudience(ann);
    const senderId = ann.createdBy || ann.authorId || '';
    userIds = userIds.filter((id) => id !== senderId);
    if (userIds.length === 0) return null;

    const tokens = await getTokensForUsers(userIds);
    const requiresResponse = ann.requiresResponse === true;
    const responseOptions = Array.isArray(ann.responseOptions)
      ? ann.responseOptions
      : [];
    const title = ann.title || 'Committee Notice';
    const body = ann.body || '';

    await writePerUserNotifications(userIds, {
      title,
      body,
      type: 'announcement',
      notifType: 'announcement',
      requiresResponse,
      responseOptions,
      announcementId: annId,
      sentBy: senderId,
      sentByName: ann.createdByName || ann.authorName || '',
      targetType: ann.targetType || 'all',
      responseCount: 0,
    });

    if (tokens.length > 0) {
      await sendMulticast(tokens, {
        notification: { title, body },
        data: {
          type: 'announcement',
          announcementId: annId,
          requiresResponse: requiresResponse ? 'true' : 'false',
          responseOptions: responseOptions.join(','),
        },
      });
    }
    return null;
  });

// ─── TRIGGER 5: activity_logs login/logout → notify leaders ─────────────────
// Whenever a user (any role) logs in or out, fan out an FCM push to every
// active leader so they have a real-time audit feed. The actor also gets
// a self-confirmation push so they know FCM is working.
exports.onAuthActivityLog = functions.firestore
  .document('activity_logs/{logId}')
  .onCreate(async (snap, context) => {
    const log = snap.data();
    if (!log) return null;
    const action = (log.action || '').toString();
    if (action !== 'login' && action !== 'logout') return null;

    const actorId = log.actorId || log.targetId || '';
    const actorName = log.actorName || log.targetName || 'Someone';
    const actorRole = (log.actorRole || 'member').toString();
    const platform =
      (log.metadata && log.metadata.platform) || 'unknown';

    // Recipients: all active leaders, plus the actor (so they see proof
    // of delivery on their own device).
    const leaderIds = await getUserIdsByRole('leader');
    const recipientSet = new Set(leaderIds);
    if (actorId) recipientSet.add(actorId);
    const recipients = Array.from(recipientSet);
    if (recipients.length === 0) return null;

    const verb = action === 'login' ? 'logged in' : 'logged out';
    const roleLabel =
      actorRole.charAt(0).toUpperCase() + actorRole.slice(1);
    const title = `${roleLabel} ${verb}`;
    const body = `${actorName} ${verb} on ${platform}.`;

    await writePerUserNotifications(recipients, {
      title,
      body,
      type: 'auth_audit',
      notifType: 'auth_audit',
      requiresResponse: false,
      action,
      actorId,
      actorName,
      actorRole,
      platform,
    });

    const tokens = await getTokensForUsers(recipients);
    if (tokens.length > 0) {
      await sendMulticast(tokens, {
        notification: { title, body },
        data: {
          type: 'auth_audit',
          action,
          actorId,
          actorName,
          actorRole,
          platform,
          requiresResponse: 'false',
        },
        webpush: {
          notification: {
            icon: '/icons/Icon-192.png',
            badge: '/icons/Icon-192.png',
            requireInteraction: false,
            tag: `auth-${actorId}-${action}`,
            renotify: true,
          },
        },
      });
    }
    return null;
  });

// ─── TRIGGER 6: notification_response created → bump responseCount ──────────
exports.onResponseCreated = functions.firestore
  .document('notification_responses/{responseId}')
  .onCreate(async (snap) => {
    const data = snap.data();
    if (!data || !data.notificationId) return null;
    try {
      await db
        .collection('notifications')
        .doc(data.notificationId)
        .update({
          responseCount: admin.firestore.FieldValue.increment(1),
        });
    } catch (e) {
      // Notification doc may not exist if response is on a source doc only.
      console.warn('responseCount increment skipped:', e.message);
    }
    return null;
  });
