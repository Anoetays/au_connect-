require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const { Paynow } = require('paynow');
const { createClient } = require('@supabase/supabase-js');

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// Utility function to validate UUID v4 format
function isValidUuid(uuid) {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
};

// Supabase client
const supabaseUrl = process.env.SUPABASE_URL || 'https://lwnblbrohablulbeiruf.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseServiceKey || '', {
  auth: { persistSession: false }
});

// Multer for file uploads (in-memory)
const storage = multer.memoryStorage();
const upload = multer({ storage, limits: { fileSize: 10 * 1024 * 1024 } });

const PAYNOW_INTEGRATION_ID = process.env.PAYNOW_INTEGRATION_ID || '23962';
const PAYNOW_INTEGRATION_KEY = process.env.PAYNOW_INTEGRATION_KEY || '79947988-9f35-4e6f-8e3b-4f66f13be66c';
const PAYNOW_MERCHANT_EMAIL = process.env.PAYNOW_MERCHANT_EMAIL || 'anotidatays29@gmail.com';

const paynow = new Paynow(PAYNOW_INTEGRATION_ID, PAYNOW_INTEGRATION_KEY);

paynow.resultUrl = process.env.PAYNOW_RESULT_URL || 'https://example.com/paynow/result';
paynow.returnUrl = process.env.PAYNOW_RETURN_URL || 'https://example.com/paynow/return';

// POST /api/pay — initiate an EcoCash mobile payment
app.post('/api/pay', async (req, res) => {
  const { phone, amount, reference } = req.body;

  if (!phone || !amount || !reference) {
    return res.status(400).json({ success: false, error: 'Missing required fields: phone, amount, reference' });
  }

  if (typeof amount !== 'number' || amount <= 0) {
    return res.status(400).json({ success: false, error: 'amount must be a positive number' });
  }

  try {
    const payment = paynow.createPayment(reference, PAYNOW_MERCHANT_EMAIL);
    payment.add(reference, amount);

    const response = await paynow.sendMobile(payment, phone, 'ecocash');

    if (response.success) {
      return res.json({ success: true, pollUrl: response.pollUrl });
    } else {
      return res.status(502).json({ success: false, error: response.error || 'Payment initiation failed' });
    }
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message || 'Internal server error' });
  }
});

// GET /api/poll?url=<pollUrl> — check transaction status
app.get('/api/poll', async (req, res) => {
  const { url } = req.query;

  if (!url) {
    return res.status(400).json({ success: false, error: 'Missing required query param: url' });
  }

  try {
    const status = await paynow.pollTransaction(url);

    return res.json({
      success: true,
      paid: status.paid(),
      status: status.status,
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message || 'Failed to poll transaction' });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// MESSAGES API — Conversations and Messages
// ═══════════════════════════════════════════════════════════════════════════

// GET /api/conversations — get all conversations for a user
app.get('/api/conversations', async (req, res) => {
  const { participant_id } = req.query;

  if (!participant_id) {
    return res.status(400).json({ success: false, error: 'Missing participant_id query parameter' });
  }

  // Validate UUID format
  if (!isValidUuid(participant_id)) {
    return res.status(400).json({ success: false, error: 'Invalid participant_id format. Must be a valid UUID.' });
  }

  try {
    const { data, error } = await supabase
      .from('conversations')
      .select('*')
      .or(`participant1_id.eq.${participant_id},participant2_id.eq.${participant_id}`)
      .order('updated_at', { ascending: false });

    if (error) throw error;
    return res.json({ success: true, data });
  } catch (err) {
    console.error('[GET /api/conversations ERROR]', err);
    return res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/conversations — create a new conversation
app.post('/api/conversations', async (req, res) => {
  const { participant1_id, participant2_id } = req.body;

  if (!participant1_id || !participant2_id) {
    return res.status(400).json({ success: false, error: 'Missing required fields' });
  }

  try {
    const { data, error } = await supabase
      .from('conversations')
      .insert([{
        participant1_id,
        participant2_id,
        updated_at: new Date().toISOString(),
      }])
      .select()
      .single();

    if (error) throw error;
    return res.status(201).json({ success: true, data });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/messages/send — send a message
app.post('/api/messages/send', async (req, res) => {
  const { conversation_id, sender_id, recipient_id, content, type, file_url, file_name } = req.body;

  if (!conversation_id || !sender_id || !recipient_id || !content) {
    return res.status(400).json({ success: false, error: 'Missing required fields' });
  }

  try {
    const { data, error } = await supabase
      .from('messages')
      .insert([{
        conversation_id,
        sender_id,
        recipient_id,
        content,
        type: type || 'text',
        file_url,
        file_name,
        is_read: false,
        sent_at: new Date().toISOString(),
      }])
      .select()
      .single();

    if (error) throw error;

    // Update conversation's updated_at timestamp
    await supabase
      .from('conversations')
      .update({ updated_at: new Date().toISOString() })
      .eq('id', conversation_id);

    return res.status(201).json({ success: true, data });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// GET /api/messages/:messageId/read — mark message as read
app.get('/api/messages/:messageId/read', async (req, res) => {
  const { messageId } = req.params;

  if (!messageId) {
    return res.status(400).json({ success: false, error: 'Missing messageId' });
  }

  try {
    const { data, error } = await supabase
      .from('messages')
      .update({ is_read: true })
      .eq('id', messageId)
      .select()
      .single();

    if (error) throw error;
    return res.json({ success: true, data });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/conversations/:conversationId/mark-read — mark all conversation messages as read
app.post('/api/conversations/:conversationId/mark-read', async (req, res) => {
  const { conversationId } = req.params;

  if (!conversationId) {
    return res.status(400).json({ success: false, error: 'Missing conversationId' });
  }

  try {
    const { error } = await supabase
      .from('messages')
      .update({ is_read: true })
      .eq('conversation_id', conversationId);

    if (error) throw error;
    return res.json({ success: true, message: 'Conversation marked as read' });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// FILE UPLOAD API
// ═══════════════════════════════════════════════════════════════════════════

// POST /api/files/upload — upload a file to Supabase Storage
app.post('/api/files/upload', upload.single('file'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, error: 'No file provided' });
  }

  const { folder = 'documents' } = req.query;
  const fileName = `${Date.now()}-${req.file.originalname}`;
  const filePath = `${folder}/${fileName}`;

  try {
    const { data, error } = await supabase.storage
      .from('uploads')
      .upload(filePath, req.file.buffer, {
        contentType: req.file.mimetype,
      });

    if (error) throw error;

    // Get public URL
    const { data: publicData } = supabase.storage
      .from('uploads')
      .getPublicUrl(filePath);

    return res.status(201).json({
      success: true,
      file: {
        name: req.file.originalname,
        path: filePath,
        url: publicData?.publicUrl,
        size: req.file.size,
      },
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICATIONS API
// ═══════════════════════════════════════════════════════════════════════════

// GET /api/notifications — get notifications for a user
app.get('/api/notifications', async (req, res) => {
  const { user_id, role } = req.query;

  // Must provide either user_id or role query parameter
  if (!user_id && !role) {
    return res.status(400).json({ success: false, error: 'Missing user_id or role query parameter' });
  }

  try {
    let query = supabase.from('notifications').select('*');

    // Query by specific user ID (must be valid UUID)
    if (user_id && user_id !== 'all_admins') {
      if (!isValidUuid(user_id)) {
        return res.status(400).json({ success: false, error: 'Invalid user_id format. Must be a valid UUID.' });
      }
      query = query.eq('recipient_id', user_id);
    } 
    // Query by role (for admins, etc)
    else if (role === 'admin' || (user_id === 'all_admins')) {
      query = query.eq('recipient_role', 'admin');
    }

    const { data, error } = await query.order('created_at', { ascending: false });

    if (error) throw error;
    return res.json({ success: true, data });
  } catch (err) {
    console.error('[GET /api/notifications ERROR]', err);
    return res.status(500).json({ success: false, error: err.message || 'Unknown error' });
  }
});

// POST /api/notifications/send — send a notification
app.post('/api/notifications/send', async (req, res) => {
  const { recipient_id, recipient_role, type, title, body, metadata } = req.body;

  if (!recipient_role || !type || !title) {
    return res.status(400).json({
      success: false,
      error: 'Missing required fields: recipient_role, type, title',
    });
  }

  try {
    const { data, error } = await supabase
      .from('notifications')
      .insert([{
        recipient_id,
        recipient_role,
        type,
        title,
        body: body || '',
        metadata: metadata || {},
        is_read: false,
      }])
      .select()
      .single();

    if (error) throw error;
    return res.status(201).json({ success: true, data });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/notifications/:id/read — mark a notification as read
app.post('/api/notifications/:id/read', async (req, res) => {
  const { id } = req.params;

  try {
    const { data, error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return res.json({ success: true, data });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// DELETE /api/notifications/:id — delete a notification
app.delete('/api/notifications/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const { error } = await supabase
      .from('notifications')
      .delete()
      .eq('id', id);

    if (error) throw error;
    return res.json({ success: true, message: 'Notification deleted' });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// APPLICATIONS API
// ═══════════════════════════════════════════════════════════════════════════

// GET /api/applications/:userId — get user's applications
app.get('/api/applications/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    const { data, error } = await supabase
      .from('applications')
      .select('*')
      .eq('user_id', userId)
      .order('submitted_at', { ascending: false });

    if (error) throw error;
    return res.json({ success: true, data });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/applications/update-status — admin endpoint to update application status
app.post('/api/applications/update-status', async (req, res) => {
  const { application_id, status, notes } = req.body;
  const adminId = req.headers['x-admin-id'];

  if (!application_id || !status) {
    return res.status(400).json({ success: false, error: 'Missing required fields' });
  }

  if (!adminId) {
    return res.status(401).json({ success: false, error: 'Unauthorized: x-admin-id header required' });
  }

  try {
    const { data, error } = await supabase
      .from('applications')
      .update({
        status,
        notes,
        updated_at: new Date().toISOString(),
      })
      .eq('id', application_id)
      .select()
      .single();

    if (error) throw error;

    // Send notification to applicant about status change
    if (data?.user_id) {
      await supabase
        .from('notifications')
        .insert([{
          recipient_id: data.user_id,
          recipient_role: 'applicant',
          type: 'status_update',
          title: `Application Status Updated: ${status}`,
          body: notes || `Your application status has been updated to ${status}.`,
          metadata: {
            application_id,
            status,
          },
        }]);
    }

    return res.json({ success: true, data });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN DASHBOARD API
// ═══════════════════════════════════════════════════════════════════════════

// GET /api/admin/dashboard — admin dashboard statistics
app.get('/api/admin/dashboard', async (req, res) => {
  try {
    const { data: apps, error: appsError } = await supabase
      .from('applications')
      .select('id, status, submitted_at, programme, nationality');

    if (appsError) throw appsError;

    // Calculate statistics
    const totalApplications = apps.length;
    const statusCounts = {};
    const programmeCounts = {};
    const nationalityCounts = {};
    
    apps.forEach(app => {
      statusCounts[app.status] = (statusCounts[app.status] || 0) + 1;
      programmeCounts[app.programme] = (programmeCounts[app.programme] || 0) + 1;
      nationalityCounts[app.nationality] = (nationalityCounts[app.nationality] || 0) + 1;
    });

    const recentApps = apps.slice(0, 10);

    res.json({
      success: true,
      data: {
        totalApplications,
        statusBreakdown: statusCounts,
        byProgramme: programmeCounts,
        byNationality: nationalityCounts,
        recentApplications: recentApps,
      },
    });
  } catch (err) {
    console.error('[GET /api/admin/dashboard ERROR]', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// GET /api/admin/applications — get all applications (with filtering)
app.get('/api/admin/applications', async (req, res) => {
  const { status, programme, offset = 0, limit = 20 } = req.query;

  try {
    let query = supabase
      .from('applications')
      .select('id, user_id, status, programme, applicant_name, submitted_at, type, nationality, created_at', { count: 'exact' })
      .order('submitted_at', { ascending: false });

    if (status) {
      query = query.eq('status', status);
    }
    if (programme) {
      query = query.eq('programme', programme);
    }

    const { data, count, error } = await query.range(parseInt(offset), parseInt(offset) + parseInt(limit) - 1);

    if (error) throw error;

    res.json({
      success: true,
      data,
      pagination: {
        offset: parseInt(offset),
        limit: parseInt(limit),
        total: count,
      },
    });
  } catch (err) {
    console.error('[GET /api/admin/applications ERROR]', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// GET /api/admin/applications/:appId — get detailed application view
app.get('/api/admin/applications/:appId', async (req, res) => {
  const { appId } = req.params;

  try {
    const { data: app, error: appError } = await supabase
      .from('applications')
      .select('*')
      .eq('id', parseInt(appId))
      .single();

    if (appError) throw appError;

    const { data: docs, error: docsError } = await supabase
      .from('documents')
      .select('*')
      .eq('application_id', appId);

    if (docsError) throw docsError;

    res.json({
      success: true,
      data: {
        application: app,
        documents: docs,
      },
    });
  } catch (err) {
    console.error('[GET /api/admin/applications/:appId ERROR]', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/admin/applications/:appId/review — submit application review
app.post('/api/admin/applications/:appId/review', async (req, res) => {
  const { appId } = req.params;
  const { status, reviewNotes, reviewedBy } = req.body;

  if (!status) {
    return res.status(400).json({ success: false, error: 'status is required' });
  }

  try {
    const { data, error } = await supabase
      .from('applications')
      .update({
        status,
        updated_at: new Date().toISOString(),
      })
      .eq('id', parseInt(appId))
      .select()
      .single();

    if (error) throw error;

    // Create admin action log
    await supabase
      .from('admin_actions')
      .insert([{
        admin_id: reviewedBy || 'system',
        action: 'review_application',
        application_id: parseInt(appId),
        details: { status, notes: reviewNotes },
        created_at: new Date().toISOString(),
      }])
      .catch(err => console.warn('Failed to log admin action:', err));

    // Notify applicant of status change
    if (data.user_id) {
      await supabase.from('notifications').insert([{
        recipient_id: data.user_id,
        recipient_role: 'applicant',
        type: 'status_update',
        title: `Application Review Complete: ${status}`,
        body: reviewNotes || `Your application has been ${status.toLowerCase()}.`,
        metadata: { application_id: appId, status },
      }]);
    }

    res.json({ success: true, data });
  } catch (err) {
    console.error('[POST /api/admin/applications/:appId/review ERROR]', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/admin/documents/:docId/verify — verify document status
app.post('/api/admin/documents/:docId/verify', async (req, res) => {
  const { docId } = req.params;
  const { status, verificationNotes, verifiedBy } = req.body;

  try {
    const { data, error } = await supabase
      .from('documents')
      .update({
        verification_status: status,
        reviewed_by: verifiedBy || 'admin',
        uploaded_at: new Date().toISOString(),
      })
      .eq('id', docId)
      .select()
      .single();

    if (error) throw error;

    res.json({ success: true, data });
  } catch (err) {
    console.error('[POST /api/admin/documents/:docId/verify ERROR]', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST /api/admin/notifications/bulk — send bulk notifications to admins or applicants
app.post('/api/admin/notifications/bulk', async (req, res) => {
  const { recipient_role, type, title, body, filters } = req.body;

  if (!recipient_role || !type || !title) {
    return res.status(400).json({
      success: false,
      error: 'recipient_role, type, and title are required',
    });
  }

  try {
    let query = supabase.from('notifications');
    const notifications = [];

    if (recipient_role === 'applicant' && filters) {
      // Filter applicants by programme, status, etc
      let appQuery = supabase.from('applications').select('user_id');
      if (filters.programme) appQuery = appQuery.eq('programme', filters.programme);
      if (filters.status) appQuery = appQuery.eq('status', filters.status);

      const { data: appUsers, error: appError } = await appQuery;
      if (appError) throw appError;

      appUsers.forEach(app => {
        if (app.user_id) {
          notifications.push({
            recipient_id: app.user_id,
            recipient_role: 'applicant',
            type,
            title,
            body: body || '',
            metadata: { bulkSend: true },
            is_read: false,
          });
        }
      });
    } else {
      // Send to all admins
      notifications.push({
        recipient_role: 'admin',
        type,
        title,
        body: body || '',
        metadata: { bulkSend: true },
        is_read: false,
      });
    }

    if (notifications.length === 0) {
      return res.json({ success: true, sent: 0 });
    }

    const { data, error } = await supabase
      .from('notifications')
      .insert(notifications)
      .select();

    if (error) throw error;

    res.json({ success: true, sent: data.length });
  } catch (err) {
    console.error('[POST /api/admin/notifications/bulk ERROR]', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// GET /api/admin/reports/export — export applications report (JSON/CSV)
app.get('/api/admin/reports/export', async (req, res) => {
  const { format = 'json', status, programme } = req.query;

  try {
    let query = supabase
      .from('applications')
      .select('id, user_id, applicant_name, programme, status, nationality, submitted_at, type, created_at');

    if (status) query = query.eq('status', status);
    if (programme) query = query.eq('programme', programme);

    const { data, error } = await query.order('submitted_at', { ascending: false });

    if (error) throw error;

    if (format === 'csv') {
      // Convert to CSV
      const headers = Object.keys(data[0] || {});
      const csv = [headers.join(','), ...data.map(row => headers.map(h => `"${row[h] || ''}"`).join(','))].join('\n');
      
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename="applications_export.csv"');
      res.send(csv);
    } else {
      res.json({ success: true, data, count: data.length });
    }
  } catch (err) {
    console.error('[GET /api/admin/reports/export ERROR]', err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// HEALTH CHECK
// ═══════════════════════════════════════════════════════════════════════════

app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    status: 'Backend is running',
    timestamp: new Date().toISOString(),
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 AU Connect backend running on port ${PORT}`));
